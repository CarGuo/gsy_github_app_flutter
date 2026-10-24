import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'otlp.dart';

// Internal messages contain only frozen text, primitive metadata and bytes.
// No queue, file handle, transport, callback or owning outbox crosses isolates.
typedef OutboxEventData = ({
  String appId,
  String eventId,
  String encoded,
  int windowEndMs,
});
typedef OutboxPayload = ({Uint8List bytes, int records});
typedef OutboxPackedEvents = ({List<OutboxPayload> batches, int oversized});
typedef OutboxEnvelopeData = ({
  String id,
  int createdMs,
  int attempts,
  int notBeforeMs,
  int records,
  String destination,
  Uint8List bytes,
});
typedef OutboxDecodedEnvelope = ({
  OutboxEnvelopeData? envelope,
  String? reason,
});

// The closures are deliberately created in top-level functions whose only
// inputs are the codec messages. Calling Isolate.run inside an outbox method
// could accidentally capture its owner and unsendable resources. The outbox
// awaits each call within its existing serial writer (or sequential recovery),
// so there is at most one codec task per outbox, with no second work queue.
Future<OutboxPackedEvents> packOutboxEvents(
  List<OutboxEventData> events,
  int maxBatchBytes,
) => Isolate.run(() => _packEvents(events, maxBatchBytes));

Future<Uint8List> encodeOutboxEnvelope(OutboxEnvelopeData data) =>
    Isolate.run(() => _encodeEnvelope(data));

Future<OutboxDecodedEnvelope> decodeOutboxEnvelope(
  Uint8List bytes,
  String id,
  String destination,
  int maxBatchBytes,
) => Isolate.run(() => _decodeEnvelope(bytes, id, destination, maxBatchBytes));

OutboxPackedEvents _packEvents(
  List<OutboxEventData> events,
  int maxBatchBytes,
) {
  final batches = <OutboxPayload>[];
  final builder = OtlpBatchBuilder();
  var oversized = 0;
  void finish() {
    if (builder.isEmpty) return;
    final records = builder.recordCount;
    batches.add((
      bytes: builder.takeBytes().asUnmodifiableView(),
      records: records,
    ));
  }

  for (final event in events) {
    final record = encodeOtlpLogRecordFields(
      encodedEvent: event.encoded,
      eventId: event.eventId,
      windowEndMs: event.windowEndMs,
    );
    if (!builder.tryAdd(event.appId, record, maxBytes: maxBatchBytes)) {
      finish();
      if (!builder.tryAdd(event.appId, record, maxBytes: maxBatchBytes)) {
        oversized++;
      }
    }
  }
  finish();
  return (batches: batches, oversized: oversized);
}

Uint8List _encodeEnvelope(OutboxEnvelopeData batch) {
  // The version-1 insertion order and checksum input are deliberately stable:
  // existing durable files and retry request bytes require no migration.
  final data = <String, Object?>{
    'version': 1,
    'id': batch.id,
    'created_ms': batch.createdMs,
    'attempts': batch.attempts,
    'not_before_ms': batch.notBeforeMs,
    'records': batch.records,
    'destination': _checksum(utf8.encode(batch.destination)),
    'checksum': _checksum(batch.bytes),
    'payload': base64Encode(batch.bytes),
  };
  data['state_checksum'] = _checksum(utf8.encode(jsonEncode(data)));
  return Uint8List.fromList(utf8.encode(jsonEncode(data)));
}

OutboxDecodedEnvelope _decodeEnvelope(
  Uint8List encoded,
  String id,
  String destination,
  int maxBatchBytes,
) {
  try {
    final data = jsonDecode(utf8.decode(encoded));
    if (data is! Map<String, dynamic>) {
      return (envelope: null, reason: 'corrupt_batch');
    }
    if (data['version'] != 1) {
      return (envelope: null, reason: 'unsupported_batch');
    }
    if (data['state_checksum'] !=
        _checksum(
          utf8.encode(
            jsonEncode(Map<String, dynamic>.of(data)..remove('state_checksum')),
          ),
        )) {
      return (envelope: null, reason: 'corrupt_batch');
    }
    if (data['destination'] != _checksum(utf8.encode(destination))) {
      return (envelope: null, reason: 'endpoint_changed');
    }
    final bytes = base64Decode(data['payload'] as String);
    final created = data['created_ms'];
    final attempts = data['attempts'];
    final notBefore = data['not_before_ms'];
    final records = data['records'];
    if (data['id'] != id ||
        bytes.isEmpty ||
        bytes.length > maxBatchBytes ||
        data['checksum'] != _checksum(bytes) ||
        created is! int ||
        created < 0 ||
        attempts is! int ||
        attempts < 0 ||
        notBefore is! int ||
        notBefore < 0 ||
        records is! int ||
        records <= 0 ||
        records > maxBatchBytes) {
      return (envelope: null, reason: 'corrupt_batch');
    }
    // Validate the standard envelope without rebuilding its request bytes.
    final payload = jsonDecode(utf8.decode(bytes));
    if (payload is! Map<String, dynamic> || payload['resourceLogs'] is! List) {
      return (envelope: null, reason: 'corrupt_batch');
    }
    return (
      envelope: (
        id: id,
        createdMs: created,
        attempts: attempts,
        notBeforeMs: notBefore,
        records: records,
        destination: destination,
        bytes: bytes.asUnmodifiableView(),
      ),
      reason: null,
    );
  } catch (_) {
    // Malformed input is data loss with a visible reason. Isolate startup or
    // transfer failures occur outside this parser and propagate to the owner's
    // existing unavailable/disk-error path, preserving a valid spool file.
    return (envelope: null, reason: 'corrupt_batch');
  }
}

// CRC-32 detects accidental corruption, not malicious tampering/authenticity.
final List<int> _crcTable = List<int>.generate(256, (value) {
  var crc = value;
  for (var bit = 0; bit < 8; bit++) {
    crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
  }
  return crc;
}, growable: false);

int _checksum(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc = (crc >> 8) ^ _crcTable[(crc ^ byte) & 0xff];
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
