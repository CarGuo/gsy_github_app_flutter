import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'frame_tracker.dart';
import 'capacity.dart';
import 'http_request_timing.dart';
import 'model.dart';
import 'monitored_http_client.dart';
import 'native_resources.dart';
import 'navigation.dart';
import 'outbox.dart';
import 'otlp.dart';
import 'recorder.dart';

/// Centralized bounded configuration. These defaults are safety budgets, not SLOs.
class MonitorConfig {
  MonitorConfig({
    required this.identity,
    required this.endpoint,
    Iterable<String> scenes = const [],
    Iterable<String> operations = const [],
    this.enabled = true,
    this.sessionSampleRate = 1,
    this.windowInterval = const Duration(seconds: 30),
    this.resourceInterval = const Duration(seconds: 5),
    this.collectResources = true,
    this.maxFrameContexts = 2048,
    this.frameContextMaxAge = const Duration(seconds: 30),
    this.recorderLimits = const RecorderLimits(),
    this.outboxLimits = const OutboxLimits(),
    this.allowInsecureLoopback = false,
    this.transportFactory,
  }) : scenes = List.unmodifiable(scenes.take(recorderLimits.maxScenes + 1)),
       operations = List.unmodifiable(
         operations.take(recorderLimits.maxOperations + 1),
       ) {
    outboxLimits.validate();
    recorderLimits.validate();
    validateOtlpEndpoint(
      endpoint,
      allowInsecureLoopback: allowInsecureLoopback,
    );
    if (!sessionSampleRate.isFinite ||
        sessionSampleRate < 0 ||
        sessionSampleRate > 1) {
      throw ArgumentError.value(
        sessionSampleRate,
        'sessionSampleRate',
        'Must be between 0 and 1',
      );
    }
    if (windowInterval <= Duration.zero ||
        resourceInterval <= Duration.zero ||
        frameContextMaxAge <= Duration.zero ||
        maxFrameContexts < 1 ||
        maxFrameContexts > 65536) {
      throw ArgumentError(
        'Intervals and bounded frame capacity must be positive',
      );
    }
    capacityEstimate = MonitorCapacityEstimate.forConfiguration(
      identity: identity,
      recorder: recorderLimits,
      outbox: outboxLimits,
      windowInterval: windowInterval,
    );
  }

  final MonitorIdentity identity;
  final Uri endpoint;
  final List<String> scenes;
  final List<String> operations;
  final bool enabled;
  final double sessionSampleRate;
  final Duration windowInterval;
  final Duration resourceInterval;
  final bool collectResources;
  final int maxFrameContexts;
  final Duration frameContextMaxAge;
  final RecorderLimits recorderLimits;
  final OutboxLimits outboxLimits;
  final bool allowInsecureLoopback;
  late final MonitorCapacityEstimate capacityEstimate;

  /// Optional fresh, dedicated exporter transport for an integrator's authenticated
  /// ingress. Called once per selected session, after resolving storage, never
  /// when disabled or sampled out. The monitor owns and closes the returned
  /// transport; do not return the application's shared HTTP client.
  /// Credentials belong in transport memory, never in endpoint URLs or events.
  /// Custom transports must honor TLS, deadlines, response limits and no-redirect
  /// semantics described by [OtlpTransport]. The default sends no auth headers.
  final OtlpTransport Function()? transportFactory;

  bool _equivalentTo(MonitorConfig other) =>
      mapEquals(identity.toJson(), other.identity.toJson()) &&
      endpoint == other.endpoint &&
      listEquals(scenes, other.scenes) &&
      listEquals(operations, other.operations) &&
      enabled == other.enabled &&
      sessionSampleRate == other.sessionSampleRate &&
      windowInterval == other.windowInterval &&
      resourceInterval == other.resourceInterval &&
      collectResources == other.collectResources &&
      maxFrameContexts == other.maxFrameContexts &&
      frameContextMaxAge == other.frameContextMaxAge &&
      recorderLimits.maxSeries == other.recorderLimits.maxSeries &&
      recorderLimits.maxScenes == other.recorderLimits.maxScenes &&
      recorderLimits.maxOperations == other.recorderLimits.maxOperations &&
      outboxLimits.equivalentTo(other.outboxLimits) &&
      allowInsecureLoopback == other.allowInsecureLoopback &&
      transportFactory == other.transportFactory;
}

/// One performance-only monitor per Flutter isolate/engine.
///
/// Initialize before runApp. Equivalent starts return the existing instance;
/// changing configuration requires disposal and otherwise throws [StateError].
/// No global error handlers or HTTP overrides
/// are installed. Application HTTP clients remain owned by the application.
class PerformanceMonitor with WidgetsBindingObserver {
  PerformanceMonitor._(this.config, this._selected)
    : _recorder = MetricRecorder(
        config.identity,
        MonitorIdentity.newSessionId(),
        limits: config.recorderLimits,
      ) {
    if (_selected) {
      _recorder.registerScenes(config.scenes);
      _recorder.registerOperations(config.operations);
    }
    navigatorObserver = PerformanceNavigatorObserver(onScene: setScene);
  }

  static PerformanceMonitor? _instance;
  static Future<PerformanceMonitor>? _starting;

  static Future<PerformanceMonitor> start(
    MonitorConfig config, {
    Directory? storageDirectory,
  }) {
    final instance = _instance;
    if (instance != null) {
      if (!instance._disposed) {
        // 2026-10-23: returning an enabled singleton for enabled:false, or an
        // old endpoint after a new configuration, silently violates consent
        // and routing. Keep idempotent starts but make conflicts explicit.
        if (!instance.config._equivalentTo(config) ||
            (storageDirectory != null &&
                instance._storageDirectoryPath !=
                    storageDirectory.absolute.path)) {
          return Future.error(
            StateError(
              'Dispose the existing PerformanceMonitor before changing configuration or storage',
            ),
          );
        }
        return Future.value(instance);
      }
      return instance.dispose().then(
        (_) => start(config, storageDirectory: storageDirectory),
      );
    }
    return _starting ??= _initialize(config, storageDirectory).whenComplete(() {
      _starting = null;
    });
  }

  static Future<PerformanceMonitor> _initialize(
    MonitorConfig config,
    Directory? storageDirectory,
  ) async {
    // Sampling/permission decisions precede binding hooks, disk recovery and export.
    final selected =
        config.enabled &&
        (config.sessionSampleRate == 1 ||
            (config.sessionSampleRate > 0 &&
                Random.secure().nextDouble() < config.sessionSampleRate));
    final monitor = PerformanceMonitor._(config, selected);
    monitor._storageDirectoryPath = storageDirectory?.absolute.path;
    if (!selected) {
      _instance = monitor;
      return monitor;
    }
    if (config.capacityEstimate.warnings.isNotEmpty) {
      monitor._diagnostic('configured_export_capacity');
    }
    final binding = WidgetsFlutterBinding.ensureInitialized();
    final earlyInitialization =
        binding.rootElement == null && !binding.firstFrameRasterized;
    monitor._automaticExportAllowed = binding.firstFrameRasterized;
    final startup = Stopwatch()..start();
    if (earlyInitialization) {
      monitor._startupWatch = startup;
    } else {
      startup.stop();
      monitor._diagnostic('startup_late_initialization');
    }
    monitor._frames = FrameTracker(
      recorder: monitor._recorder,
      currentScene: () => SceneSnapshot(monitor._scene, monitor._sceneRevision),
      onDiagnostic: monitor._diagnostic,
      onFirstTiming: monitor._firstTimingObserved,
      maxContexts: config.maxFrameContexts,
      contextMaxAge: config.frameContextMaxAge,
    );
    if (config.collectResources) monitor._resources = NativeResourceProvider();
    monitor._foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed ||
        binding.lifecycleState == AppLifecycleState.inactive;
    binding.addObserver(monitor);
    _instance = monitor;
    monitor._storageReady = monitor._openStorage(storageDirectory);
    if (monitor._foreground) {
      monitor._resume();
    } else {
      // Use the same startup invalidation for an initially background engine
      // and for a later pause; neither interval observes foreground startup.
      monitor._pause();
    }
    return monitor;
  }

  final MonitorConfig config;
  final bool _selected;
  final MetricRecorder _recorder;
  late final PerformanceNavigatorObserver navigatorObserver;
  ReliableOutbox? _outbox;
  FrameTracker? _frames;
  NativeResourceProvider? _resources;
  NativeCpuFailure? _retainedCpuFailure;
  String? _storageDirectoryPath;
  Timer? _windowTimer;
  Timer? _resourceTimer;
  Stopwatch? _startupWatch;
  bool _foreground = true;
  bool _disposed = false;
  bool _resourceInFlight = false;
  bool _automaticExportAllowed = false;
  int _resourceGeneration = 0;
  String _scene = 'unknown';
  int _sceneRevision = 0;
  Future<void> _storageReady = Future.value();
  Future<void>? _persisting;
  bool _persistRequested = false;
  Future<void>? _exporting;
  bool _exportRequested = false;
  Future<void>? _disposeFuture;

  bool get active => _selected && !_disposed;
  String get currentScene => _scene;
  FrameStats get frameStats => _frames?.stats ?? const FrameStats();
  Map<String, int> get diagnostics => Map.unmodifiable(_recorder.diagnostics);
  int get pendingBatches => _outbox?.pendingBatches ?? 0;
  int get pendingBytes => _outbox?.pendingBytes ?? 0;

  /// Latest CPU request failure, retained across success and disposal.
  /// Contains only a fixed category and whole channel wait, never error text.
  /// 2026-10-23: expose the monitor-owned provider's diagnostic in production.
  NativeCpuFailure? get lastCpuFailure =>
      _resources?.lastCpuFailure ?? _retainedCpuFailure;

  // Disk recovery is deliberately asynchronous and cannot delay runApp.
  Future<void> _openStorage(Directory? storageDirectory) async {
    OtlpTransport? transport;
    try {
      final directory =
          storageDirectory ??
          Directory(
            '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}flutter_performance_monitor',
          );
      _storageDirectoryPath = directory.absolute.path;
      transport = config.transportFactory?.call();
      _outbox = await ReliableOutbox.open(
        directory,
        config.endpoint,
        limits: config.outboxLimits,
        transport: transport,
        allowInsecureLoopback: config.allowInsecureLoopback,
        onDiagnostic: (reason, count) =>
            _recorder.diagnostic(reason, count: count),
      );
      _outbox!.setAutomaticExportEnabled(_automaticExportAllowed);
      _outbox!.setForeground(active && _foreground);
    } catch (_) {
      if (_outbox == null) {
        try {
          transport?.close();
        } catch (_) {
          // A custom cleanup failure must not escape into the application.
        }
      }
      _diagnostic('storage_unavailable');
    }
  }

  void _diagnostic(String reason) => _recorder.diagnostic(reason);

  void registerScenes(Iterable<String> scenes) {
    if (active) _recorder.registerScenes(scenes);
  }

  void registerOperations(Iterable<String> operations) {
    if (active) _recorder.registerOperations(operations);
  }

  /// Set a registered stable scene at a shared tab/container boundary.
  /// Unregistered strings are discarded without being retained or transmitted.
  void setScene(String scene) {
    if (!active) return;
    final safe = _recorder.resolveScene(scene);
    // Even equal/unknown labels can represent a different navigation revision.
    _scene = safe;
    _sceneRevision++;
    _frames?.sceneChanged();
  }

  /// Starts a transport observation without retaining request data.
  /// Adapters complete this at response headers, before body transformation.
  HttpRequestTiming? startHttpRequest(String method) => beginHttpRequestTiming(
    method: method,
    currentScene: () => _scene,
    enabled: () => active && _foreground,
    onHeaders: (duration, scene) =>
        _recorder.record('network_headers_us', duration, scene: scene),
    onDiagnostic: _diagnostic,
  );

  MonitoredHttpClient wrapHttpClient(http.Client inner) =>
      MonitoredHttpClient.withRequestTiming(
        inner,
        startRequest: startHttpRequest,
      );

  /// Measures a centrally declared operation's wall time, not CPU or correctness.
  Future<T> traceOperation<T>(
    String operation,
    Future<T> Function() body,
  ) async {
    if (!active || !_foreground) return body();
    final safeOperation = _recorder.resolveOperation(operation);
    final scene = _scene;
    final watch = Stopwatch()..start();
    try {
      return await body();
    } finally {
      watch.stop();
      if (active && _foreground) {
        _recorder.record(
          'operation_us',
          watch.elapsedMicroseconds,
          scene: scene,
          operation: safeOperation,
        );
      }
    }
  }

  void _firstTimingObserved() {
    // 2026-10-23: recovery and automatic window timers may persist immediately,
    // but cannot compete with the application's first frame for network work.
    // An integrator's explicit flush remains an intentional immediate export.
    if (active && !_automaticExportAllowed) {
      _automaticExportAllowed = true;
      _outbox?.setAutomaticExportEnabled(true);
      if (_foreground) unawaited(_automaticFlush());
    }
    final watch = _startupWatch;
    if (watch == null || !active) return;
    _startupWatch = null;
    watch.stop();
    // Notification-observed upper bound; never mix engine and Stopwatch epochs.
    _recorder.record(
      'flutter_init_to_first_raster_observed_us',
      watch.elapsedMicroseconds,
    );
    _diagnostic('startup_observed_notification');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!active) return;
    // Inactive can be a visible app temporarily without input focus.
    final foreground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (foreground) {
      _resume();
    } else {
      _pause();
      unawaited(_persistWindow());
    }
  }

  void _resume() {
    if (!active) return;
    _resourceGeneration++;
    _resources?.reset();
    _frames?.start();
    _outbox?.setForeground(true);
    _windowTimer ??= Timer.periodic(config.windowInterval, (_) {
      unawaited(_automaticFlush());
    });
    if (_resources != null) {
      _resourceTimer ??= Timer.periodic(config.resourceInterval, (_) {
        unawaited(_sampleResources());
      });
      unawaited(_sampleResources());
    }
    unawaited(_automaticFlush());
  }

  Future<void> _automaticFlush() =>
      _automaticExportAllowed ? flush() : _persistWindow();

  void _pause() {
    if (_startupWatch != null) {
      // 2026-10-23: a startup observation crossing background time cannot
      // represent Flutter initialization latency. Do not resume this stopwatch.
      _startupWatch!.stop();
      _startupWatch = null;
      _diagnostic('startup_interrupted');
    }
    _windowTimer?.cancel();
    _windowTimer = null;
    _resourceTimer?.cancel();
    _resourceTimer = null;
    _resourceGeneration++;
    _resources?.reset();
    _frames?.pause();
    _outbox?.setForeground(false);
  }

  Future<void> _sampleResources() async {
    if (!active || !_foreground || _resourceInFlight) return;
    _resourceInFlight = true;
    final generation = _resourceGeneration;
    final scene = _scene;
    try {
      final sample = await _resources!.sample();
      if (!active || !_foreground || generation != _resourceGeneration) return;
      for (final diagnostic in sample.diagnostics) {
        _diagnostic(diagnostic);
      }
      if (sample.rssBytes != null) {
        _recorder.record('process_rss_bytes', sample.rssBytes!, scene: scene);
      }
      if (sample.cpuCoresUsed != null) {
        _recorder.record(
          'process_cpu_cores',
          sample.cpuCoresUsed!,
          scene: 'unknown',
        );
      }
    } catch (_) {
      if (active) _diagnostic('resource_sample_error');
    } finally {
      _resourceInFlight = false;
    }
  }

  // Disk persistence has its own serialized lane. A slow network request must
  // not delay a newer window requested by a background transition.
  Future<void> _persistWindow() {
    _persistRequested = true;
    final pending = _persisting;
    if (pending != null) return pending;
    final completion = Completer<void>();
    _persisting = completion.future;
    unawaited(_drainRequestedWindows(completion));
    return completion.future;
  }

  Future<void> _drainRequestedWindows(Completer<void> completion) async {
    try {
      await _storageReady;
      if (_outbox?.isAvailable != true) {
        _persistRequested = false;
        return;
      }
      while (_persistRequested) {
        // A request arriving during enqueue sets this again. Coalesce to one
        // pending drain rather than retaining an unbounded list of closures.
        _persistRequested = false;
        final events = await _recorder.drainAsync();
        if (events.isNotEmpty) await _outbox?.enqueue(events);
      }
    } on RecorderDrainException catch (error) {
      _persistRequested = false;
      _diagnostic(
        error.kind == RecorderDrainFailureKind.validation
            ? 'window_validation_failed'
            : 'window_worker_failed',
      );
    } catch (_) {
      _persistRequested = false;
      _diagnostic('storage_unavailable');
    } finally {
      // Clear the slot synchronously before completing the shared future, so a
      // later request cannot attach to a finished drain and be forgotten.
      _persisting = null;
      completion.complete();
    }
  }

  Future<void> flush() {
    if (!active) return Future.value();
    final persistence = _persistWindow();
    if (!_foreground) return persistence;
    _exportRequested = true;
    final pending = _exporting;
    if (pending != null) return pending;
    final completion = Completer<void>();
    _exporting = completion.future;
    unawaited(_exportRequestedWindows(completion));
    return completion.future;
  }

  Future<void> _exportRequestedWindows(Completer<void> completion) async {
    try {
      while (_exportRequested && active && _foreground) {
        _exportRequested = false;
        await _persistWindow();
        // ReliableOutbox also serializes its exports. Network waiting never
        // owns the durable-window lane; repeated export requests share a bit.
        if (active && _foreground) await _outbox?.flush();
      }
    } catch (_) {
      _diagnostic('storage_unavailable');
    } finally {
      _exportRequested = false;
      _exporting = null;
      completion.complete();
    }
  }

  Future<void> dispose() => _disposeFuture ??= _dispose();
  Future<void> _dispose() async {
    _disposed = true;
    _pause();
    _frames?.dispose();
    navigatorObserver.dispose();
    _startupWatch?.stop();
    _startupWatch = null;
    if (_selected) WidgetsBinding.instance.removeObserver(this);
    await _persistWindow();
    await _outbox?.dispose();
    _retainedCpuFailure = _resources?.lastCpuFailure;
    _resources = null;
    _outbox = null;
    if (identical(_instance, this)) _instance = null;
  }
}
