/// One send-to-headers observation, shared by HTTP client adapters.
///
/// It retains only a registered scene and a fixed method category. It never
/// receives a URL, request/response headers, body or exception.
final class HttpRequestTiming {
  HttpRequestTiming._(
    this._scene,
    this._methodReason,
    this._enabled,
    this._onHeaders,
    this._onDiagnostic,
  ) : _watch = Stopwatch()..start();

  final String _scene;
  final String _methodReason;
  final bool Function() _enabled;
  final void Function(int, String) _onHeaders;
  final void Function(String) _onDiagnostic;
  final Stopwatch _watch;
  bool _finished = false;

  /// Call when the transport exposes response headers, before reading its body.
  /// Status errors are still responses; body decoding errors occur afterward.
  void headersReceived(int statusCode) => _finish(() {
    _onHeaders(_watch.elapsedMicroseconds, _scene);
    _onDiagnostic(_methodReason);
    final group = statusCode ~/ 100;
    _onDiagnostic(
      'network_status_${group >= 1 && group <= 5 ? '${group}xx' : 'other'}',
    );
  });

  /// Call when the transport fails before exposing headers.
  void failed() => _finish(() {
    _onDiagnostic(_methodReason);
    _onDiagnostic('network_failed');
  });

  /// Intentional caller cancellation is not a transport failure.
  /// 2026-10-23: preserve the method denominator for every terminal outcome.
  void cancelled() => _finish(() {
    _onDiagnostic(_methodReason);
    _onDiagnostic('network_cancelled');
  });

  void _finish(void Function() record) {
    if (_finished) return;
    _finished = true;
    _watch.stop();
    try {
      if (_enabled()) record();
    } catch (_) {
      // Instrumentation callbacks must preserve the original transport outcome.
    }
  }
}

// 2026-10-23: a single measurement boundary serves package:http and Dio without
// relabeling full downloads as header latency or duplicating lifecycle logic.
// Internal factory; only HttpRequestTiming is exported from the public library.
HttpRequestTiming? beginHttpRequestTiming({
  required String method,
  required String Function() currentScene,
  required bool Function() enabled,
  required void Function(int, String) onHeaders,
  required void Function(String) onDiagnostic,
}) {
  try {
    if (!enabled()) return null;
    const methods = {
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
      'HEAD',
      'OPTIONS',
    };
    final normalized = method.toUpperCase();
    final category = methods.contains(normalized)
        ? normalized.toLowerCase()
        : 'other';
    return HttpRequestTiming._(
      currentScene(),
      'network_method_$category',
      enabled,
      onHeaders,
      onDiagnostic,
    );
  } catch (_) {
    // A failing integration callback cannot prevent a business request.
    return null;
  }
}
