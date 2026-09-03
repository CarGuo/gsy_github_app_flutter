import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_responsive.dart';

/// [gsyWindowSizeFromWidth] 边界断言：这些数值构成后续 AdaptiveScaffold /
/// GSYTwoPane 分支判定的基石，任何策略调整都必须先在这里改测试。
void main() {
  group('gsyWindowSizeFromWidth 边界', () {
    test('599 → compact', () {
      expect(gsyWindowSizeFromWidth(599), GSYWindowSize.compact);
    });

    test('600 → medium', () {
      expect(gsyWindowSizeFromWidth(600), GSYWindowSize.medium);
    });

    test('839 → medium', () {
      expect(gsyWindowSizeFromWidth(839), GSYWindowSize.medium);
    });

    test('840 → expanded', () {
      expect(gsyWindowSizeFromWidth(840), GSYWindowSize.expanded);
    });

    test('0 → compact（防御下界）', () {
      expect(gsyWindowSizeFromWidth(0), GSYWindowSize.compact);
    });
  });

  Widget harness({
    required Size size,
    List<DisplayFeature> features = const [],
    required void Function(BuildContext ctx) probe,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, displayFeatures: features),
      child: MaterialApp(
        home: Builder(builder: (ctx) {
          probe(ctx);
          return const Scaffold(body: SizedBox.shrink());
        }),
      ),
    );
  }

  group('GSYResponsiveContext', () {
    testWidgets('compact 窗口：所有布尔字段与枚举一致', (tester) async {
      late GSYWindowSize size;
      late bool compact;
      late bool medium;
      late bool expanded;
      late bool narrow;
      late bool canTwoPane;
      await tester.pumpWidget(harness(
        size: const Size(400, 800),
        probe: (ctx) {
          size = ctx.windowSize;
          compact = ctx.isCompactWindow;
          medium = ctx.isMediumWindow;
          expanded = ctx.isExpandedWindow;
          narrow = ctx.isNarrowHeight;
          canTwoPane = ctx.canShowTwoPane;
        },
      ));
      expect(size, GSYWindowSize.compact);
      expect(compact, true);
      expect(medium, false);
      expect(expanded, false);
      expect(narrow, false);
      expect(canTwoPane, false);
    });

    testWidgets('expanded + 足够高 → canShowTwoPane=true', (tester) async {
      late bool canTwoPane;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          canTwoPane = ctx.canShowTwoPane;
        },
      ));
      expect(canTwoPane, true);
    });

    testWidgets('expanded + 手机横屏窄条 → canShowTwoPane=false（不上双栏）',
        (tester) async {
      late GSYWindowSize size;
      late bool canTwoPane;
      late bool narrow;
      await tester.pumpWidget(harness(
        size: const Size(1000, 400),
        probe: (ctx) {
          size = ctx.windowSize;
          canTwoPane = ctx.canShowTwoPane;
          narrow = ctx.isNarrowHeight;
        },
      ));
      expect(size, GSYWindowSize.expanded);
      expect(narrow, true);
      expect(canTwoPane, false);
    });

    testWidgets('verticalHinge：识别 vertical hinge', (tester) async {
      DisplayFeature? hinge;
      const feature = DisplayFeature(
        bounds: Rect.fromLTWH(600, 0, 20, 1200),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );
      await tester.pumpWidget(harness(
        size: const Size(1220, 1200),
        features: const [feature],
        probe: (ctx) {
          hinge = ctx.verticalHinge;
        },
      ));
      expect(hinge, isNotNull);
      expect(hinge!.type, DisplayFeatureType.hinge);
      expect(hinge!.bounds.left, 600);
    });

    testWidgets('verticalHinge：horizontal fold 不算', (tester) async {
      DisplayFeature? hinge;
      const feature = DisplayFeature(
        bounds: Rect.fromLTWH(0, 600, 1200, 20),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      );
      await tester.pumpWidget(harness(
        size: const Size(1200, 1220),
        features: const [feature],
        probe: (ctx) {
          hinge = ctx.verticalHinge;
        },
      ));
      expect(hinge, isNull);
    });
  });
}
