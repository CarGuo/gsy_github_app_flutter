package dev.carguo.flutter_performance_monitor;

import android.os.Process;
import android.os.SystemClock;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import java.util.HashMap;
import java.util.Map;

/** Process-wide cumulative CPU and monotonic counters; no Activity hooks. */
public final class FlutterPerformanceMonitorPlugin
    implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private MethodChannel channel;

  interface CounterReader {
    long read();
  }

  private final CounterReader cpuTimeMillis;
  private final CounterReader monotonicMillis;

  public FlutterPerformanceMonitorPlugin() {
    this(Process::getElapsedCpuTime, SystemClock::elapsedRealtime);
  }

  // Injectable readers keep conversion and failure tests independent of Android's runtime.
  FlutterPerformanceMonitorPlugin(CounterReader cpuTimeMillis, CounterReader monotonicMillis) {
    this.cpuTimeMillis = cpuTimeMillis;
    this.monotonicMillis = monotonicMillis;
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    // 2026-10-23: process sampling has no UI dependency. Use Flutter's serial
    // background queue so sampling cannot queue behind platform UI work.
    BinaryMessenger messenger = binding.getBinaryMessenger();
    channel = new MethodChannel(
        messenger,
        "dev.carguo.flutter_performance_monitor/resources",
        StandardMethodCodec.INSTANCE,
        messenger.makeBackgroundTaskQueue());
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result result) {
    if (!"sample".equals(call.method)) {
      result.notImplemented();
      return;
    }
    try {
      // Android reports milliseconds. The wire contract is microseconds, retaining
      // millisecond source resolution, rather than claiming microsecond precision.
      long cpuMs = cpuTimeMillis.read();
      long monotonicMs = monotonicMillis.read();
      if (cpuMs < 0 || monotonicMs < 0
          || cpuMs > Long.MAX_VALUE / 1000 || monotonicMs > Long.MAX_VALUE / 1000) {
        result.error("resource_cpu_invalid", "CPU counters unavailable", null);
        return;
      }
      Map<String, Long> counters = new HashMap<>();
      counters.put("cpu_time_us", cpuMs * 1000L);
      counters.put("monotonic_us", monotonicMs * 1000L);
      result.success(counters);
    } catch (RuntimeException ignored) {
      // Never include exception text, process identifiers or device details.
      result.error("resource_cpu_error", "CPU counters unavailable", null);
    }
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
  }
}
