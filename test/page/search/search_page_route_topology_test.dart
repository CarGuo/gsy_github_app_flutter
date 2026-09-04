import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/page/search/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SearchPage 分档适配契约（[docs/01-architecture/route-topology.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md) §3.1 分档 1）：
///
/// - compact 保留 [CRAnimation] 弧形入场（`ClipPath + AnimationClipper`）；
/// - medium / expanded **不得**再包 CRAnimation，改由 CupertinoPageRoute 兜底
///   转场，避免 `minR = MediaQuery.height - 8` 在宽屏对角线 > height 时露出弧外底色。
///
/// 该契约是本次修复的核心视觉证据，若被静默回退（例如未来有人把 CRAnimation 又
/// 包回外层），本 case 会立刻失败提示。
void main() {
  setUp(() {
    // SearchPage.initState 内 _loadHistory 触发 SharedPreferences.getInstance()，
    // 单测无 platform channel 会抛 MissingPluginException 中断 pump。
    SharedPreferences.setMockInitialValues(const {});
  });

  tearDown(() {
    GSYAdaptiveNavigation.instance.resetDelegateForTest();
  });

  Widget mount(Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchPage(const Offset(200, 200)),
      ),
    );
  }

  testWidgets('compact 窗口（宽 400）→ CRAnimation 存在（保留弧形入场）',
      (tester) async {
    await tester.pumpWidget(mount(const Size(400, 800)));
    // SearchPage.initState 里挂了 Future.delayed(Duration.zero) → controller.forward，
    // 需要 pumpAndSettle 把这条 300ms 动画链和其后 setState(endAnima=true) 都跑完，
    // 否则测试结束时 fake_async 仍有挂起的 Timer，binding._verifyInvariants
    // 断言 `!timersPending` 会失败。
    await tester.pumpAndSettle();

    expect(find.byType(CRAnimation), findsOneWidget,
        reason:
            'compact 分档必须保留弧形入场动画，否则移动端搜索体感回退');
  });

  testWidgets(
      'medium 窗口（宽 720）→ CRAnimation 不再包裹 Scaffold，'
      '避免弧形 clip 在宽屏对角线 > height 时露底色',
      (tester) async {
    await tester.pumpWidget(mount(const Size(720, 1024)));
    await tester.pumpAndSettle();

    expect(find.byType(CRAnimation), findsNothing,
        reason:
            'route-topology.md §3.1 分档 1：medium 起弱化为 Fade，'
            '禁止再走 CRAnimation.ClipPath 遮挡弧外底色');
    expect(find.byType(Scaffold), findsOneWidget,
        reason: '弱化后仍必须渲染 Scaffold 骨架');
  });

  testWidgets(
      'expanded 窗口（宽 1600）→ CRAnimation 不再包裹 Scaffold',
      (tester) async {
    await tester.pumpWidget(mount(const Size(1600, 1000)));
    await tester.pumpAndSettle();

    expect(find.byType(CRAnimation), findsNothing,
        reason:
            'expanded 大屏对角线远超 height，若继续用 CRAnimation.minR=height-8 '
            '会露出弧外底色（真机截图显示的那道弧），必须弱化');
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
