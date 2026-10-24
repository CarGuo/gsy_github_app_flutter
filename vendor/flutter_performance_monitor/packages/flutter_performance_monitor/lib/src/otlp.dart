import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'model.dart';

/// Encodes one already-validated event exactly once, including JSON escaping.
Uint8List encodeOtlpLogRecord(TelemetryEvent event) =>
    encodeOtlpLogRecordFields(
      encodedEvent: event.encoded,
      eventId: event.eventId,
      windowEndMs: event.body['window_end_unix_ms'] as int,
    );

/// Internal wire codec for primitive snapshots of already-validated events.
/// Keeping the body graph out of the message makes isolate transfer bounded by
/// the frozen event text rather than copying the original nested collections.
Uint8List encodeOtlpLogRecordFields({
  required String encodedEvent,
  required String eventId,
  required int windowEndMs,
}) => Uint8List.fromList(
  utf8.encode(
    jsonEncode({
      'timeUnixNano': '${BigInt.from(windowEndMs) * BigInt.from(1000000)}',
      'severityNumber': 9,
      'body': {'stringValue': encodedEvent},
      'attributes': [
        {
          'key': 'event.id',
          'value': {'stringValue': eventId},
        },
        {
          'key': 'schema.version',
          'value': {'intValue': '1'},
        },
      ],
    }),
  ),
);

final Uint8List _rootPrefix = Uint8List.fromList(
  utf8.encode('{"resourceLogs":['),
);
final Uint8List _rootSuffix = Uint8List.fromList(utf8.encode(']}'));
final Uint8List _resourceSuffix = Uint8List.fromList(utf8.encode(']}]}'));
final Uint8List _comma = Uint8List.fromList([44]);

class _EncodedResource {
  _EncodedResource(String appId)
    : prefix = Uint8List.fromList(
        utf8.encode(
          '{"resource":${jsonEncode({
            'attributes': [
              {
                'key': 'service.name',
                'value': {'stringValue': appId},
              },
            ],
          })},"scopeLogs":[{"scope":{"name":"dev.carguo.flutter_performance_monitor"},"logRecords":[',
        ),
      );
  final Uint8List prefix;
  final List<Uint8List> records = [];
}

/// Low-level OTLP envelope packer. Callers provide complete JSON record bytes;
/// this class does not validate application schemas. The outbox only supplies
/// bytes from [encodeOtlpLogRecord], which accepts validated TelemetryEvent data.
/// Accounting uses UTF-8 bytes, including every comma and resource envelope.
class OtlpBatchBuilder {
  final Map<String, _EncodedResource> _groups = {};
  int _byteLength = _rootPrefix.length + _rootSuffix.length;
  int _recordCount = 0;
  int get byteLength => _byteLength;
  int get recordCount => _recordCount;
  bool get isEmpty => _recordCount == 0;

  bool tryAdd(String appId, Uint8List record, {required int maxBytes}) {
    final existing = _groups[appId];
    final group = existing ?? _EncodedResource(appId);
    final extra =
        record.length +
        (existing == null
            ? group.prefix.length +
                  _resourceSuffix.length +
                  (_groups.isEmpty ? 0 : 1)
            : 1);
    if (_byteLength + extra > maxBytes) return false;
    if (existing == null) _groups[appId] = group;
    group.records.add(record);
    _byteLength += extra;
    _recordCount++;
    return true;
  }

  /// Copies each prepared byte segment once; no prior record is re-encoded.
  Uint8List takeBytes() {
    final result = BytesBuilder(copy: false)..add(_rootPrefix);
    var firstGroup = true;
    for (final group in _groups.values) {
      if (!firstGroup) result.add(_comma);
      firstGroup = false;
      result.add(group.prefix);
      var firstRecord = true;
      for (final record in group.records) {
        if (!firstRecord) result.add(_comma);
        firstRecord = false;
        result.add(record);
      }
      result.add(_resourceSuffix);
    }
    result.add(_rootSuffix);
    assert(result.length == _byteLength);
    final bytes = result.takeBytes();
    _groups.clear();
    _recordCount = 0;
    _byteLength = _rootPrefix.length + _rootSuffix.length;
    return bytes;
  }
}

/// Standard OTLP/HTTP JSON logs. Each event is encoded once, in linear work.
Uint8List encodeOtlpLogs(List<TelemetryEvent> events) {
  final builder = OtlpBatchBuilder();
  for (final event in events) {
    builder.tryAdd(
      event.appId,
      encodeOtlpLogRecord(event),
      maxBytes: 0x7fffffffffffffff,
    );
  }
  return builder.takeBytes();
}

/// No credentials, query strings, redirects or implicit cleartext production use.
Uri validateOtlpEndpoint(Uri endpoint, {bool allowInsecureLoopback = false}) {
  const devHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};
  final secure = endpoint.scheme == 'https';
  final local =
      allowInsecureLoopback &&
      endpoint.scheme == 'http' &&
      devHosts.contains(endpoint.host);
  if ((!secure && !local) ||
      endpoint.host.isEmpty ||
      endpoint.userInfo.isNotEmpty ||
      endpoint.hasQuery ||
      endpoint.hasFragment ||
      !{'', '/', '/v1/logs'}.contains(endpoint.path)) {
    throw ArgumentError(
      'Use an HTTPS OTLP /v1/logs endpoint; cleartext requires explicit development loopback opt-in.',
    );
  }
  return endpoint.replace(path: '/v1/logs');
}

class OtlpResponse {
  OtlpResponse(this.statusCode, {List<int> body = const [], this.retryAfter})
    : body = Uint8List.fromList(body).asUnmodifiableView();

  final int statusCode;
  final Uint8List body;
  final String? retryAfter;
}

/// An injected transport must honor the deadline and decoded response byte
/// limit, throwing [OtlpResponseTooLarge] when that limit is exceeded.
/// Implementations must never instrument their own export requests.
/// Preserve HTTPS certificate validation and reject redirects rather than
/// forwarding credentials to another destination. Keep authentication material
/// out of telemetry, logs, exceptions exposed to the app, and durable payloads.
abstract interface class OtlpTransport {
  Future<OtlpResponse> send(
    Uri endpoint,
    Uint8List bytes, {
    required Duration timeout,
    required int maxResponseBytes,
  });
  void close();
}

/// Terminal response-limit failure, regardless of HTTP status. It is not an
/// acceptance acknowledgement and intentionally retains no server body text.
class OtlpResponseTooLarge implements Exception {
  const OtlpResponseTooLarge({this.statusCode});
  final int? statusCode;
}

/// Independent dart:io client; it does not use a monitored application client.
class HttpOtlpTransport implements OtlpTransport {
  HttpOtlpTransport({
    HttpClient? client,
    FutureOr<String?> Function()? authorization,
  }) : _client = client ?? HttpClient(),
       _authorization = authorization;
  final HttpClient _client;
  // 2026-10-23: obtain a rotating ingest credential only at send time. Never
  // serialize it with durable events or forward it through redirects.
  final FutureOr<String?> Function()? _authorization;
  bool _closed = false;

  @override
  Future<OtlpResponse> send(
    Uri endpoint,
    Uint8List bytes, {
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    if (_closed) throw StateError('Transport closed');
    HttpClientRequest? request;
    StreamSubscription<List<int>>? subscription;
    var cancelled = false;
    final completed = Completer<OtlpResponse>();
    void fail(Object error, [StackTrace? stack]) {
      if (!completed.isCompleted) completed.completeError(error, stack);
    }

    Future<void> cancelResponse() async {
      try {
        await subscription?.cancel();
      } catch (_) {
        // Cancellation follows an already-reported terminal transport outcome.
      }
    }

    void abort() {
      cancelled = true;
      try {
        request?.abort();
      } catch (_) {
        /* Best-effort cleanup only. */
      }
      unawaited(cancelResponse());
    }

    final timer = Timer(timeout, () {
      fail(TimeoutException('OTLP deadline'));
      abort();
    });
    // The async setup AND every later stream callback contain their own errors.
    unawaited(() async {
      try {
        final authorization = await _authorization?.call();
        if (authorization != null &&
            (authorization.isEmpty ||
                authorization.length > 8192 ||
                authorization.contains('\r') ||
                authorization.contains('\n'))) {
          throw const FormatException('Invalid OTLP authorization value');
        }
        if (cancelled) return;
        _client.connectionTimeout = timeout;
        final opened = await _client.postUrl(endpoint);
        request = opened;
        if (cancelled) {
          abort();
          return;
        }
        opened.followRedirects = false;
        if (authorization != null) {
          if (endpoint.scheme != 'https') {
            throw const FormatException('OTLP credentials require HTTPS');
          }
          opened.headers.set(HttpHeaders.authorizationHeader, authorization);
        }
        opened.headers.contentType = ContentType.json;
        opened.contentLength = bytes.length;
        opened.add(bytes);
        final response = await opened.close();
        if (cancelled) {
          subscription = response.listen((_) {}, onError: (Object _) {});
          await cancelResponse();
          return;
        }
        final builder = BytesBuilder(copy: false);
        subscription = response.listen(
          (chunk) {
            if (completed.isCompleted) return;
            try {
              if (builder.length + chunk.length > maxResponseBytes) {
                fail(OtlpResponseTooLarge(statusCode: response.statusCode));
                abort();
              } else {
                builder.add(chunk);
              }
            } catch (error, stack) {
              fail(error, stack);
              abort();
            }
          },
          onError: (Object error, StackTrace stack) {
            fail(error, stack);
            abort();
          },
          onDone: () {
            if (completed.isCompleted) return;
            try {
              // value() throws for repeated fields. Ambiguous duplicates are
              // ignored, while their HTTP status still controls retryability.
              final retryValues =
                  response.headers[HttpHeaders.retryAfterHeader];
              final retryAfter = retryValues?.length == 1
                  ? retryValues!.single
                  : null;
              completed.complete(
                OtlpResponse(
                  response.statusCode,
                  body: builder.takeBytes(),
                  retryAfter: retryAfter,
                ),
              );
            } catch (error, stack) {
              fail(error, stack);
              abort();
            }
          },
        );
      } catch (error, stack) {
        fail(error, stack);
        abort();
      }
    }());
    try {
      return await completed.future;
    } finally {
      timer.cancel();
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _client.close(force: true);
  }
}

enum OtlpDisposition {
  accepted,
  partial,
  retry,
  authRequired,
  rejected,
  invalidResponse,
}

class OtlpResult {
  const OtlpResult(this.disposition, {this.rejectedRecords = 0});
  final OtlpDisposition disposition;
  final int rejectedRecords;
}

/// Partial success is terminal, including a warning with zero rejections.
OtlpResult classifyOtlpResponse(OtlpResponse response) {
  if (response.statusCode == 401 || response.statusCode == 403) {
    return const OtlpResult(OtlpDisposition.authRequired);
  }
  if ({429, 502, 503, 504}.contains(response.statusCode)) {
    return const OtlpResult(OtlpDisposition.retry);
  }
  if (response.statusCode != 200) {
    return const OtlpResult(OtlpDisposition.rejected);
  }
  if (response.body.isEmpty) {
    return const OtlpResult(OtlpDisposition.accepted);
  }
  try {
    final decoded = jsonDecode(utf8.decode(response.body));
    if (decoded is! Map<String, dynamic>) {
      return const OtlpResult(OtlpDisposition.invalidResponse);
    }
    final partial = decoded['partialSuccess'] ?? decoded['partial_success'];
    if (partial == null) return const OtlpResult(OtlpDisposition.accepted);
    if (partial is! Map<String, dynamic>) {
      return const OtlpResult(OtlpDisposition.invalidResponse);
    }
    final raw =
        partial['rejectedLogRecords'] ?? partial['rejected_log_records'] ?? 0;
    final rejected = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw)
        : null;
    final message = partial['errorMessage'] ?? partial['error_message'] ?? '';
    if (rejected == null || rejected < 0 || message is! String) {
      return const OtlpResult(OtlpDisposition.invalidResponse);
    }
    if (rejected != 0 || message.isNotEmpty) {
      return OtlpResult(OtlpDisposition.partial, rejectedRecords: rejected);
    }
    return const OtlpResult(OtlpDisposition.accepted);
  } catch (_) {
    return const OtlpResult(OtlpDisposition.invalidResponse);
  }
}

Duration? parseRetryAfter(String? value, DateTime now) {
  if (value == null) return null;
  final seconds = BigInt.tryParse(value.trim());
  if (seconds != null && !seconds.isNegative) {
    // Avoid Duration integer overflow for an extreme server value; this is
    // beyond any supported retention horizon, so TTL still wins.
    final maxSeconds = BigInt.from(9223372036854);
    return Duration(
      seconds: (seconds > maxSeconds ? maxSeconds : seconds).toInt(),
    );
  }
  try {
    final delta = HttpDate.parse(value).difference(now);
    return delta.isNegative ? Duration.zero : delta;
  } catch (_) {
    return null;
  }
}
