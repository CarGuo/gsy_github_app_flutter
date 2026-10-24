import 'dart:convert';
import 'dart:math';

/// Integer ceiling that survives JSON consumers using IEEE-754 numbers.
const int maxTelemetryInteger = 9007199254740991;

/// Largest millisecond timestamp representable as OTLP uint64 nanoseconds.
const int maxTelemetryTimestampMs = 18446744073709;

/// Fixed metric names and histogram boundaries for schema version 1.
abstract final class Metrics {
  static const frameBuildUs = 'frame_build_us';
  static const frameRasterUs = 'frame_raster_us';
  static const frameTotalSpanUs = 'frame_total_span_us';
  static const networkHeadersUs = 'network_headers_us';
  static const operationUs = 'operation_us';
  static const flutterInitToFirstRasterObservedUs =
      'flutter_init_to_first_raster_observed_us';
  static const processRssBytes = 'process_rss_bytes';
  static const processCpuCores = 'process_cpu_cores';
  static const latencyBounds = <num>[
    100,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    12000,
    16000,
    20000,
    24000,
    32000,
    48000,
    64000,
    96000,
    128000,
    256000,
    512000,
    1000000,
    2000000,
    5000000,
    10000000,
  ];
  static const rssBounds = <num>[
    16777216,
    33554432,
    67108864,
    134217728,
    268435456,
    536870912,
    1073741824,
    2147483648,
    4294967296,
    8589934592,
  ];
  static const cpuBounds = <num>[.125, .25, .5, 1, 2, 4, 8, 16];
  static const all = <String>{
    frameBuildUs,
    frameRasterUs,
    frameTotalSpanUs,
    networkHeadersUs,
    operationUs,
    flutterInitToFirstRasterObservedUs,
    processRssBytes,
    processCpuCores,
  };

  static List<num>? boundsFor(String metric) => switch (metric) {
    processRssBytes => rssBounds,
    processCpuCores => cpuBounds,
    frameBuildUs ||
    frameRasterUs ||
    frameTotalSpanUs ||
    networkHeadersUs ||
    operationUs ||
    flutterInitToFirstRasterObservedUs => latencyBounds,
    _ => null,
  };

  static bool isFrame(String metric) =>
      metric == frameBuildUs ||
      metric == frameRasterUs ||
      metric == frameTotalSpanUs;
}

/// Diagnostic values are fixed to avoid collecting exception/URL text.
abstract final class DiagnosticReasons {
  static const invalidMetric = 'invalid_metric';
  static const invalidSample = 'invalid_sample';
  static const invalidNominalHz = 'invalid_nominal_hz';
  static const invalidBudget = 'invalid_budget';
  static const invalidLabel = 'invalid_label';
  static const unregisteredScene = 'unregistered_scene';
  static const unregisteredOperation = 'unregistered_operation';
  static const sceneRegistryFull = 'scene_registry_full';
  static const operationRegistryFull = 'operation_registry_full';
  static const seriesLimit = 'series_limit';
  static const accumulatorOverflow = 'accumulator_overflow';
  static const invalidDiagnostic = 'invalid_diagnostic';
  static const invalidDiagnosticCount = 'invalid_diagnostic_count';
  static const clockError = 'clock_error';
  static const clockRegression = 'clock_regression';
  static const all = <String>{
    invalidMetric,
    invalidSample,
    invalidNominalHz,
    invalidBudget,
    invalidLabel,
    unregisteredScene,
    unregisteredOperation,
    sceneRegistryFull,
    operationRegistryFull,
    seriesLimit,
    accumulatorOverflow,
    invalidDiagnostic,
    invalidDiagnosticCount,
    clockError,
    clockRegression,
    'frame_context_unmatched',
    'frame_context_repeated',
    'frame_context_evicted',
    'frame_context_ambiguous',
    'frame_context_stale',
    'frame_multiview',
    'startup_unobservable',
    'resource_unsupported',
    'resource_sample_failed',
    'resource_invalid_delta',
    'network_error',
    'frame_context_expired',
    'frame_capture_stale',
    'frame_capture_error',
    'frame_timing_unmatched',
    'frame_timing_repeated',
    'frame_timing_pre_start',
    'frame_scene_ambiguous',
    'frame_multiview_unknown',
    'frame_timing_record',
    'frame_timing_attributed',
    'frame_ui_over_budget',
    'frame_raster_over_budget',
    'frame_either_over_budget',
    'startup_late_initialization',
    'startup_observed_notification',
    // 2026-10-23: distinguish invalid startup intervals and worker failures
    // from filesystem failure; no exception strings enter the event schema.
    'startup_interrupted',
    'window_worker_failed',
    'window_validation_failed',
    'resource_sample_error',
    'resource_rss_unsupported',
    'collection_callback_error',
    'network_failed',
    'network_cancelled',
    'network_status_1xx',
    'network_status_2xx',
    'network_status_3xx',
    'network_status_4xx',
    'network_status_5xx',
    'network_status_other',
    'network_method_get',
    'network_method_post',
    'network_method_put',
    'network_method_patch',
    'network_method_delete',
    'network_method_head',
    'network_method_options',
    'network_method_other',
    'resource_cpu_unsupported',
    'resource_cpu_error',
    'resource_cpu_invalid',
    'resource_rss_error',
    'resource_rss_invalid',
    'resource_sample_in_flight',
    'storage_unavailable',
    'storage_locked',
    'disk_error',
    'corrupt_batch',
    'unsupported_batch',
    'uncommitted_batch',
    'recovery_limit',
    'endpoint_changed',
    'clock_skew',
    'queue_capacity',
    'event_too_large',
    'expired_batch',
    'attempts_expired',
    'transport_error',
    'response_too_large',
    'retryable_response',
    'auth_required',
    'configured_export_capacity',
    'permanent_rejection',
    'invalid_response',
    'partial_success',
    'partial_rejected_records',
    'rate_limited',
    'callback_error',
    'enqueue_after_dispose',
  };
}

final RegExp _stableLabel = RegExp(r'^[a-zA-Z0-9_/][a-zA-Z0-9_./:{}-]*$');
final RegExp _metadataLabel = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$');

/// Intended for centrally registered route names/templates, never route values.
bool isValidStableLabel(String value) =>
    value.isNotEmpty && value.length <= 96 && _stableLabel.hasMatch(value);

bool _metadata(String value, {bool empty = false}) =>
    (empty && value.isEmpty) ||
    (value.isNotEmpty && value.length <= 64 && _metadataLabel.hasMatch(value));

/// Build metadata only: this deliberately has no user or persistent device ID.
final class MonitorIdentity {
  factory MonitorIdentity({
    required String appId,
    required String appVersion,
    required String platform,
    required String buildMode,
    String deviceClass = 'unknown',
    String mode = 'daily',
    String runId = '',
    String flutterVersion = 'unknown',
  }) {
    if (![
          appId,
          appVersion,
          platform,
          buildMode,
          deviceClass,
          flutterVersion,
        ].every(_metadata) ||
        !_metadata(runId, empty: true) ||
        !const {'daily', 'test'}.contains(mode) ||
        !const {'debug', 'profile', 'release', 'unknown'}.contains(buildMode)) {
      throw ArgumentError(
        'Identity requires bounded build labels and a valid mode',
      );
    }
    return MonitorIdentity._(
      appId,
      appVersion,
      platform,
      buildMode,
      deviceClass,
      mode,
      runId,
      flutterVersion,
    );
  }

  const MonitorIdentity._(
    this.appId,
    this.appVersion,
    this.platform,
    this.buildMode,
    this.deviceClass,
    this.mode,
    this.runId,
    this.flutterVersion,
  );

  final String appId;
  final String appVersion;
  final String platform;
  final String buildMode;
  final String deviceClass;
  final String mode;
  final String runId;
  final String flutterVersion;

  Map<String, Object?> toJson() => Map.unmodifiable({
    'app_id': appId,
    'app_version': appVersion,
    'platform': platform,
    'build_mode': buildMode,
    'device_class': deviceClass,
    'mode': mode,
    'run_id': runId,
    'flutter_version': flutterVersion,
  });

  /// A new 128-bit, process-session random ID; callers must not persist it.
  static String newSessionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// Immutable, strictly validated schema-1 event. Encoding never changes on retry.
final class TelemetryEvent {
  factory TelemetryEvent(Map<String, Object?> body) {
    final canonical = _validateEvent(body);
    return TelemetryEvent._(Map.unmodifiable(canonical), jsonEncode(canonical));
  }

  const TelemetryEvent._(this.body, this.encoded);
  final Map<String, Object?> body;
  final String encoded;
  String get eventId => body['event_id']! as String;
  String get appId => body['app_id']! as String;
}

const _commonKeys = <String>[
  'schema_version',
  'event_id',
  'session_id',
  'sequence',
  'window_start_unix_ms',
  'window_end_unix_ms',
  'app_id',
  'app_version',
  'platform',
  'build_mode',
  'device_class',
  'mode',
  'run_id',
  'flutter_version',
  'kind',
];
const _histogramKeys = <String>[
  'metric',
  'scene',
  'operation',
  'nominal_hz',
  'bounds',
  'bucket_counts',
  'count',
  'sum',
  'max',
  'over_budget_count',
  'budget_us',
];

Never _invalidEvent() => throw ArgumentError('Invalid telemetry event schema');

bool _integer(Object? value, {int minimum = 0}) =>
    value is int && value >= minimum && value <= maxTelemetryInteger;
bool _number(Object? value) =>
    value is num &&
    value.isFinite &&
    value >= 0 &&
    value <= maxTelemetryInteger;

Map<String, Object?> _validateEvent(Map<String, Object?> input) {
  final kind = input['kind'];
  final keys = <String>[
    ..._commonKeys,
    if (kind == 'histogram')
      ..._histogramKeys
    else if (kind == 'diagnostic') ...[
      'reason',
      'count',
    ] else
      _invalidEvent(),
  ];
  if (input.length != keys.length ||
      !keys.every(input.containsKey) ||
      input['schema_version'] is! int ||
      input['schema_version'] != 1 ||
      !_integer(input['sequence'], minimum: 1) ||
      !_integer(input['window_start_unix_ms']) ||
      !_integer(input['window_end_unix_ms']) ||
      (input['window_start_unix_ms']! as int) > maxTelemetryTimestampMs ||
      (input['window_end_unix_ms']! as int) > maxTelemetryTimestampMs ||
      (input['window_end_unix_ms']! as int) <
          (input['window_start_unix_ms']! as int)) {
    _invalidEvent();
  }
  final session = input['session_id'];
  if (session is! String ||
      !_metadata(session) ||
      input['event_id'] != '$session:${input['sequence']}') {
    _invalidEvent();
  }
  for (final key in const [
    'app_id',
    'app_version',
    'platform',
    'build_mode',
    'device_class',
    'flutter_version',
  ]) {
    if (input[key] is! String || !_metadata(input[key]! as String)) {
      _invalidEvent();
    }
  }
  if (input['run_id'] is! String ||
      !_metadata(input['run_id']! as String, empty: true) ||
      !const {'daily', 'test'}.contains(input['mode']) ||
      !const {
        'debug',
        'profile',
        'release',
        'unknown',
      }.contains(input['build_mode'])) {
    _invalidEvent();
  }
  final output = {for (final key in keys) key: input[key]};
  if (kind == 'diagnostic') {
    if (!DiagnosticReasons.all.contains(input['reason']) ||
        !_integer(input['count'], minimum: 1)) {
      _invalidEvent();
    }
    return output;
  }
  final metric = input['metric'];
  final expectedBounds = metric is String ? Metrics.boundsFor(metric) : null;
  final bounds = input['bounds'];
  final counts = input['bucket_counts'];
  if (expectedBounds == null ||
      bounds is! List ||
      counts is! List ||
      bounds.length != expectedBounds.length ||
      counts.length != bounds.length + 1 ||
      !_integer(input['count'], minimum: 1) ||
      !_number(input['sum']) ||
      !_number(input['max']) ||
      !_integer(input['over_budget_count'])) {
    _invalidEvent();
  }
  for (var i = 0; i < bounds.length; i++) {
    if (bounds[i] is! num || bounds[i] != expectedBounds[i]) _invalidEvent();
  }
  var total = 0;
  var highestBucket = 0;
  for (var i = 0; i < counts.length; i++) {
    final count = counts[i];
    if (!_integer(count)) _invalidEvent();
    total += count as int;
    if (total > maxTelemetryInteger) _invalidEvent();
    if (count > 0) highestBucket = i;
  }
  final maximum = input['max']! as num;
  final sum = input['sum']! as num;
  final overBudget = input['over_budget_count']! as int;
  if (total != input['count'] ||
      overBudget > total ||
      maximum > sum ||
      (highestBucket > 0 && maximum <= expectedBounds[highestBucket - 1]) ||
      (highestBucket < expectedBounds.length &&
          maximum > expectedBounds[highestBucket])) {
    _invalidEvent();
  }
  // Float sums may accumulate roundoff. Integer counts and bucket membership
  // remain exact; use a small relative tolerance only for the aggregate sum.
  final tolerance = max(1.0, sum.toDouble()) * 1e-9;
  if (sum > maximum.toDouble() * total + tolerance) _invalidEvent();
  var lowerSum = 0.0;
  var upperSum = 0.0;
  for (var i = 0; i < counts.length; i++) {
    final count = counts[i] as int;
    lowerSum += (i == 0 ? 0.0 : expectedBounds[i - 1].toDouble()) * count;
    upperSum +=
        (i == expectedBounds.length
            ? maximum.toDouble()
            : min(maximum, expectedBounds[i]).toDouble()) *
        count;
  }
  // At least one observation must equal the declared maximum. Replace its
  // bucket's lower endpoint rather than counting every sample at that endpoint.
  lowerSum +=
      maximum.toDouble() -
      (highestBucket == 0 ? 0.0 : expectedBounds[highestBucket - 1].toDouble());
  if (sum + tolerance < lowerSum || sum > upperSum + tolerance) _invalidEvent();
  for (final key in const ['scene', 'operation']) {
    if (input[key] is! String || !isValidStableLabel(input[key]! as String)) {
      _invalidEvent();
    }
  }
  final hz = input['nominal_hz'];
  final budget = input['budget_us'];
  if (hz != null && (!_number(hz) || (hz as num) <= 0 || hz > 1000)) {
    _invalidEvent();
  }
  if (budget != null && (!_number(budget) || (budget as num) <= 0)) {
    _invalidEvent();
  }
  if (budget == null && overBudget != 0) _invalidEvent();
  if (budget is num &&
      ((maximum <= budget && overBudget != 0) ||
          (maximum > budget && overBudget == 0))) {
    _invalidEvent();
  }
  if (budget is num) {
    var minimumOverBudget = 0;
    var maximumOverBudget = 0;
    for (var i = 0; i < counts.length; i++) {
      final lower = i == 0 ? 0 : expectedBounds[i - 1];
      final upper = i == expectedBounds.length
          ? maximum
          : min(maximum, expectedBounds[i]);
      if (lower >= budget) minimumOverBudget += counts[i] as int;
      if (upper > budget) maximumOverBudget += counts[i] as int;
    }
    if (overBudget < minimumOverBudget || overBudget > maximumOverBudget) {
      _invalidEvent();
    }
  }
  if (!Metrics.isFrame(metric as String) && (hz != null || budget != null)) {
    _invalidEvent();
  }
  output['bounds'] = expectedBounds;
  output['bucket_counts'] = List<int>.unmodifiable(counts.cast<int>());
  return output;
}
