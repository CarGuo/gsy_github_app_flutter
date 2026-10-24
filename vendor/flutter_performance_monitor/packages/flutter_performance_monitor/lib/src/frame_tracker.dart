import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'navigation.dart';
import 'recorder.dart';

/// Counts of reported engine timing records, never presented frames or FPS.
class FrameStats {
  const FrameStats({
    this.timingRecords = 0,
    this.attributedTimingRecords = 0,
    this.unattributedTimingRecords = 0,
    this.repeatedFrameNumbers = 0,
    this.preStartTimingRecords = 0,
    this.uiBudgetOverrunRecords = 0,
    this.rasterBudgetOverrunRecords = 0,
    this.eitherBudgetOverrunRecords = 0,
    this.contextEvictions = 0,
    this.contextExpirations = 0,
  });
  final int timingRecords;
  final int attributedTimingRecords;
  final int unattributedTimingRecords;
  final int repeatedFrameNumbers;
  final int preStartTimingRecords;
  final int uiBudgetOverrunRecords;
  final int rasterBudgetOverrunRecords;
  final int eitherBudgetOverrunRecords;

  /// Context cache retirements, including already matched contexts. These are
  /// not lost timing counts; only unmatched retirements emit diagnostics.
  final int contextEvictions;
  final int contextExpirations;
}

class _FrameContext {
  _FrameContext(this.scene, this.nominalHz, this.capturedAtUs);
  final String scene;
  final double? nominalHz;
  final int capturedAtUs;
  bool matched = false;
}

/// Internal bounded frame-number join, with a single passive engine-local broker.
class FrameTracker {
  FrameTracker({
    required this.recorder,
    required this.currentScene,
    required this.onDiagnostic,
    this.onFirstTiming,
    this.maxContexts = 2048,
    this.contextMaxAge = const Duration(seconds: 30),
    int Function()? elapsedMicroseconds,
  }) : _elapsedMicroseconds =
           elapsedMicroseconds ??
           (Stopwatch()..start()).elapsedMicrosecondsGetter {
    if (maxContexts < 1 || contextMaxAge <= Duration.zero) {
      throw ArgumentError('Frame context limits must be positive');
    }
  }

  final MetricRecorder recorder;
  final SceneSnapshot Function() currentScene;
  final void Function(String) onDiagnostic;
  final void Function()? onFirstTiming;
  final int maxContexts;
  final Duration contextMaxAge;
  final int Function() _elapsedMicroseconds;
  final _contexts = <int, _FrameContext>{};
  final _seen = <int, int>{};
  int _startFrameNumber = -1;
  int _lastCapture = -1;
  bool _disposed = false;
  bool _running = false;
  bool _hasTiming = false;
  int _timingRecords = 0;
  int _attributed = 0;
  int _unattributed = 0;
  int _repeated = 0;
  int _preStart = 0;
  int _uiOver = 0;
  int _rasterOver = 0;
  int _eitherOver = 0;
  int _evicted = 0;
  int _expired = 0;

  FrameStats get stats => FrameStats(
    timingRecords: _timingRecords,
    attributedTimingRecords: _attributed,
    unattributedTimingRecords: _unattributed,
    repeatedFrameNumbers: _repeated,
    preStartTimingRecords: _preStart,
    uiBudgetOverrunRecords: _uiOver,
    rasterBudgetOverrunRecords: _rasterOver,
    eitherBudgetOverrunRecords: _eitherOver,
    contextEvictions: _evicted,
    contextExpirations: _expired,
  );

  @visibleForTesting
  int get retainedContexts => _contexts.length;
  @visibleForTesting
  int get currentFrameNumber =>
      WidgetsBinding.instance.platformDispatcher.frameData.frameNumber;
  @visibleForTesting
  static bool get hasActiveCollector => _FrameBroker.instance._active != null;

  /// Called for every scene revision, including changes to the same scene name.
  /// Scene changes before drawing completes make that frame's context ambiguous.
  void sceneChanged() => _FrameBroker.instance.sceneChanged(this);

  void start() {
    if (_disposed || _running) return;
    final binding = WidgetsBinding.instance;
    resetWatermark(currentFrameNumber);
    _FrameBroker.instance.attach(this, binding);
    _running = true;
  }

  void pause() {
    if (!_running) return;
    _FrameBroker.instance.detach(this);
    _running = false;
    _contexts.clear();
    _seen.clear();
  }

  void dispose() {
    if (_disposed) return;
    pause();
    _disposed = true;
    _contexts.clear();
    _seen.clear();
  }

  @visibleForTesting
  void resetWatermark(int frameNumber) {
    _startFrameNumber = frameNumber;
    _lastCapture = frameNumber;
    _contexts.clear();
    _seen.clear();
  }

  void _expire(int now) {
    while (_contexts.isNotEmpty &&
        now - _contexts.values.first.capturedAtUs >
            contextMaxAge.inMicroseconds) {
      final context = _contexts.remove(_contexts.keys.first)!;
      _expired++;
      // 2026-10-23: matched contexts remain for repeated raster records. Their
      // normal retirement is cache housekeeping, not an attribution failure.
      if (!context.matched) onDiagnostic('frame_context_expired');
    }
    while (_seen.isNotEmpty &&
        now - _seen.values.first > contextMaxAge.inMicroseconds) {
      _seen.remove(_seen.keys.first);
    }
  }

  /// Called after the rendering pipeline, once FrameData has been updated.
  @visibleForTesting
  void captureContext({
    required int frameNumber,
    required SceneSnapshot beforeDraw,
    required int afterDrawRevision,
    required int viewCount,
    double? nominalHz,
    bool sceneChangedDuringFrame = false,
  }) {
    if (_disposed) return;
    final now = _elapsedMicroseconds();
    _expire(now);
    if (frameNumber < 0 || frameNumber <= _lastCapture) {
      onDiagnostic('frame_capture_stale');
      return;
    }
    _lastCapture = frameNumber;
    var scene = beforeDraw.scene;
    if (sceneChangedDuringFrame || beforeDraw.revision != afterDrawRevision) {
      scene = 'unknown';
      onDiagnostic('frame_scene_ambiguous');
    }
    if (viewCount != 1) {
      scene = 'unknown';
      nominalHz = null;
      onDiagnostic('frame_multiview_unknown');
    }
    if (nominalHz != null && (!nominalHz.isFinite || nominalHz <= 0)) {
      nominalHz = null;
    }
    if (_contexts.length >= maxContexts) {
      final evicted = _contexts.remove(_contexts.keys.first)!;
      _evicted++;
      if (!evicted.matched) onDiagnostic('frame_context_evicted');
    }
    _contexts[frameNumber] = _FrameContext(scene, nominalHz, now);
  }

  @visibleForTesting
  void recordTimings(List<FrameTiming> timings) {
    if (_disposed) return;
    final now = _elapsedMicroseconds();
    _expire(now);
    for (final timing in timings) {
      _timingRecords++;
      onDiagnostic('frame_timing_record');
      final id = timing.frameNumber;
      if (id >= 0) {
        if (_seen.containsKey(id)) {
          _repeated++;
          onDiagnostic('frame_timing_repeated');
        } else {
          if (_seen.length >= maxContexts) _seen.remove(_seen.keys.first);
          _seen[id] = now;
        }
      }
      if (id >= 0 && id <= _startFrameNumber) {
        _preStart++;
        onDiagnostic('frame_timing_pre_start');
      }
      // 2026-10-23: queued timings from before start/resume cannot establish
      // this session's first raster observation or unlock automatic exports.
      if (!_hasTiming && _running && id >= 0 && id > _startFrameNumber) {
        _hasTiming = true;
        onFirstTiming?.call();
      }
      // Keep context after matching: native raster retries can share an ID.
      final context = _contexts[id];
      if (context != null) context.matched = true;
      final scene = context?.scene ?? 'unknown';
      if (context != null && scene != 'unknown') {
        _attributed++;
        onDiagnostic('frame_timing_attributed');
      } else {
        _unattributed++;
        onDiagnostic('frame_timing_unmatched');
      }
      final hz = context?.nominalHz;
      final budget = hz == null ? null : 1000000 / hz;
      final build = timing.buildDuration.inMicroseconds;
      final raster = timing.rasterDuration.inMicroseconds;
      final uiOver = budget != null && build > budget;
      final rasterOver = budget != null && raster > budget;
      if (uiOver) {
        _uiOver++;
        onDiagnostic('frame_ui_over_budget');
      }
      if (rasterOver) {
        _rasterOver++;
        onDiagnostic('frame_raster_over_budget');
      }
      if (uiOver || rasterOver) {
        _eitherOver++;
        onDiagnostic('frame_either_over_budget');
      }
      recorder.record(
        'frame_build_us',
        build,
        scene: scene,
        nominalHz: hz,
        budgetUs: budget,
      );
      recorder.record(
        'frame_raster_us',
        raster,
        scene: scene,
        nominalHz: hz,
        budgetUs: budget,
      );
      // Pipeline span is neither build+raster nor a dropped-frame measure.
      recorder.record(
        'frame_total_span_us',
        timing.totalSpan.inMicroseconds,
        scene: scene,
        nominalHz: hz,
      );
    }
  }
}

extension on Stopwatch {
  int elapsedMicrosecondsGetter() => elapsedMicroseconds;
}

/// One passive persistent trampoline per binding; it never retains a session
/// after detach. No transient callback, timer, or new frame is scheduled.
class _FrameBroker {
  static final instance = _FrameBroker();
  final _registeredBindings = Expando<bool>();
  FrameTracker? _active;
  WidgetsBinding? _binding;
  bool _changedDuringBeginFrame = false;
  int? _ambiguousFrameNumber;
  int? _drawCompletedFrameNumber;

  void attach(FrameTracker tracker, WidgetsBinding binding) {
    if (identical(_active, tracker)) return;
    if (_active != null) {
      throw StateError('Only one frame collector may be active');
    }
    _binding = binding;
    _active = tracker;
    _changedDuringBeginFrame = false;
    _ambiguousFrameNumber = null;
    binding.addTimingsCallback(_timings);
    if (_registeredBindings[binding] != true) {
      _registeredBindings[binding] = true;
      // 2026-10-23: a rescheduled transient callback blocks flutter_driver's
      // frameSync and Priority.idle even with scheduleNewFrame:false. Rendering
      // has already registered drawFrame, so this observer runs after drawing.
      binding.addPersistentFrameCallback(_persistent);
    }
    // Attaching part way through a frame cannot establish its starting scene.
    sceneChanged(tracker);
  }

  void detach(FrameTracker tracker) {
    if (!identical(_active, tracker)) return;
    final binding = _binding!;
    binding.removeTimingsCallback(_timings);
    _changedDuringBeginFrame = false;
    _ambiguousFrameNumber = null;
    _active = null;
  }

  void sceneChanged(FrameTracker tracker) {
    if (!identical(_active, tracker)) return;
    final binding = _binding!;
    switch (binding.schedulerPhase) {
      case SchedulerPhase.transientCallbacks:
        // The engine publishes the new FrameData after onBeginFrame returns.
        _changedDuringBeginFrame = true;
      case SchedulerPhase.midFrameMicrotasks:
        _ambiguousFrameNumber = tracker.currentFrameNumber;
      case SchedulerPhase.persistentCallbacks:
        final frameNumber = tracker.currentFrameNumber;
        if (_drawCompletedFrameNumber != frameNumber) {
          _ambiguousFrameNumber = frameNumber;
        }
      case SchedulerPhase.postFrameCallbacks:
      case SchedulerPhase.idle:
        // Drawing is complete. This scene starts with the next host frame.
        break;
    }
  }

  void _persistent(Duration _) {
    final binding = _binding;
    if (binding == null) return;
    final dispatcher = binding.platformDispatcher;
    final active = _active;
    final frameNumber =
        active?.currentFrameNumber ?? dispatcher.frameData.frameNumber;
    _drawCompletedFrameNumber = frameNumber;
    if (active == null) return;
    final ambiguous =
        _changedDuringBeginFrame || _ambiguousFrameNumber == frameNumber;
    _changedDuringBeginFrame = false;
    _ambiguousFrameNumber = null;
    try {
      final scene = active.currentScene();
      final views = dispatcher.views.toList(growable: false);
      active.captureContext(
        frameNumber: frameNumber,
        beforeDraw: scene,
        afterDrawRevision: scene.revision,
        sceneChangedDuringFrame: ambiguous,
        viewCount: views.length,
        nominalHz: views.length == 1 ? views.single.display.refreshRate : null,
      );
    } catch (_) {
      active.onDiagnostic('frame_capture_error');
    }
  }

  void _timings(List<FrameTiming> timings) {
    final active = _active;
    if (active == null) return;
    try {
      active.recordTimings(timings);
    } catch (_) {
      active.onDiagnostic('collection_callback_error');
    }
  }
}
