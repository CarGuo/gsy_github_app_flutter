import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_responsive.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';

/// [GSYPullLoadWidget] wrapListChild 契约锁。
///
/// 意图：Discussion / Trend / Notify / Dynamic / Search 等大量列表页都通过
/// [GSYPullLoadWidget] 共享 pull-refresh + load-more 栈。之前只有 nested 版
/// ([GSYNestedPullLoadWidget]) 有契约锁，本文件补齐非嵌套版的等价保护，
/// 确保未来重构不会把 `_getItem` 里的 [GSYAdaptiveNavigation.wrapListChild]
/// 悄悄拆掉，导致所有共享通路的 tab 在 medium / expanded 上文列表 item 都
/// 一路拉满宽度。
///
/// - compact：identical 返回 child（原样透传）
/// - medium / expanded：包 [ConstrainedBox] maxWidth==cardMaxWidth
/// - 空态 / progressIndicator 不套（与文档写死一致）
///
/// P1-4 Discussion tab 的自适应契约通过"Discussion tab 使用 GSYPullLoadWidget"
/// + "GSYPullLoadWidget wraps items with wrapListChild"两条锁共同证明。
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
          body: GSYPullLoadWidget(
            control,
            itemBuilder,
            () async {},
            () async {},
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

  group('GSYPullLoadWidget wrapListChild 契约（覆盖 Discussion/Trend/Notify 等通路）',
      () {
    testWidgets('compact 400 宽 → item 出口不额外包装（原样透传）', (tester) async {
      const marker = Key('pull-item-marker-compact');
      final control = GSYPullLoadWidgetControl()..dataList = [1];

      await tester.pumpWidget(mount(
        size: const Size(400, 800),
        control: control,
        itemBuilder: (_, index) => Container(key: marker, height: 48),
      ));
      await tester.pump();

      expect(find.byKey(marker), findsOneWidget);
      expect(findCardConstraint(tester, marker), isNull,
          reason: 'compact 断点不允许套 cardMaxWidth 约束');
    });

    testWidgets('medium 720 宽 → item 外层出现 maxWidth==cardMaxWidth 约束',
        (tester) async {
      const marker = Key('pull-item-marker-medium');
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
      const marker = Key('pull-item-marker-expanded');
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

      // 契约：expanded 下 wrapListChild 会包一层 Align(topCenter)。
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
      final control = GSYPullLoadWidgetControl()..dataList = [];

      await tester.pumpWidget(mount(
        size: const Size(720, 1024),
        control: control,
        itemBuilder: (_, index) => const SizedBox.shrink(),
      ));
      await tester.pump();

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
