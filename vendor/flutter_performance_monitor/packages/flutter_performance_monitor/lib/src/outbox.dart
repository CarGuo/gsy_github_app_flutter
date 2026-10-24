import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'model.dart';
import 'otlp.dart';
import 'outbox_codec.dart';
import 'outbox_ownership.dart';

/// Safety ceilings, not measured performance targets. Capacity counts encoded
/// disk envelopes, including the temporary file during atomic replacement.
class OutboxLimits {
  const OutboxLimits({
    this.maxQueueBytes = 8 * 1024 * 1024,
    this.maxQueueBatches = 128,
    this.maxBatchBytes = 256 * 1024,
    this.ttl = const Duration(hours: 24),
    this.maxExportBytesPerMinute = 1024 * 1024,
    this.maxRequestsPerMinute = 12,
    this.maxAttempts,
    this.requestTimeout = const Duration(seconds: 10),
    this.maxResponseBytes = 64 * 1024,
    this.initialBackoff = const Duration(seconds: 2),
    this.maxBackoff = const Duration(minutes: 5),
  });

  final int maxQueueBytes, maxQueueBatches, maxBatchBytes;
  final Duration ttl;
  final int maxExportBytesPerMinute, maxRequestsPerMinute;

  /// Null retains retryable failures until TTL or queue pressure, even offline.
  final int? maxAttempts;
  final Duration requestTimeout;
  final int maxResponseBytes;
  final Duration initialBackoff, maxBackoff;

  bool equivalentTo(OutboxLimits other) =>
      maxQueueBytes == other.maxQueueBytes &&
      maxQueueBatches == other.maxQueueBatches &&
      maxBatchBytes == other.maxBatchBytes &&
      ttl == other.ttl &&
      maxExportBytesPerMinute == other.maxExportBytesPerMinute &&
      maxRequestsPerMinute == other.maxRequestsPerMinute &&
      maxAttempts == other.maxAttempts &&
      requestTimeout == other.requestTimeout &&
      maxResponseBytes == other.maxResponseBytes &&
      initialBackoff == other.initialBackoff &&
      maxBackoff == other.maxBackoff;

  void validate() {
    if (maxQueueBytes <= 0 ||
        maxQueueBatches <= 0 ||
        maxBatchBytes <= 0 ||
        maxExportBytesPerMinute < maxBatchBytes ||
        maxRequestsPerMinute <= 0 ||
        (maxAttempts != null && maxAttempts! <= 0) ||
        maxResponseBytes <= 0 ||
        ttl <= Duration.zero ||
        requestTimeout <= Duration.zero ||
        initialBackoff <= Duration.zero ||
        maxBackoff < initialBackoff) {
      throw ArgumentError(
        'Outbox limits must be positive and the export byte budget must fit one maximum batch.',
      );
    }
  }
}

class _Batch {
  _Batch(
    this.id,
    this.createdMs,
    this.bytes,
    this.records, {
    this.attempts = 0,
    this.notBeforeMs = 0,
    this.diskBytes = 0,
  });
  final String id;
  final int createdMs, records;
  final Uint8List bytes;
  int attempts, notBeforeMs, diskBytes;
}

/// One UI-isolate owner per directory. Bounded, at-least-once best-effort
/// delivery; ACK is Collector acceptance, not final database commit.
///
/// Commits flush a temporary file then atomically rename it. This covers process
/// restart, not device power loss: Dart does not expose a directory fsync here.
/// Disk failures disable this outbox rather than retaining unbounded RAM.
class ReliableOutbox {
  ReliableOutbox._(
    this.directory,
    this.endpoint,
    this.limits,
    this._transport,
    this._clock,
    this._onDiagnostic,
    this._random,
  );

  /// [clock] supplies epoch timestamps. Monotonic elapsed time keeps live
  /// deadlines progressing even when wall time stalls or corrects backwards.
  /// Forward wall corrections can still advance age, as they do on recovery.
  static Future<ReliableOutbox> open(
    Directory directory,
    Uri endpoint, {
    OutboxLimits limits = const OutboxLimits(),
    OtlpTransport? transport,
    DateTime Function()? clock,
    bool allowInsecureLoopback = false,
    void Function(String reason, int count)? onDiagnostic,
    Random? random,
  }) async {
    limits.validate();
    final outbox = ReliableOutbox._(
      directory,
      validateOtlpEndpoint(
        endpoint,
        allowInsecureLoopback: allowInsecureLoopback,
      ),
      limits,
      transport ?? HttpOtlpTransport(),
      clock ?? DateTime.now,
      onDiagnostic,
      random ?? Random.secure(),
    );
    await outbox._recover();
    return outbox;
  }

  final Directory directory;
  final Uri endpoint;
  final OutboxLimits limits;
  final OtlpTransport _transport;
  final DateTime Function() _clock;
  final Stopwatch _elapsed = Stopwatch()..start();
  final void Function(String reason, int count)? _onDiagnostic;
  final Random _random;
  final List<_Batch> _queue = [];
  final Map<String, int> _diagnostics = {};
  Future<void> _writer = Future<void>.value();
  Future<void>? _flushing, _disposing;
  OutboxOwnership? _ownership;
  Timer? _timer;
  _Batch? _inFlight;
  bool _available = false, _foreground = true, _disposed = false;
  bool _automaticExportEnabled = true;
  int _lastNowMs = 0, _rateStartMs = 0, _attemptedBytes = 0, _requestStarts = 0;
  int _lastElapsedMs = 0, _lastWallMs = 0;
  bool _reporting = false, _rateReported = false;
  int _pendingEnqueueBytes = 0;

  Map<String, int> get diagnostics => Map.unmodifiable(_diagnostics);
  int get pendingBatches => _queue.length;
  int get pendingBytes => _queue.fold(0, (sum, batch) => sum + batch.diskBytes);
  bool get isAvailable => _available && !_disposed;
  Duration? get oldestAge => _queue.isEmpty
      ? null
      : Duration(milliseconds: max(0, _nowMs() - _queue.first.createdMs));

  int _nowMs() {
    final elapsedMs = _elapsed.elapsedMilliseconds;
    var now = _lastNowMs;
    var clockFailed = false;
    try {
      now = _clock().millisecondsSinceEpoch;
    } catch (_) {
      _diagnose('clock_error');
      clockFailed = true;
      if (now == 0) now = DateTime.now().millisecondsSinceEpoch;
    }
    _lastWallMs = now;
    // Apply the elapsed floor on every read: a backward correction between
    // reads can leave wall time net-forward but still behind elapsed time.
    // Consume each interval once so restoration cannot add it a second time.
    now = max(now, _lastNowMs + max(0, elapsedMs - _lastElapsedMs));
    _lastElapsedMs = elapsedMs;
    _lastNowMs = max(_lastNowMs, now);
    if (clockFailed) _lastWallMs = _lastNowMs;
    // This remains epoch-referenced for the version-1 spool and its existing
    // restart TTL/future-skew policy, never a process-relative timestamp.
    return _lastNowMs;
  }

  void _diagnose(String reason, [int count = 1]) {
    if (count <= 0) return;
    _diagnostics.update(reason, (n) => n + count, ifAbsent: () => count);
    if (_onDiagnostic == null || _reporting) return;
    _reporting = true;
    try {
      _onDiagnostic(reason, count);
    } catch (_) {
      _diagnostics.update('callback_error', (n) => n + 1, ifAbsent: () => 1);
    } finally {
      _reporting = false;
    }
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _writer.then((_) async {
      try {
        await action();
      } catch (_) {
        _diskFailed();
      }
    });
    _writer = next;
    return next;
  }

  void _diskFailed() {
    _available = false;
    _timer?.cancel();
    _timer = null;
    _diagnose('disk_error');
  }

  String _path(String name) =>
      '${directory.path}${Platform.pathSeparator}$name';
  File _file(_Batch batch) => File(_path('${batch.id}.ready'));

  Future<void> _recover() async {
    try {
      await directory.create(recursive: true);
      final canonical = await directory.resolveSymbolicLinks();
      _ownership = await OutboxOwnership.acquire(
        '$canonical${Platform.pathSeparator}.lock',
      );
      if (_ownership == null) {
        _diagnose('storage_locked');
        return;
      }
      _available = true;
      var scanned = 0;
      final maxEntries = limits.maxQueueBatches * 4 + 32;
      await for (final entity in directory.list(followLinks: false)) {
        if (++scanned > maxEntries) {
          _available = false;
          _diagnose('recovery_limit');
          break;
        }
        final name = entity.path.split(Platform.pathSeparator).last;
        if (entity is! File) continue;
        if (RegExp(r'^[a-f0-9]{32}\.tmp$').hasMatch(name)) {
          await entity.delete();
          _diagnose('uncommitted_batch');
        } else if (RegExp(r'^[a-f0-9]{32}\.ready$').hasMatch(name)) {
          await _recoverFile(entity, name.substring(0, 32));
        }
      }
      _queue.sort((a, b) {
        final time = a.createdMs.compareTo(b.createdMs);
        return time != 0 ? time : a.id.compareTo(b.id);
      });
      if (_available) {
        await _expire();
        while (_queue.length > limits.maxQueueBatches ||
            pendingBytes > limits.maxQueueBytes) {
          await _drop(_queue.first, 'queue_capacity');
        }
      }
    } catch (_) {
      _available = false;
      _diagnose('storage_unavailable');
      await _releaseOwner();
    }
  }

  Future<void> _recoverFile(File file, String id) async {
    String? reason;
    final size = await file.length();
    if (size > limits.maxBatchBytes * 2 + 2048) {
      reason = 'corrupt_batch';
    } else {
      // Read raw bytes asynchronously; UTF-8, JSON, base64 and checksums all
      // run off the owner isolate. Await one file before reading the next.
      final decoded = await decodeOutboxEnvelope(
        await file.readAsBytes(),
        id,
        endpoint.toString(),
        limits.maxBatchBytes,
      );
      reason = decoded.reason;
      final batch = decoded.envelope;
      if (batch != null) {
        _queue.add(
          _Batch(
            id,
            batch.createdMs,
            batch.bytes,
            batch.records,
            attempts: batch.attempts,
            notBeforeMs: batch.notBeforeMs,
            diskBytes: size,
          ),
        );
        _queue.sort((a, b) => a.createdMs.compareTo(b.createdMs));
        while (_queue.length > limits.maxQueueBatches ||
            pendingBytes > limits.maxQueueBytes) {
          await _drop(_queue.first, 'queue_capacity');
        }
      }
    }
    if (reason != null) {
      await file.delete();
      _diagnose(reason);
    }
  }

  Future<bool> _commit(_Batch batch, {required bool replacing}) async {
    final encoded = await encodeOutboxEnvelope((
      id: batch.id,
      createdMs: batch.createdMs,
      attempts: batch.attempts,
      notBeforeMs: batch.notBeforeMs,
      records: batch.records,
      destination: endpoint.toString(),
      bytes: batch.bytes,
    ));
    if (!replacing && encoded.length * 2 + 64 > limits.maxQueueBytes) {
      _diagnose('queue_capacity');
      return false;
    }
    // Reserve both old and temporary bytes, so an atomic retry-state update
    // cannot exceed the configured disk ceiling even transiently.
    while (pendingBytes + encoded.length > limits.maxQueueBytes ||
        (!replacing && _queue.length >= limits.maxQueueBatches)) {
      final candidates = _queue.where((b) => b != batch && b != _inFlight);
      if (candidates.isEmpty) {
        _diagnose('queue_capacity');
        return false;
      }
      await _drop(candidates.first, 'queue_capacity');
    }
    final temp = File(_path('${batch.id}.tmp'));
    await temp.writeAsBytes(encoded, flush: true);
    await temp.rename(_file(batch).path);
    batch.diskBytes = encoded.length;
    if (!replacing) _queue.add(batch);
    return true;
  }

  /// Persist promptly; enqueue never starts network I/O. Oversized events drop
  /// visibly. Serialization/transport/disk failures never escape into the app.
  Future<void> enqueue(List<TelemetryEvent> events) {
    // Snapshot the list synchronously and bound work waiting for the disk writer.
    final accepted = <OutboxEventData>[];
    var reserved = 0;
    for (final event in events) {
      final upperBytes = event.encoded.length * 4;
      if (_pendingEnqueueBytes + reserved + upperBytes > limits.maxQueueBytes) {
        _diagnose('queue_capacity');
      } else {
        accepted.add((
          appId: event.appId,
          eventId: event.eventId,
          encoded: event.encoded,
          windowEndMs: event.body['window_end_unix_ms'] as int,
        ));
        reserved += upperBytes;
      }
    }
    // Rejected offers have already been diagnosed. Reuse the writer tail so
    // callers still await earlier accepted writes without adding an empty job.
    if (events.isNotEmpty && accepted.isEmpty) return _writer;
    _pendingEnqueueBytes += reserved;
    return _writer = _enqueue(
      accepted,
    ).whenComplete(() => _pendingEnqueueBytes -= reserved);
  }

  Future<void> _enqueue(List<OutboxEventData> events) => _serial(() async {
    if (_disposed) {
      _diagnose('enqueue_after_dispose', events.length);
      return;
    }
    if (!_available) {
      _diagnose('storage_unavailable', events.length);
      return;
    }
    await _expire();
    if (events.isEmpty) return;
    final packed = await packOutboxEvents(events, limits.maxBatchBytes);
    _diagnose('event_too_large', packed.oversized);
    for (final payload in packed.batches) {
      String id;
      do {
        id = List.generate(
          16,
          (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
      } while (_queue.any((batch) => batch.id == id));
      await _commit(
        _Batch(id, _nowMs(), payload.bytes, payload.records),
        replacing: false,
      );
    }
  });

  Future<void> _drop(_Batch batch, String reason) async {
    await _file(batch).delete();
    _queue.remove(batch);
    if (reason.isNotEmpty) _diagnose(reason);
  }

  Future<void> _expire() async {
    final now = _nowMs();
    for (final batch in List<_Batch>.of(_queue)) {
      if (batch == _inFlight) continue;
      if (batch.createdMs > now + const Duration(minutes: 5).inMilliseconds) {
        await _drop(batch, 'clock_skew');
      } else if (now - batch.createdMs >= limits.ttl.inMilliseconds) {
        await _drop(batch, 'expired_batch');
      } else if (limits.maxAttempts != null &&
          batch.attempts >= limits.maxAttempts!) {
        await _drop(batch, 'attempts_expired');
      }
    }
  }

  /// Coalesced, serialized export. Attempts use exactly the stored request bytes.
  Future<void> flush() {
    if (_disposed || !_foreground || !_available) return Future.value();
    if (_flushing != null) return _flushing!;
    final completer = Completer<void>();
    _flushing = completer.future;
    unawaited(() async {
      try {
        await _flushLoop();
      } catch (_) {
        _diagnose('transport_error');
      } finally {
        _flushing = null;
        completer.complete();
      }
    }());
    return completer.future;
  }

  Future<void> _flushLoop() async {
    _timer?.cancel();
    _timer = null;
    while (!_disposed && _foreground && _available) {
      _Batch? batch;
      await _serial(() async {
        await _expire();
        if (_queue.isEmpty || _disposed || !_foreground || !_available) return;
        final now = _nowMs();
        final first = _queue.first;
        if (first.notBeforeMs > now) {
          _schedule(first.notBeforeMs);
          return;
        }
        if (now - _rateStartMs >= 60000) {
          _rateStartMs = now;
          _attemptedBytes = 0;
          _requestStarts = 0;
          _rateReported = false;
        }
        if (_requestStarts >= limits.maxRequestsPerMinute ||
            _attemptedBytes + first.bytes.length >
                limits.maxExportBytesPerMinute) {
          if (!_rateReported) {
            _diagnose('rate_limited');
            _rateReported = true;
          }
          _schedule(_rateStartMs + 60000);
          return;
        }
        // Persist before send, conservatively counting a crash before send as an
        // attempt. A crash after send then replays immutable bytes, never new IDs.
        _inFlight = first;
        first.attempts++;
        first.notBeforeMs = now + _backoff(first.attempts).inMilliseconds;
        if (!await _commit(first, replacing: true)) {
          await _drop(first, '');
          _inFlight = null;
          return;
        }
        _attemptedBytes += first.bytes.length;
        _requestStarts++;
        batch = first;
      });
      final current = batch;
      if (current == null) break;
      // Codec and disk awaits above can overlap a lifecycle pause. Keep the
      // already-persisted conservative attempt, but do not start a new request.
      if (_disposed || !_foreground || !_available) {
        await _serial(() async {
          if (_inFlight == current) _inFlight = null;
        });
        continue;
      }
      OtlpResponse? response;
      String? failure;
      try {
        response = await _transport.send(
          endpoint,
          current.bytes,
          timeout: limits.requestTimeout,
          maxResponseBytes: limits.maxResponseBytes,
        );
      } on OtlpResponseTooLarge catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          // Authentication applies to the request even when an ingress sends
          // an oversized HTML error page. No response body is retained.
          response = OtlpResponse(error.statusCode!);
        } else {
          failure = 'response_too_large';
        }
      } catch (_) {
        failure = 'transport_error';
      }
      await _serial(() async {
        _inFlight = null;
        if (!_queue.contains(current) || !_available) return;
        if (failure == 'response_too_large') {
          // Known response-limit failure is terminal, not an ambiguous send or
          // an ACK. Keep only the bounded loss diagnostic, never response text.
          await _drop(current, 'response_too_large');
          return;
        }
        if (failure != null) {
          _diagnose(failure);
          await _retainForRetry(current);
          return;
        }
        final result = classifyOtlpResponse(response!);
        switch (result.disposition) {
          case OtlpDisposition.accepted:
            await _drop(current, '');
          case OtlpDisposition.partial:
            if (result.rejectedRecords > current.records) {
              await _drop(current, 'invalid_response');
              break;
            }
            _diagnose('partial_success');
            _diagnose('partial_rejected_records', result.rejectedRecords);
            await _drop(current, '');
          case OtlpDisposition.rejected:
            await _drop(current, 'permanent_rejection');
          case OtlpDisposition.authRequired:
            // 2026-10-23: credential expiry/rotation is not an event rejection.
            // Keep the exact bytes under ordinary backoff, TTL and capacity.
            _diagnose('auth_required');
            await _retainForRetry(current, retryAfter: response.retryAfter);
          case OtlpDisposition.invalidResponse:
            await _drop(current, 'invalid_response');
          case OtlpDisposition.retry:
            _diagnose('retryable_response');
            await _retainForRetry(current, retryAfter: response.retryAfter);
        }
      });
      if ((failure != null && failure != 'response_too_large') ||
          (response != null &&
              {
                OtlpDisposition.retry,
                OtlpDisposition.authRequired,
              }.contains(classifyOtlpResponse(response).disposition))) {
        break;
      }
    }
  }

  Future<void> _retainForRetry(_Batch batch, {String? retryAfter}) async {
    final now = _nowMs();
    final retry = parseRetryAfter(
      retryAfter,
      // HTTP-date Retry-After is relative to the actual wall clock, not the
      // elapsed floor retained after a correction. Store the resulting delay
      // on our epoch-referenced live timeline like an ordinary seconds value.
      DateTime.fromMillisecondsSinceEpoch(_lastWallMs, isUtc: true),
    );
    batch.notBeforeMs =
        now +
        max(
          _backoff(batch.attempts).inMilliseconds,
          retry?.inMilliseconds ?? 0,
        );
    if (!await _commit(batch, replacing: true)) {
      await _drop(batch, '');
      return;
    }
    _schedule(batch.notBeforeMs);
  }

  Duration _backoff(int attempts) {
    final exponent = min(attempts - 1, 20);
    final cap = min(
      limits.maxBackoff.inMilliseconds,
      limits.initialBackoff.inMilliseconds * (1 << exponent),
    );
    // Bounded equal jitter: never zero, never a busy retry loop.
    return Duration(
      milliseconds: max(1, (cap * (0.5 + _random.nextDouble() * 0.5)).round()),
    );
  }

  void _schedule(int dueMs) {
    if (_disposed ||
        !_foreground ||
        !_automaticExportEnabled ||
        !_available ||
        _queue.isEmpty) {
      return;
    }
    _timer?.cancel();
    final expiresMs = _queue.first.createdMs + limits.ttl.inMilliseconds;
    final delay = max(1, min(dueMs, expiresMs) - _nowMs());
    _timer = Timer(Duration(milliseconds: delay), () {
      _timer = null;
      unawaited(flush());
    });
  }

  /// Background suspends retry timers; already-sent bytes cannot be recalled.
  void setForeground(bool foreground) {
    if (_disposed) return;
    _foreground = foreground;
    if (!foreground) {
      _timer?.cancel();
      _timer = null;
    } else if (_automaticExportEnabled) {
      unawaited(flush());
    }
  }

  /// Suppress automatic exports during application startup. Explicit [flush]
  /// remains available to the caller; foreground/background is independent.
  void setAutomaticExportEnabled(bool enabled) {
    if (_disposed || _automaticExportEnabled == enabled) return;
    _automaticExportEnabled = enabled;
    if (!enabled) {
      _timer?.cancel();
      _timer = null;
    } else if (_foreground) {
      unawaited(flush());
    }
  }

  Future<void> _releaseOwner() async {
    final ownership = _ownership;
    _ownership = null;
    if (ownership != null) {
      try {
        await ownership.release();
      } catch (_) {
        _diagnose('disk_error');
      }
    }
  }

  /// Stops uploads and releases ownership, preserving pending files for restart.
  Future<void> dispose() {
    if (_disposing != null) return _disposing!;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    try {
      _transport.close();
    } catch (_) {
      _diagnose('transport_error');
    }
    return _disposing = () async {
      await _flushing;
      await _writer;
      await _releaseOwner();
    }();
  }
}
