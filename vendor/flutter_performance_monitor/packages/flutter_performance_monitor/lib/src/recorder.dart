import 'dart:async';
import 'dart:isolate';

import 'histogram.dart';
import 'model.dart';
import 'recorder_materialization.dart';

/// Engineering safety ceilings, not measured performance SLOs.
final class RecorderLimits {
  const RecorderLimits({
    this.maxSeries = 64,
    this.maxScenes = 256,
    this.maxOperations = 64,
  });
  final int maxSeries;
  final int maxScenes;
  final int maxOperations;

  void validate() {
    if (maxSeries < 1 ||
        maxSeries > 4096 ||
        maxScenes < 1 ||
        maxScenes > 4096 ||
        maxOperations < 1 ||
        maxOperations > 4096) {
      throw ArgumentError('Recorder limits must be between 1 and 4096');
    }
  }
}

/// Fixed failure categories; raw exception messages never enter telemetry.
enum RecorderDrainFailureKind { worker, validation }

/// A detached window remains owned by the recorder until materialization works.
final class RecorderDrainException implements Exception {
  const RecorderDrainException(this.kind);
  final RecorderDrainFailureKind kind;
}

/// An embedding may supply a worker scheduler; it must execute [compute] away
/// from Flutter's UI isolate. The default uses [Isolate.run].
typedef RecorderWorker =
    Future<List<TelemetryEvent>> Function(
      List<TelemetryEvent> Function() compute,
    );

/// Single-isolate aggregation with finite registries and immutable drain output.
final class MetricRecorder {
  MetricRecorder(
    this.identity,
    this.sessionId, {
    this.limits = const RecorderLimits(),
    DateTime Function()? clock,
    RecorderWorker? worker,
  }) : _clock = clock ?? DateTime.now,
       _worker = worker ?? _runRecorderWorker {
    limits.validate();
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.+-]{0,63}$').hasMatch(sessionId)) {
      throw ArgumentError('Session ID must be a bounded safe identifier');
    }
    _windowStartMs = _readClock(0);
  }

  final MonitorIdentity identity;
  final String sessionId;
  final RecorderLimits limits;
  final DateTime Function() _clock;
  final RecorderWorker _worker;
  final Set<String> _scenes = {'unknown'};
  final Set<String> _operations = {'none'};
  Map<_SeriesKey, Histogram> _series = {};
  Map<String, int> _diagnostics = {};
  final Map<String, int> _lifetimeDiagnostics = {};
  late int _windowStartMs;
  int _sequence = 0;
  final List<_RecorderWindow> _pending = [];
  Future<void> _workerTail = Future<void>.value();
  bool _workerBusy = false;
  bool _drainFailed = false;

  Set<String> get registeredScenes => Set<String>.unmodifiable(_scenes);
  Set<String> get registeredOperations => Set<String>.unmodifiable(_operations);
  int get activeSeriesCount => _series.length;

  /// Bounded lifetime counters. Drain only resets the separately emitted deltas.
  Map<String, int> get diagnostics =>
      Map<String, int>.unmodifiable(_lifetimeDiagnostics);

  void registerScenes(Iterable<String> labels) => _register(
    labels,
    _scenes,
    limits.maxScenes,
    DiagnosticReasons.sceneRegistryFull,
  );
  void registerOperations(Iterable<String> labels) => _register(
    labels,
    _operations,
    limits.maxOperations,
    DiagnosticReasons.operationRegistryFull,
  );

  void _register(
    Iterable<String> labels,
    Set<String> registry,
    int limit,
    String reason,
  ) {
    for (final label in labels) {
      if (!isValidStableLabel(label)) {
        diagnostic(DiagnosticReasons.invalidLabel);
      } else if (!registry.contains(label)) {
        if (registry.length >= limit) {
          diagnostic(reason);
        } else {
          registry.add(label);
        }
      }
    }
  }

  String resolveScene(String value) {
    if (_scenes.contains(value)) return value;
    diagnostic(DiagnosticReasons.unregisteredScene);
    return 'unknown';
  }

  String resolveOperation(String value) {
    if (_operations.contains(value)) return value;
    diagnostic(DiagnosticReasons.unregisteredOperation);
    return 'none';
  }

  void record(
    String metric,
    num value, {
    String scene = 'unknown',
    String operation = 'none',
    num? nominalHz,
    num? budgetUs,
  }) {
    final bounds = Metrics.boundsFor(metric);
    if (bounds == null) {
      diagnostic(DiagnosticReasons.invalidMetric);
      return;
    }
    if (!value.isFinite || value < 0 || value > maxTelemetryInteger) {
      diagnostic(DiagnosticReasons.invalidSample);
      return;
    }
    if (nominalHz != null &&
        (!Metrics.isFrame(metric) ||
            !nominalHz.isFinite ||
            nominalHz <= 0 ||
            nominalHz > 1000)) {
      diagnostic(DiagnosticReasons.invalidNominalHz);
      nominalHz = null;
    }
    if (budgetUs != null &&
        (!Metrics.isFrame(metric) ||
            !budgetUs.isFinite ||
            budgetUs <= 0 ||
            budgetUs > maxTelemetryInteger)) {
      diagnostic(DiagnosticReasons.invalidBudget);
      budgetUs = null;
    }
    final key = _SeriesKey(
      metric,
      resolveScene(scene),
      resolveOperation(operation),
      nominalHz,
      budgetUs,
    );
    var histogram = _series[key];
    if (histogram == null) {
      if (_series.length >= limits.maxSeries) {
        diagnostic(DiagnosticReasons.seriesLimit);
        return;
      }
      histogram = Histogram(bounds, budgetUs: budgetUs);
      _series[key] = histogram;
    }
    if (!histogram.add(value)) {
      diagnostic(DiagnosticReasons.accumulatorOverflow);
    }
  }

  void diagnostic(String reason, {int count = 1}) {
    if (count <= 0 || count > maxTelemetryInteger) {
      reason = DiagnosticReasons.invalidDiagnosticCount;
      count = 1;
    } else if (!DiagnosticReasons.all.contains(reason)) {
      reason = DiagnosticReasons.invalidDiagnostic;
    }
    for (final counters in [_diagnostics, _lifetimeDiagnostics]) {
      final current = counters[reason] ?? 0;
      counters[reason] = count > maxTelemetryInteger - current
          ? maxTelemetryInteger
          : current + count;
    }
  }

  /// Synchronous materialization for standalone recorder consumers.
  /// Flutter collection uses [drainAsync] so validation/JSON stay off the UI.
  List<TelemetryEvent> drain() {
    if (_workerBusy) {
      throw StateError('Await asynchronous drains before a synchronous drain');
    }
    _detachWindow();
    final events = <TelemetryEvent>[];
    try {
      for (final window in _pending) {
        events.addAll(window.materialize());
      }
    } catch (_) {
      _drainFailed = true;
      rethrow;
    }
    _recordValidationFailures(events, _pending);
    _pending.clear();
    _drainFailed = false;
    return List.unmodifiable(events);
  }

  /// Detaches this window before yielding; later samples belong to a new window.
  Future<List<TelemetryEvent>> drainAsync() {
    // 2026-10-23: detaching is a transaction, not an implicit acknowledgement.
    // Retain the original window/IDs on validation or worker startup failure.
    // Subsequent calls retry it before newer windows, without UI serialization.
    final boundary = _detachWindow();
    final completion = Completer<List<TelemetryEvent>>();
    _workerBusy = true;
    late final Future<void> turn;
    turn = _workerTail.then((_) async {
      final events = <TelemetryEvent>[];
      final windows = _pending
          .where((window) => window.sequenceEnd <= boundary)
          .toList(growable: false);
      try {
        for (final window in windows) {
          final result = await _worker(window.materialize);
          events.addAll(result);
        }
        _recordValidationFailures(events, windows);
        _pending.removeRange(0, windows.length);
        _drainFailed = false;
        completion.complete(List.unmodifiable(events));
      } on RecorderDrainException catch (error, stack) {
        _drainFailed = true;
        completion.completeError(error, stack);
      } catch (_, stack) {
        _drainFailed = true;
        completion.completeError(
          const RecorderDrainException(RecorderDrainFailureKind.worker),
          stack,
        );
      } finally {
        if (identical(_workerTail, turn)) _workerBusy = false;
      }
    });
    _workerTail = turn;
    return completion.future;
  }

  void _recordValidationFailures(
    List<TelemetryEvent> events,
    Iterable<_RecorderWindow> windows,
  ) {
    // Validation diagnostics already occupy their reserved event positions;
    // update only the local lifetime counter, without exporting them twice.
    var failures = 0;
    for (final event in events) {
      if (event.body['reason'] == 'window_validation_failed') {
        failures += event.body['count']! as int;
      }
    }
    for (final window in windows) {
      failures -= window.diagnostics['window_validation_failed'] ?? 0;
    }
    if (failures > 0) {
      final previous = _lifetimeDiagnostics['window_validation_failed'] ?? 0;
      _lifetimeDiagnostics['window_validation_failed'] =
          failures > maxTelemetryInteger - previous
          ? maxTelemetryInteger
          : previous + failures;
    }
  }

  int _detachWindow() {
    // A broken worker must not create an ever growing chain of failed windows.
    // Keep the current bounded accumulators active until the retained work runs.
    if (_drainFailed) return _sequence;
    final endMs = _readClock(_windowStartMs);
    // 2026-10-23: transfer window ownership instead of validating/encoding each
    // series on Flutter's UI isolate. Reserve IDs before async work so windows
    // remain ordered and immutable while collection continues.
    final window = _RecorderWindow(
      identity,
      sessionId,
      _windowStartMs,
      endMs,
      _sequence,
      _series,
      _diagnostics,
    );
    _sequence += _series.length + _diagnostics.length;
    if (!window.isEmpty) _pending.add(window);
    _series = {};
    _diagnostics = {};
    _windowStartMs = endMs;
    return _sequence;
  }

  int _readClock(int fallback) {
    try {
      final value = _clock().millisecondsSinceEpoch;
      if (value < fallback) {
        diagnostic(DiagnosticReasons.clockRegression);
        return fallback;
      }
      if (value > maxTelemetryTimestampMs) {
        diagnostic(DiagnosticReasons.clockError);
        return fallback;
      }
      return value;
    } catch (_) {
      diagnostic(DiagnosticReasons.clockError);
      return fallback;
    }
  }
}

// This data-only message never contains the recorder's clock, callbacks,
// registries or Flutter owner. The detached histograms cannot be mutated by
// later collection. A top-level entry prevents an isolate closure capturing
// the owning monitor, its timers or platform channels.
Future<List<TelemetryEvent>> _runRecorderWorker(
  List<TelemetryEvent> Function() compute,
) => Isolate.run(compute);

final class _RecorderWindow {
  const _RecorderWindow(
    this.identity,
    this.sessionId,
    this.startMs,
    this.endMs,
    this.sequenceBefore,
    this.series,
    this.diagnostics,
  );

  final MonitorIdentity identity;
  final String sessionId;
  final int startMs;
  final int endMs;
  final int sequenceBefore;
  final Map<_SeriesKey, Histogram> series;
  final Map<String, int> diagnostics;

  bool get isEmpty => series.isEmpty && diagnostics.isEmpty;
  int get sequenceEnd => sequenceBefore + series.length + diagnostics.length;

  List<TelemetryEvent> materialize() {
    try {
      return _materialize();
    } on ArgumentError {
      throw const RecorderDrainException(RecorderDrainFailureKind.validation);
    }
  }

  List<TelemetryEvent> _materialize() {
    final events = <TelemetryEvent>[];
    var sequence = sequenceBefore;
    final metadata = identity.toJson();
    Map<String, Object?> common() => {
      'schema_version': 1,
      'event_id': '$sessionId:${++sequence}',
      'session_id': sessionId,
      'sequence': sequence,
      'window_start_unix_ms': startMs,
      'window_end_unix_ms': endMs,
      ...metadata,
    };
    for (final entry in series.entries) {
      final histogram = entry.value;
      final key = entry.key;
      events.add(
        materializeRecorderEvent(common(), {
          'kind': 'histogram',
          'metric': key.metric,
          'scene': key.scene,
          'operation': key.operation,
          'nominal_hz': key.nominalHz,
          'bounds': histogram.bounds,
          'bucket_counts': histogram.bucketCounts,
          'count': histogram.count,
          'sum': histogram.sum,
          'max': histogram.max,
          'over_budget_count': histogram.overBudgetCount,
          'budget_us': key.budgetUs,
        }),
      );
    }
    for (final entry in diagnostics.entries) {
      events.add(
        materializeRecorderEvent(common(), {
          'kind': 'diagnostic',
          'reason': entry.key,
          'count': entry.value,
        }),
      );
    }
    return List<TelemetryEvent>.unmodifiable(events);
  }
}

final class _SeriesKey {
  const _SeriesKey(
    this.metric,
    this.scene,
    this.operation,
    this.nominalHz,
    this.budgetUs,
  );
  final String metric;
  final String scene;
  final String operation;
  final num? nominalHz;
  final num? budgetUs;
  @override
  int get hashCode =>
      Object.hash(metric, scene, operation, nominalHz, budgetUs);
  @override
  bool operator ==(Object other) =>
      other is _SeriesKey &&
      metric == other.metric &&
      scene == other.scene &&
      operation == other.operation &&
      nominalHz == other.nominalHz &&
      budgetUs == other.budgetUs;
}
