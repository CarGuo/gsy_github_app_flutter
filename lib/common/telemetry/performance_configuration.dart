import 'package:flutter/foundation.dart';
import 'package:flutter_performance_monitor/flutter_performance_monitor.dart';

/// Deployment policy for the optional, independently authenticated exporter.
final class GsyPerformanceConfiguration {
  new _(
    this._ingestToken, {
    required this.endpoint,
    required this.allowInsecureLoopback,
  });

  static GsyPerformanceConfiguration? fromEnvironment() => resolve(
    endpoint: const String.fromEnvironment('MONITOR_ENDPOINT'),
    ingestToken: () => const String.fromEnvironment('MONITOR_INGEST_TOKEN'),
    allowInsecureLoopback: const bool.fromEnvironment(
      'MONITOR_ALLOW_INSECURE_LOOPBACK',
    ),
    releaseMode: kReleaseMode,
  );

  /// 2026-10-23: fail activation for incomplete production configuration before
  /// opening platform channels or an outbox. This credential is exclusively for
  /// telemetry ingestion; never connect this source to GitHub's login storage.
  static GsyPerformanceConfiguration? resolve({
    required String endpoint,
    required String Function() ingestToken,
    bool allowInsecureLoopback = false,
    required bool releaseMode,
  }) {
    if (endpoint.isEmpty) return null;
    if (releaseMode && allowInsecureLoopback) {
      throw const FormatException(
        'Release telemetry cannot enable insecure loopback',
      );
    }
    final Uri parsedEndpoint;
    try {
      parsedEndpoint = Uri.parse(endpoint);
    } catch (_) {
      // URI parser errors may contain the original input, including credentials.
      throw const FormatException('Invalid performance telemetry endpoint');
    }
    final configuration = GsyPerformanceConfiguration._(
      ingestToken,
      endpoint: parsedEndpoint,
      allowInsecureLoopback: allowInsecureLoopback,
    );
    configuration.readAuthorization();
    // Endpoint syntax, allowed hosts and OTLP path remain owned by the SDK's
    // MonitorConfig validation; this layer adds only deployment auth policy.
    return configuration;
  }

  final Uri endpoint;
  final bool allowInsecureLoopback;
  final String Function() _ingestToken;
  // RFC 6750 section 2.1 b64token; limit includes the "Bearer " prefix.
  static final _bearerToken = RegExp(r'^[a-zA-Z0-9\-._~+/]+=*$');

  /// Evaluated for every export attempt so a future short-lived credential
  /// provider can rotate without copying credentials into persisted batches.
  String? readAuthorization() {
    final token = _ingestToken();
    if (endpoint.scheme != 'https') {
      if (token.isNotEmpty) {
        throw const FormatException('Telemetry credentials require HTTPS');
      }
      return null;
    }
    if (token.isEmpty ||
        token.length > 8185 ||
        _bearerToken.matchAsPrefix(token)?.end != token.length) {
      throw const FormatException(
        'HTTPS telemetry requires a valid ingest credential',
      );
    }
    return 'Bearer $token';
  }

  HttpOtlpTransport createTransport() =>
      HttpOtlpTransport(authorization: readAuthorization);
}
