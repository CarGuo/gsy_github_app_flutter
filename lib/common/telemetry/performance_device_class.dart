import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 2026-10-23: version trends must compare hardware cohorts separately, including
/// simulator vs physical devices. Only OS model data is accepted, never names or
/// per-device identifiers; canonical labels meet the SDK's 64-character boundary.
/// Hash the complete model so non-ASCII names and truncated suffixes remain
/// distinct. The readable portion is descriptive, never the cohort identity.
String performanceDeviceClass({
  required String model,
  required bool isPhysicalDevice,
}) {
  final canonical = model
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  final digest = sha256.convert(utf8.encode(model)).toString().substring(0, 32);
  final prefix = isPhysicalDevice ? 'physical-' : 'simulator-';
  if (canonical.isEmpty) return '$prefix$digest';
  final maxModelLength = 64 - prefix.length - digest.length - 1;
  final readable = canonical.length > maxModelLength
      ? canonical.substring(0, maxModelLength)
      : canonical;
  return '$prefix$readable-$digest';
}
