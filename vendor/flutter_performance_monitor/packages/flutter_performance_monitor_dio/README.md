# Dio response-header timing

Decorate the existing `Dio.httpClientAdapter` once at its central construction
site. It preserves the application's adapter, request options, upload stream,
cancel future, response stream and close behavior.

```dart
import 'package:flutter_performance_monitor_dio/flutter_performance_monitor_dio.dart';

dio.httpClientAdapter = MonitoredDioAdapter(
  dio.httpClientAdapter,
  monitor: () => monitor,
);
```

2026-10-23: the callback may return null while optional monitoring initializes.
Each fetch obtains the core `startHttpRequest(method)` token, shared with
`MonitoredHttpClient`; it captures the starting scene and completes once at
headers or pre-header failure. Do not decorate the same adapter repeatedly.

The default Dio IO adapter returns `ResponseBody` after headers arrive and before
consuming its stream. This adapter therefore measures `fetch` start to response
headers, including connection/upload work performed by that fetch and excluding
request interceptors, serialization and body download/JSON
transformation. It does not use `Interceptor.onResponse`, which runs after Dio's
body transformation. A custom/native adapter that buffers the body before
returning does not satisfy this headers boundary and must be qualified before use.

Only method group, response status group, elapsed time and the monitor's starting
scene are recorded. URLs, query values, headers, bodies and error text are never
passed to the monitor. HTTP error statuses are header responses; failures before
headers increment `network_failed`; caller cancellation increments
`network_cancelled`. Every terminal outcome counts its method once, including
actual IO aborts caused by CancelToken. Errors while consuming a response body remain application errors and
do not retroactively erase the header observation. A monitor that is absent,
disabled or disposed does not record and does not close the business transport.

Sources: [Dio HttpClientAdapter](https://pub.dev/documentation/dio/latest/dio/HttpClientAdapter-class.html),
[Dio IO adapter source](https://github.com/cfug/dio/blob/main/dio/lib/src/adapters/io_adapter.dart).
