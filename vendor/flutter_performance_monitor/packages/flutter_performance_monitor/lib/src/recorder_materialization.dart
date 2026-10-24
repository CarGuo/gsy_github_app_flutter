import 'model.dart';

/// Internal worker-side validation boundary. Invalid measurements keep their
/// reserved ID as an explicit rejection diagnostic; valid neighbours survive.
TelemetryEvent materializeRecorderEvent(
  Map<String, Object?> common,
  Map<String, Object?> measurement,
) {
  try {
    return TelemetryEvent({...common, ...measurement});
  } on ArgumentError {
    // 2026-10-23: a deterministic malformed series must not discard its window
    // or indefinitely retry and block every later observation. Preserve the
    // exact position while reporting rejection, without serializing raw input.
    return TelemetryEvent({
      ...common,
      'kind': 'diagnostic',
      'reason': 'window_validation_failed',
      'count': 1,
    });
  }
}
