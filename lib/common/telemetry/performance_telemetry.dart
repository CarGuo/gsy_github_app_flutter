import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_performance_monitor/flutter_performance_monitor.dart';
import 'package:flutter_performance_monitor_dio/flutter_performance_monitor_dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';

import 'performance_configuration.dart';
import 'performance_device_class.dart';
import 'performance_navigation.dart';

/// The application's composition seam for collection, not a business service.
class GsyPerformanceTelemetry {
  new _();
  static final instance = GsyPerformanceTelemetry._();

  PerformanceMonitor? _monitor;
  PerformanceMonitor? get monitor => _monitor;
  late final navigation = GsyPerformanceNavigation(
    onScene: (scene) => _monitor?.setScene(scene),
  );

  /// 2026-10-23: telemetry is optional, but activation failure must remain visible
  /// in both entry points without exposing endpoint/configuration exception text.
  void start() {
    unawaited(
      initialize().catchError((Object error, StackTrace stack) {
        printError(
          'Performance telemetry initialization failed',
          error.runtimeType,
          stack,
        );
      }),
    );
  }

  /// 2026-10-23: deployments must supply their ingress; ordinary builds neither
  /// create a telemetry installation nor send to a developer's local service.
  /// Version cohorts use package metadata and actual build mode, not UI labels.
  /// Entry points start this future without awaiting it: package metadata and
  /// optional telemetry must not become the application's startup barrier.
  /// [start] explicitly reports activation failures. Late activation is reported
  /// by the SDK instead of being mistaken for a complete startup measurement.
  Future<void> initialize() async {
    if (kIsWeb) return;
    final deployment = GsyPerformanceConfiguration.fromEnvironment();
    if (deployment == null) return;
    final (package, deviceClass) = await (
      PackageInfo.fromPlatform(),
      _readDeviceClass(),
    ).wait;
    const runId = String.fromEnvironment('MONITOR_RUN_ID');
    _monitor = await PerformanceMonitor.start(
      MonitorConfig(
        identity: MonitorIdentity(
          appId: package.packageName,
          appVersion: '${package.version}+${package.buildNumber}',
          platform: Platform.operatingSystem,
          buildMode: kReleaseMode
              ? 'release'
              : kProfileMode
              ? 'profile'
              : 'debug',
          deviceClass: deviceClass,
          flutterVersion: const String.fromEnvironment(
            'MONITOR_FLUTTER_VERSION',
            defaultValue: 'unknown',
          ),
          mode: runId.isEmpty ? 'daily' : 'test',
          runId: runId,
        ),
        endpoint: deployment.endpoint,
        scenes: GsyPerformanceNavigation.scenes,
        allowInsecureLoopback: deployment.allowInsecureLoopback,
        // 2026-10-23: the SDK owns a dedicated TLS exporter. Its per-send auth
        // factory cannot reuse or persist the application's GitHub credential.
        transportFactory: deployment.createTransport,
      ),
    );
    navigation.synchronize();
  }

  Future<String> _readDeviceClass() async {
    const override = String.fromEnvironment('MONITOR_DEVICE_CLASS');
    if (override.isNotEmpty) return override;
    final device = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await device.androidInfo;
      return performanceDeviceClass(
        model: info.model,
        isPhysicalDevice: info.isPhysicalDevice,
      );
    }
    if (Platform.isIOS) {
      final info = await device.iosInfo;
      return performanceDeviceClass(
        model: info.utsname.machine,
        isPhysicalDevice: info.isPhysicalDevice,
      );
    }
    return 'unknown';
  }

  HttpClientAdapter wrapDioAdapter(HttpClientAdapter inner) =>
      MonitoredDioAdapter(inner, monitor: () => _monitor);

  /// HttpLink owns this client and closes it when the link is disposed.
  http.Client createHttpClient() => MonitoredHttpClient.withRequestTiming(
    http.Client(),
    startRequest: (method) => _monitor?.startHttpRequest(method),
  );
}
