import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/material.dart';

/// 响应式布局断点（对齐 Material 3 Window Size Classes）。
///
/// - compact  = `[0, 600)`
/// - medium   = `[600, 840)`
/// - expanded = `[840, ∞)`
///
/// 手机横屏（宽 ≥ 600 但高 < 500）视为"窄条"，仍走 compact 骨架，
/// 不做 Master-Detail（高度不足以看 detail）。
class GSYBreakpoints {
  const new _();

  static const double compactMax = 600;
  static const double mediumMax = 840;

  static const double narrowHeightLimit = 500;

  static const double cardMaxWidth = 720;

  static const double railWidth = 96;
  static const double railExtendedWidth = 240;

  static const double masterMinWidth = 320;
  static const double masterMaxRatio = 0.42;
}

enum GSYWindowSize { compact, medium, expanded }

GSYWindowSize gsyWindowSizeFromWidth(double width) {
  if (width < GSYBreakpoints.compactMax) return GSYWindowSize.compact;
  if (width < GSYBreakpoints.mediumMax) return GSYWindowSize.medium;
  return GSYWindowSize.expanded;
}

extension GSYResponsiveContext on BuildContext {
  GSYWindowSize get windowSize =>
      gsyWindowSizeFromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompactWindow => windowSize == GSYWindowSize.compact;
  bool get isMediumWindow => windowSize == GSYWindowSize.medium;
  bool get isExpandedWindow => windowSize == GSYWindowSize.expanded;

  bool get isNarrowHeight =>
      MediaQuery.sizeOf(this).height < GSYBreakpoints.narrowHeightLimit;

  bool get canShowTwoPane =>
      windowSize == GSYWindowSize.expanded && !isNarrowHeight;

  DisplayFeature? get verticalHinge {
    for (final feature in MediaQuery.displayFeaturesOf(this)) {
      final isFoldOrHinge = feature.type == DisplayFeatureType.fold ||
          feature.type == DisplayFeatureType.hinge;
      if (!isFoldOrHinge) continue;
      final isVertical = feature.bounds.width < feature.bounds.height;
      if (!isVertical) continue;
      return feature;
    }
    return null;
  }
}
