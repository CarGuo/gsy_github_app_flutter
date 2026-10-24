import 'package:http/http.dart' as http;

import 'http_request_timing.dart';

/// Shared HTTP seam recording send-to-response-headers wall time only.
///
/// Does not inspect URL, query, headers, body, cookies, exceptions, or downloaded
/// bytes. This is not DNS/TLS timing, wire latency, or full-download duration.
class MonitoredHttpClient extends http.BaseClient {
  MonitoredHttpClient(
    this._inner, {
    required String Function() currentScene,
    required void Function(int microseconds, String scene) onHeaders,
    required void Function(String reason) onDiagnostic,
    bool Function()? enabled,
  }) : _startRequest = ((method) => beginHttpRequestTiming(
         method: method,
         currentScene: currentScene,
         enabled: enabled ?? _alwaysEnabled,
         onHeaders: onHeaders,
         onDiagnostic: onDiagnostic,
       ));

  MonitoredHttpClient.withRequestTiming(
    this._inner, {
    required HttpRequestTiming? Function(String method) startRequest,
  }) : _startRequest = startRequest;

  final http.Client _inner;
  final HttpRequestTiming? Function(String) _startRequest;
  bool _closed = false;
  static bool _alwaysEnabled() => true;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) throw StateError('HTTP client is closed');
    HttpRequestTiming? timing;
    try {
      timing = _startRequest(request.method);
    } catch (_) {
      // Preserve request behavior if an application supplies a failing factory.
    }
    try {
      final response = await _inner.send(request);
      timing?.headersReceived(response.statusCode);
      return response;
    } catch (error) {
      if (error is http.RequestAbortedException) {
        timing?.cancelled();
      } else {
        timing?.failed();
      }
      rethrow;
    }
  }

  /// Closing the wrapper closes its underlying client exactly once.
  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _inner.close();
  }
}
