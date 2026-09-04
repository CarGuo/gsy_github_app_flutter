import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_responsive.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';

/// [GSYNestedPullLoadWidget] wrapListChild 契约锁。
///
/// 意图：Info / Issue 两个 tab 走嵌套滚动 shell，itemBuilder 出口必须与
/// [GSYPullLoadWidget] 收口保持一致，medium / expanded 断点下 item 自动
/// 限宽到 [GSYBreakpoints.cardMaxWidth]（720dp）；compact 不做任何包装。
///
/// 未来若有人把 wrapListChild 从 `_getItem` 拆掉，或改成"仅头/尾包装"，
/// 本文件就会 fail。
void main() {
  tearDown(() {
    GSYAdaptiveNavigation.instance.resetDelegateForTest();
  });

  Widget mount({
    required Size size,
    required GSYPullLoadWidgetControl control,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GSYNestedPullLoadWidget(
            control,
            itemBuilder,
            () async {},
            () async {},
            headerSliverBuilder: (_, __) => const [],
          ),
        ),
      ),
    );
  }

  ConstrainedBox? findCardConstraint(WidgetTester tester, Key marker) {
    final ancestors = find.ancestor(
      of: find.byKey(marker),
      matching: find.byType(ConstrainedBox),
    );
    for (final el in tester.widgetList<ConstrainedBox>(ancestors)) {
      if (el.constraints.maxWidth == GSYBreakpoints.cardMaxWidth) {
        return el;
      }
    }
    return null;
  }

  group('GSYNestedPullLoadWidget wrapListChild 契约（P0-1）', () {
    testWidgets('compact 400 宽 → item 出口不额外包装（原样透传）', (tester) async {
      const marker = Key('nested-item-marker-compact');
      final control = GSYPullLoadWidgetControl()..dataList = [1];

      await tester.pumpWidget(mount(
        size: const Size(400, 800),
        control: control,
        itemBuilder: (_, index) => Container(key: marker, height: 48),
      ));
      await tester.pump();

      // 契约要求：compact 下 wrapListChild identical 返回，因此外围不该
      // 出现 maxWidth == cardMaxWidth 的 ConstrainedBox。
      expect(find.byKey(marker), findsOneWidget);
      expect(findCardConstraint(tester, marker), isNull,
          reason: 'compact 断点不允许套 cardMaxWidth 约束');
    });

    testWidgets('medium 720 宽 → item 外层出现 maxWidth==cardMaxWidth 约束',
        (tester) async {
      const marker = Key('nested-item-marker-medium');
      final control = GSYPullLoadWidgetControl()..dataList = [1];

      await tester.pumpWidget(mount(
        size: const Size(720, 1024),
        control: control,
        itemBuilder: (_, index) => Container(key: marker, height: 48),
      ));
      await tester.pump();

      expect(find.byKey(marker), findsOneWidget);
      expect(findCardConstraint(tester, marker), isNotNull,
          reason: 'medium 断点 item 出口必须套 cardMaxWidth ConstrainedBox');
    });

    testWidgets('expanded 1600 宽 → item 外层出现 maxWidth==cardMaxWidth 约束且水平居中',
        (tester) async {
      const marker = Key('nested-item-marker-expanded');
      final control = GSYPullLoadWidgetControl()..dataList = [1];

      await tester.pumpWidget(mount(
        size: const Size(1600, 1000),
        control: control,
        itemBuilder: (_, index) => Container(key: marker, height: 48),
      ));
      await tester.pump();

      expect(find.byKey(marker), findsOneWidget);
      expect(findCardConstraint(tester, marker), isNotNull,
          reason: 'expanded 断点 item 出口必须套 cardMaxWidth ConstrainedBox');

      // 契约要求：expanded 下 wrapListChild 会包一层 Align(topCenter)。
      final aligns = find.ancestor(
        of: find.byKey(marker),
        matching: find.byWidgetPredicate(
            (w) => w is Align && w.alignment == Alignment.topCenter),
      );
      expect(aligns, findsWidgets,
          reason: 'expanded 断点必须让 item 水平居中');
    });

    testWidgets('空态（dataList=[]） medium 断点：empty widget 不套 cardMaxWidth 约束',
        (tester) async {
      // 契约：空态与 progressIndicator 保持不包，避免"loading 被挤到 720dp
      // 中央后再居中"的错位视觉。用 EMPTY dataList 触发 _buildEmpty 分支。
      final control = GSYPullLoadWidgetControl()..dataList = [];

      await tester.pumpWidget(mount(
        size: const Size(720, 1024),
        control: control,
        itemBuilder: (_, index) => const SizedBox.shrink(),
      ));
      await tester.pump();

      // 空态挂载的是 asset image (DEFAULT_USER_ICON)；断言"没有 cardMaxWidth
      // 的 ConstrainedBox 直接包裹整个 Image / Column"。
      final image = find.byType(Image);
      expect(image, findsOneWidget, reason: '空态应挂载默认用户 icon');

      final ancestors = find.ancestor(
        of: image,
        matching: find.byType(ConstrainedBox),
      );
      for (final el in tester.widgetList<ConstrainedBox>(ancestors)) {
        expect(el.constraints.maxWidth == GSYBreakpoints.cardMaxWidth, false,
            reason: '空态外层不允许套 cardMaxWidth 约束');
      }
    });
  });
}
