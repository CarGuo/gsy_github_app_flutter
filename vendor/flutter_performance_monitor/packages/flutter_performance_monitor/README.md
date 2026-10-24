# flutter_performance_monitor

Private performance-only Flutter SDK: passive engine frame context, fixed
histograms, shared HTTP headers timing, optional operation timing, process
resources and a bounded durable OTLP outbox. See the repository
[README](../../README.md) and [verification record](../../docs/validation.md).

## Central integration

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_performance_monitor/flutter_performance_monitor.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final monitor = await PerformanceMonitor.start(MonitorConfig(
    identity: MonitorIdentity(
      appId: 'my_app', appVersion: '1.0.0',
      platform: Platform.operatingSystem,
      buildMode: kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug',
    ),
    endpoint: Uri.parse('https://telemetry.example.com/v1/logs'),
    scenes: const ['/', '/catalog', '/settings'],
    operations: const ['catalog_refresh'],
  ));
  final apiClient = monitor.wrapHttpClient(http.Client());
  // Inject apiClient into the existing shared service layer.
  // Keep and close it using the app's normal service lifecycle.
  runApp(MaterialApp(
    navigatorObservers: [monitor.navigatorObserver],
    routes: {
      '/': (_) => const Scaffold(body: Text('Home')),
      '/catalog': (_) => const Scaffold(body: Text('Catalog')),
      '/settings': (_) => const Scaffold(body: Text('Settings')),
    },
  ));
}
```

Use build-mode metadata matching the artifact being run. Append the observer to
existing observers. No page decorators, global error-handler replacements or
HttpOverrides are required. For go_router, use the separate optional adapter;
for custom tabs use `setScene` at the shared selection boundary. Navigator
observation is scoped to the Navigator where it is installed.

2026-10-23: the HTTP wrapper and optional
[Dio adapter](../flutter_performance_monitor_dio/README.md) share
`monitor.startHttpRequest(method)`. It returns a nullable `HttpRequestTiming`,
captures the starting scene, and accepts only `headersReceived(statusCode)` or
`failed()` to finish once. Disabled/background requests return null; completion
also checks the monitor's current collection state. Transport adapters complete
at response headers before consuming the body. No URL, header, body or exception
is passed to this API; an operation span is a separate business measurement.

An optional existing service boundary can use:

```dart
final result = await monitor.traceOperation('catalog_refresh', () async {
  return service.refreshCatalog();
});
```

Call `flush()` for an explicit window/export attempt. It is not a final-database
commit guarantee. `dispose()` stops collection/export and retains durable queued
data; the application still owns its business client. Starts coalesce; dispose
before changing configuration. `enabled: false` and sampling rejection skip
hooks/storage. Default durable storage uses application support; tests may inject
an app-owned `Directory`.

2026-10-23: real monitor windows use `MetricRecorder.drainAsync()`. The owner
isolate detaches the window before yielding, then a worker isolate materializes,
validates and JSON-encodes its immutable events. Bounded collection and window
ownership remain on the owner isolate. Standalone `MetricRecorder.drain()` is
still synchronous; use `drainAsync()` when that consumer needs worker-side
materialization. This distinction prevents an asynchronous export from being
mistaken for off-isolate event construction, or the whole SDK for zero UI work.

## Measurement and privacy limits

- Reported timing records are the frame denominator; repeated IDs are legitimate and diagnosed
- Navigation context does not prove pixel ownership, completed transitions, physical FPS or dropped frames
- Headers latency excludes response-body download; unwrapped/native/isolate network traffic is not auto-covered
- Startup is SDK init to first raster timing notification observed, including batching delay; late init is skipped
- Process CPU is cores used and may exceed one; RSS is process residency, not Dart heap or page-exclusive memory
- Unsupported resources and unmatched attribution remain explicit; missing data is not zero
- Register bounded route names/templates centrally; route arguments, URLs, request headers/bodies and persistent device IDs are not telemetry

Default limits are safety ceilings, not measured mobile performance promises.
See [architecture](../../docs/architecture.md) for exact semantics and
[integration boundaries](../../docs/integration.md).

## Platform setup

Android/iOS/macOS native samplers register as an ordinary Flutter plugin. macOS
applications need `com.apple.security.network.client = true` in release as well
as debug/profile entitlements while preserving App Sandbox. Android needs INTERNET
permission. Use HTTPS in production. The example's loopback/emulator HTTP opt-in
and debug-only domain configuration are explicitly development-only.

Flutter 3.32 / Dart 3.8 is the intended API floor; the 2026-10-23 current host
checks use native macOS arm64, Flutter 3.47.2 / Dart 3.13.2. Android physical
profile evidence and Apple native compilation are recorded with their exact
revision boundaries in the [validation record](../../docs/validation.md).
Minimum Flutter and iOS physical performance are still unverified. Web is outside scope. The
[example](example/README.md) contains actual ordinary-engine and end-to-end probes,
separate from widget tests.

This private project has no public distribution license selected. See LICENSE;
third-party packages retain their own licenses.

## Online ingestion and recovery

2026-10-23: configure a dedicated ingest credential through
`transportFactory: () => HttpOtlpTransport(authorization: readIngestAuthorization)`.
The callback is evaluated for each send and returns a complete Authorization
value or null. Credentials never enter event bodies or disk batches; redirects
are refused and credentials require HTTPS. Preserve certificate validation.
An ingest key has no dashboard/database administration privileges; never reuse
the application's account token. HTTP 401/403 retain batches with `auth_required`
and normal backoff. Default retention/capacity still bound recovery; an explicit
`maxAttempts` also remains an intentional delivery ceiling.

Automatic exports wait for the first observed raster timing; explicit `flush()`
is an immediate caller request. Unsuccessful materialization retains its detached
window for worker retry; invalid events are individually diagnosed. Each durable
directory has one writer across processes/engines. Engines that need independent
queues must supply distinct stable directories, so restart recovery can find
their pending batches. `capacityEstimate` reports the configured series/window
and queue/export relationship. See [repair rationale](../../docs/sdk-integrity-2026-10-23.md).
