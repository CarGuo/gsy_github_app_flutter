import 'dart:convert';
import 'dart:math';

import 'model.dart';
import 'otlp.dart';
import 'outbox.dart';
import 'recorder.dart';

/// A full configured window can generate work faster than the export budget.
/// This is an upper-bound planning warning, not measured traffic or an SLO.
enum CapacityWarning { exportBytes, exportRequests }

/// Conservative schema/wire upper bounds, evaluated once during configuration.
/// Normal traffic depends on active series, diagnostics and sample values.
final class MonitorCapacityEstimate {
  MonitorCapacityEstimate._({
    required this.maximumWindowEvents,
    required this.maximumEventBytes,
    required this.maximumWindowStagingBytes,
    required this.minimumAtomicQueueBytes,
    required this.maximumWindowWireBytes,
    required this.maximumWindowRequests,
    required Set<CapacityWarning> warnings,
  }) : warnings = Set.unmodifiable(warnings);

  final int maximumWindowEvents;
  final int maximumEventBytes;
  final int maximumWindowStagingBytes;
  final int minimumAtomicQueueBytes;
  final int maximumWindowWireBytes;
  final int maximumWindowRequests;
  final Set<CapacityWarning> warnings;

  static MonitorCapacityEstimate forConfiguration({
    required MonitorIdentity identity,
    required RecorderLimits recorder,
    required OutboxLimits outbox,
    required Duration windowInterval,
  }) {
    // 2026-10-23: derive capacity from the actual schema and OTLP encoder.
    // Do not equate a 4096-series recorder with a queue/exporter sized for 64.
    // All labels are bounded ASCII, so quote escaping adds no unknown growth.
    final common = <String, Object?>{
      'schema_version': 1,
      'event_id': '${'s' * 32}:$maxTelemetryInteger',
      'session_id': 's' * 32,
      'sequence': maxTelemetryInteger,
      'window_start_unix_ms': maxTelemetryTimestampMs,
      'window_end_unix_ms': maxTelemetryTimestampMs,
      ...identity.toJson(),
    };
    // At most 17 significant digits, decimal point, exponent sign and three
    // exponent digits fit in 24 ASCII bytes for any positive finite double.
    const scalarBytes = 24;
    final histogram = jsonEncode({
      ...common,
      'kind': 'histogram',
      'metric': Metrics.flutterInitToFirstRasterObservedUs,
      'scene': 's' * 96,
      'operation': 'o' * 96,
      'nominal_hz': 1000,
      'bounds': Metrics.latencyBounds,
      // Deliberately conservative: not all buckets can simultaneously contain
      // maxTelemetryInteger, but each field must fit without a loss assumption.
      'bucket_counts': List.filled(
        Metrics.latencyBounds.length + 1,
        maxTelemetryInteger,
      ),
      'count': maxTelemetryInteger,
      'sum': maxTelemetryInteger,
      'max': maxTelemetryInteger,
      'over_budget_count': maxTelemetryInteger,
      'budget_us': maxTelemetryInteger,
    });
    final diagnostic = jsonEncode({
      ...common,
      'kind': 'diagnostic',
      'reason': DiagnosticReasons.all.reduce(
        (a, b) => a.length >= b.length ? a : b,
      ),
      'count': maxTelemetryInteger,
    });
    // Five numeric histogram fields can be doubles rather than these shorter
    // integer fixtures. Add the full width, not an assumed observed value.
    final histogramBytes = utf8.encode(histogram).length + 5 * scalarBytes;
    final diagnosticBytes = utf8.encode(diagnostic).length;
    final histogramRecord =
        encodeOtlpLogRecordFields(
          encodedEvent: histogram,
          eventId: common['event_id']! as String,
          windowEndMs: maxTelemetryTimestampMs,
        ).length +
        5 * scalarBytes;
    final diagnosticRecord = encodeOtlpLogRecordFields(
      encodedEvent: diagnostic,
      eventId: common['event_id']! as String,
      windowEndMs: maxTelemetryTimestampMs,
    ).length;
    final builder = OtlpBatchBuilder();
    builder.tryAdd(
      identity.appId,
      utf8.encode('{}'),
      maxBytes: maxTelemetryInteger,
    );
    final envelopeBytes = builder.byteLength - 2;
    final maxRecord = max(histogramRecord, diagnosticRecord);
    if (maxRecord + envelopeBytes > outbox.maxBatchBytes) {
      throw ArgumentError(
        'maxBatchBytes must fit one maximum schema event '
        '(${maxRecord + envelopeBytes} bytes)',
      );
    }
    final diagnosticCount = DiagnosticReasons.all.length;
    final events = recorder.maxSeries + diagnosticCount;
    final staging =
        4 *
        (recorder.maxSeries * histogramBytes +
            diagnosticCount * diagnosticBytes);
    // Disk envelopes base64 the wire bytes. Two copies plus the existing
    // replacement headroom must fit while atomically persisting retry state.
    final diskEnvelopeOverhead = utf8
        .encode(
          jsonEncode({
            'version': 1,
            'id': 'a' * 32,
            'created_ms': maxTelemetryInteger,
            'attempts': maxTelemetryInteger,
            'not_before_ms': maxTelemetryInteger,
            'records': maxTelemetryInteger,
            'destination': 'a' * 8,
            'checksum': 'a' * 8,
            'payload': '',
          }),
        )
        .length;
    final atomicBytes =
        2 * (4 * ((outbox.maxBatchBytes + 2) ~/ 3) + diskEnvelopeOverhead) + 64;
    if (outbox.maxQueueBytes < max(staging, atomicBytes)) {
      throw ArgumentError(
        'maxQueueBytes must fit a full configured window staging '
        '($staging bytes) and atomic maximum batch replacement '
        '($atomicBytes bytes); reduce maxSeries or increase queue capacity',
      );
    }
    final usableBatchBytes = outbox.maxBatchBytes - envelopeBytes;
    final recordsPerBatch = max(1, usableBatchBytes ~/ (maxRecord + 1));
    final requests = (events + recordsPerBatch - 1) ~/ recordsPerBatch;
    final wire =
        recorder.maxSeries * histogramRecord +
        diagnosticCount * diagnosticRecord +
        events +
        requests * envelopeBytes;
    final windowsPerMinute =
        const Duration(minutes: 1).inMicroseconds /
        windowInterval.inMicroseconds;
    return MonitorCapacityEstimate._(
      maximumWindowEvents: events,
      maximumEventBytes: max(histogramBytes, diagnosticBytes),
      maximumWindowStagingBytes: staging,
      minimumAtomicQueueBytes: atomicBytes,
      maximumWindowWireBytes: wire,
      maximumWindowRequests: requests,
      warnings: {
        if (wire * windowsPerMinute > outbox.maxExportBytesPerMinute)
          CapacityWarning.exportBytes,
        if (requests * windowsPerMinute > outbox.maxRequestsPerMinute)
          CapacityWarning.exportRequests,
      },
    );
  }
}
