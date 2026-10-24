import Darwin
import Dispatch
import Foundation
import FlutterMacOS

/// Process-wide counters only. Flutter derives interval CPU cores used.
public class FlutterPerformanceMonitorPlugin: NSObject, FlutterPlugin {
  // 2026-10-23: Flutter's macOS messenger does not implement background task
  // queues. Dispatch process-only sampling to one serial worker explicitly.
  private let samplingQueue = DispatchQueue(
    label: "dev.carguo.flutter_performance_monitor.resources"
  )

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "dev.carguo.flutter_performance_monitor/resources",
      binaryMessenger: registrar.messenger
    )
    let instance = FlutterPerformanceMonitorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "sample" else {
      result(FlutterMethodNotImplemented)
      return
    }

    // FlutterResult is documented as callable from any thread. The worker
    // retains this one request until reply; no AppKit or engine state is read.
    samplingQueue.async {
      Self.sample(result: result)
    }
  }

  private static func sample(result: @escaping FlutterResult) {
    var usage = rusage()
    guard getrusage(RUSAGE_SELF, &usage) == 0 else {
      result(FlutterError(code: "resource_cpu_error", message: "CPU counters unavailable", details: nil))
      return
    }

    // getrusage(RUSAGE_SELF) includes process user + system CPU time.
    // timeval is seconds + microseconds; it is not milliseconds or wall time.
    guard let userUs = Self.microseconds(usage.ru_utime),
          let systemUs = Self.microseconds(usage.ru_stime) else {
      result(FlutterError(code: "resource_cpu_invalid", message: "CPU counters unavailable", details: nil))
      return
    }
    let (cpuUs, overflow) = userUs.addingReportingOverflow(systemUs)
    let uptimeUs = ProcessInfo.processInfo.systemUptime * 1_000_000
    guard !overflow, uptimeUs.isFinite, uptimeUs >= 0, uptimeUs < Double(Int64.max) else {
      result(FlutterError(code: "resource_cpu_invalid", message: "CPU counters unavailable", details: nil))
      return
    }

    // These cumulative readings remain in the Dart provider. Only the derived
    // interval CPU metric is recorded; raw system uptime is never exported.
    result(["cpu_time_us": cpuUs, "monotonic_us": Int64(uptimeUs)])
  }

  private static func microseconds(_ value: timeval) -> Int64? {
    guard value.tv_sec >= 0, value.tv_usec >= 0, value.tv_usec < 1_000_000 else {
      return nil
    }
    let (secondsUs, multipliedOverflow) = Int64(value.tv_sec).multipliedReportingOverflow(by: 1_000_000)
    let (totalUs, addedOverflow) = secondsUs.addingReportingOverflow(Int64(value.tv_usec))
    return multipliedOverflow || addedOverflow ? nil : totalUs
  }
}
