/// Bounded performance-only telemetry. See README for measurement semantics,
/// safe route registries, storage, lifecycle, and tested-platform limitations.
library;

export 'src/capacity.dart' show MonitorCapacityEstimate, CapacityWarning;

export 'src/frame_tracker.dart' show FrameStats;
export 'src/http_request_timing.dart' show HttpRequestTiming;
export 'src/model.dart';
export 'src/monitor.dart';
export 'src/monitored_http_client.dart';
export 'src/native_resources.dart';
export 'src/navigation.dart';
export 'src/outbox.dart';
export 'src/otlp.dart'
    show OtlpTransport, HttpOtlpTransport, OtlpResponse, OtlpResponseTooLarge;
export 'src/recorder.dart';
