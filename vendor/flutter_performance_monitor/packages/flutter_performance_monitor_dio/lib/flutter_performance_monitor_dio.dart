import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_performance_monitor/flutter_performance_monitor.dart';

/// Decorates the application's existing Dio transport; it never creates one.
///
/// 2026-10-23: measure at HttpClientAdapter.fetch rather than onResponse, because
/// Dio transforms/consumes the body before response interceptors are invoked.
/// The returned response, stream, upload stream, cancellation and close remain
/// owned by Dio. No URL, headers, options, exception or body is retained by the
/// monitor. Adapters that buffer a complete body before returning cannot supply
/// headers-only timing and should not use this decorator for that metric.
class MonitoredDioAdapter implements HttpClientAdapter {
  MonitoredDioAdapter(
    this._inner, {
    required PerformanceMonitor? Function() monitor,
  }) : _monitor = monitor;

  final HttpClientAdapter _inner;
  final PerformanceMonitor? Function() _monitor;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    HttpRequestTiming? timing;
    var cancellationRequested = false;
    // IOHttpClientAdapter aborts its socket on this signal; its fetch may then
    // throw HttpException rather than DioExceptionType.cancel. Observe the
    // transport's cancellation contract instead of inferring it from a socket.
    if (cancelFuture != null) {
      unawaited(
        cancelFuture.then<void>(
          (_) {
            cancellationRequested = true;
          },
          onError: (Object _) {
            cancellationRequested = true;
          },
        ),
      );
    }
    try {
      timing = _monitor()?.startHttpRequest(options.method);
    } catch (_) {
      // Match MonitoredHttpClient: an application's failing monitor factory must
      // not replace the business transport outcome.
    }
    try {
      final response = await _inner.fetch(options, requestStream, cancelFuture);
      timing?.headersReceived(response.statusCode);
      return response;
    } catch (error) {
      if (cancellationRequested ||
          options.cancelToken?.isCancelled == true ||
          (error is DioException && CancelToken.isCancel(error))) {
        timing?.cancelled();
      } else {
        timing?.failed();
      }
      rethrow;
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
