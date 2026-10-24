import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Fixed local failure categories, never platform exception text or codes.
enum NativeCpuFailureKind { timeout, platform, unexpected }

/// The latest failed CPU request's local diagnostic snapshot.
///
/// [elapsed] measures the caller's whole wait, including channel scheduling. It
/// is not native CPU execution time. This snapshot is never added to telemetry.
final class NativeCpuFailure {
  const NativeCpuFailure(this.kind, this.elapsed);

  final NativeCpuFailureKind kind;
  final Duration elapsed;
}

/// One process-wide resource observation. A missing value is not a zero sample.
///
/// These readings describe the entire process, not a page's exclusive resource
/// use. No native cumulative counter or system-uptime value is exposed here.
class NativeResourceSample {
  NativeResourceSample({
    this.cpuCoresUsed,
    this.rssBytes,
    List<String> diagnostics = const <String>[],
  }) : diagnostics = List<String>.unmodifiable(diagnostics);

  /// Average process CPU cores used between two foreground observations.
  ///
  /// One fully busy core is 1.0. Multiple busy cores can produce values above 1.0.
  /// This is neither a percentage of all cores nor a current-thread measurement.
  final double? cpuCoresUsed;

  /// Current process resident set size from Dart's [ProcessInfo.currentRss].
  ///
  /// This is not Dart heap usage, Apple physical footprint, or page-exclusive
  /// memory. It is sampled independently of the native CPU method channel.
  final int? rssBytes;

  /// Fixed reason codes only; platform error messages are never retained.
  final List<String> diagnostics;
}

/// Optional, low-frequency resource sampling for Android, iOS and macOS.
///
/// This class creates no timers or lifecycle hooks. The owner must sample only
/// while foregrounded, and call [reset] when pausing, resuming or disposing.
/// Unsupported platforms still provide RSS when Dart supports it. Channel,
/// decoding and RSS failures become missing readings with fixed diagnostics.
class NativeResourceProvider {
  NativeResourceProvider({
    MethodChannel? channel,
    int Function()? rssReader,
    bool? supportsNativeCpu,
    Duration sampleTimeout = const Duration(seconds: 1),
  }) : _channel = channel ?? const MethodChannel(channelName),
       _rssReader = rssReader ?? _readCurrentRss,
       _supportsNativeCpu =
           supportsNativeCpu ??
           (Platform.isAndroid || Platform.isIOS || Platform.isMacOS),
       _sampleTimeout = sampleTimeout {
    if (sampleTimeout <= Duration.zero) {
      throw ArgumentError.value(sampleTimeout, 'sampleTimeout', 'must be > 0');
    }
  }

  static const String channelName =
      'dev.carguo.flutter_performance_monitor/resources';

  final MethodChannel _channel;
  final int Function() _rssReader;
  final bool _supportsNativeCpu;
  final Duration _sampleTimeout;
  _CpuCounters? _previous;
  bool _sampling = false;
  bool _nativeCallPending = false;
  bool _missingPlugin = false;
  bool _unsupportedReported = false;
  int _generation = 0;
  NativeCpuFailure? _lastCpuFailure;

  /// One bounded snapshot retained across successful requests and [reset].
  ///
  /// 2026-10-23: preserve whether a failure was the existing deadline or a native
  /// exception, so startup sampling failures can be investigated without logging
  /// private messages, adding event fields, or relaxing the request deadline.
  NativeCpuFailure? get lastCpuFailure => _lastCpuFailure;

  static int _readCurrentRss() => ProcessInfo.currentRss;

  /// Discard the CPU baseline, including any pending observation's result.
  ///
  /// A fresh pair of observations is required after this call so background
  /// time is never silently included in the next foreground CPU interval.
  void reset() {
    _generation++;
    _previous = null;
  }

  Future<NativeResourceSample> sample() async {
    final diagnostics = <String>[];
    int? rssBytes;
    try {
      final rss = _rssReader();
      if (rss > 0) {
        rssBytes = rss;
      } else {
        diagnostics.add('resource_rss_invalid');
      }
    } catch (_) {
      diagnostics.add('resource_rss_error');
    }

    NativeResourceSample result([double? cores]) => NativeResourceSample(
      cpuCoresUsed: cores,
      rssBytes: rssBytes,
      diagnostics: diagnostics,
    );

    if (!_supportsNativeCpu || _missingPlugin) {
      _reportUnsupported(diagnostics);
      return result();
    }
    if (_sampling || _nativeCallPending) {
      diagnostics.add('resource_sample_in_flight');
      return result();
    }

    _sampling = true;
    final generation = _generation;
    final wait = Stopwatch()..start();
    try {
      final raw = await _sampleNative().timeout(_sampleTimeout);
      if (generation != _generation) return result();

      final current = _CpuCounters.tryParse(raw);
      if (current == null) {
        _previous = null;
        diagnostics.add('resource_cpu_invalid');
        return result();
      }
      final previous = _previous;
      _previous = current;
      if (previous == null) return result();

      final elapsedUs = current.monotonicUs - previous.monotonicUs;
      final cpuUs = current.cpuTimeUs - previous.cpuTimeUs;
      if (elapsedUs <= 0 || cpuUs < 0) {
        diagnostics.add('resource_cpu_invalid');
        return result();
      }
      final cores = cpuUs / elapsedUs;
      if (!cores.isFinite || cores < 0) {
        diagnostics.add('resource_cpu_invalid');
        return result();
      }
      return result(cores);
    } on MissingPluginException {
      if (generation == _generation) {
        _previous = null;
        _missingPlugin = true;
        _reportUnsupported(diagnostics);
      }
      return result();
    } catch (error) {
      if (generation == _generation) {
        _previous = null;
        _lastCpuFailure = NativeCpuFailure(
          error is TimeoutException
              ? NativeCpuFailureKind.timeout
              : error is PlatformException
              ? NativeCpuFailureKind.platform
              : NativeCpuFailureKind.unexpected,
          wait.elapsed,
        );
        diagnostics.add('resource_cpu_error');
      }
      return result();
    } finally {
      wait.stop();
      _sampling = false;
    }
  }

  void _reportUnsupported(List<String> diagnostics) {
    // 2026-10-23: unsupported CPU is a capability state, not a new failure on
    // every resource tick. Foreground baseline resets do not change capability.
    if (_unsupportedReported) return;
    _unsupportedReported = true;
    diagnostics.add('resource_cpu_unsupported');
  }

  Future<Object?> _sampleNative() async {
    _nativeCallPending = true;
    try {
      return await _channel.invokeMethod<Object?>('sample');
    } finally {
      // Future.timeout bounds the caller's wait, not the native request. Keep
      // this guard until the underlying request actually settles, even across
      // reset(). The awaited wrapper propagates errors to timeout's listener,
      // which also consumes late errors; there is no detached cleanup Future.
      _nativeCallPending = false;
    }
  }
}

class _CpuCounters {
  const _CpuCounters(this.cpuTimeUs, this.monotonicUs);

  final int cpuTimeUs;
  final int monotonicUs;

  static _CpuCounters? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final cpu = raw['cpu_time_us'];
    final monotonic = raw['monotonic_us'];
    if (cpu is! int || monotonic is! int || cpu < 0 || monotonic < 0) {
      return null;
    }
    return _CpuCounters(cpu, monotonic);
  }
}
