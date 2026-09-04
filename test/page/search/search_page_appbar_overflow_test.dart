import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/page/search/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SearchPage AppBar.bottom 溢出归属锁死（reviewer P1-5，2026-09-04）：
///
/// [navigator_utils_search_test.dart canShowTwoPane=true case](file:///d:/workspace/project/gsy_github_app_flutter/test/common/utils/navigator_utils_search_test.dart)
/// 在右列 700dp 观察到 `RenderFlex overflowed by 22 pixels`，用 takeException + 白名单兜住。
/// reviewer 独立上下文追问：**该 overflow 是本轮把 Search 落到右列引入的新回归，
/// 还是 SearchPage 既有的窄栏渲染缺口**？
///
/// 本文件用四档挂载环境把答案证据化——同一 fixture、同一 pump 时序，只换宽度 / 挂载方式：
///   1. compact 全屏 400dp（改造前 `showGeneralDialog` + 改造后 canShowTwoPane=false 起飞宽度）
///   2. medium 全屏 720dp（medium 分档全屏 push）
///   3. expanded 全屏 1200dp（forceFullScreenDetail=true 用户偏好路径）
///   4. 右列 700dp（本轮 canShowTwoPane=true 双栏挂载环境）
///
/// **2026-09-04 实测结论（本 case suite 首次跑出的真实观察）**：
///   - 400dp / 720dp / 1200dp 三档全屏挂载 **不 overflow**；
///   - 只有右列 700dp 才 overflow。
///
/// 归属推断：overflow 与"绝对宽度"无关（否则 400dp 更窄理应更严重）——它与
/// **"SearchPage 被塞进 Row + Expanded/SizedBox 固定宽度子树"的约束传播路径** 有关。
/// 因此**这是本轮把 Search 落到右列（即 ADR-0005 detailNavigator 挂载路径）
/// 才暴露出来的 SearchPage AppBar.bottom 渲染缺口**——SearchPage 在全屏 Scaffold
/// 挂载下从未被这样窄栏 + Row 约束地渲染过。
///
/// 修复责任归属：非本轮路由改造直接引入（`goSearchPage` / `_openDetailOrRouter`
/// 都没改 SearchPage 内部布局），但**本轮首次让 SearchPage 走进右列 Row 挂载
/// 语境**，让原本潜伏的窄栏渲染缺口第一次表现出来。属于"路由拓扑收敛顺带
/// 暴露了 SearchPage UI 的既存假设违反"。
/// 依 AGENTS.md §"改动尽量限制在当前功能域" 原则，SearchPage AppBar.bottom
/// PreferredSize(100) 的高度硬编码属 [SearchPage.build](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart)
/// 的 UI 责任范围，本轮不动，挂 [route-topology.md §7 后续跟进](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md) P2 项，
/// 并用 takeException 白名单在契约测试里护住。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  tearDown(() {
    GSYAdaptiveNavigation.instance.resetDelegateForTest();
  });

  Widget mountFullScreen(Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchPage(const Offset(200, 200)),
      ),
    );
  }

  Widget mountRightPane({
    required Size screen,
    required double rightPaneWidth,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: screen),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(width: screen.width - rightPaneWidth),
              SizedBox(
                width: rightPaneWidth,
                child: SearchPage(const Offset(200, 200)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> didOverflow(WidgetTester tester, Widget subject) async {
    await tester.pumpWidget(subject);
    await tester.pumpAndSettle();
    final ex = tester.takeException();
    return ex is FlutterError && ex.toString().contains('overflowed');
  }

  testWidgets(
      '归属证据：右列 700dp 挂载 SearchPage → overflow 必现（与 navigator_utils_search_test 一致）',
      (tester) async {
    final overflowed = await didOverflow(
      tester,
      mountRightPane(screen: const Size(1200, 800), rightPaneWidth: 700),
    );
    expect(overflowed, isTrue,
        reason: '右列 700dp 是本轮 canShowTwoPane=true 挂载环境；'
            '若这里没 overflow，与 navigator_utils_search_test 观察不一致 → '
            '两处 fixture 有差异，需要重新对齐');
  });

  testWidgets(
      '归属证据：compact 全屏 400dp → SearchPage 不 overflow（宽度更窄反而不出问题，'
      '证明与宽度无关）',
      (tester) async {
    final overflowed =
        await didOverflow(tester, mountFullScreen(const Size(400, 800)));
    expect(overflowed, isFalse,
        reason: 'compact 全屏 400dp 比右列 700dp 更窄，若"仅宽度决定"则应更严重 overflow；'
            '实测不 overflow → 归属证据：overflow **不是**由宽度绝对值决定，'
            '而是由"SearchPage 被 Row + 固定宽度 SizedBox 约束挂载"这一挂载语境决定。'
            '因此这是本轮把 SearchPage 首次落到右列时才暴露的既存缺口，'
            '不是纯粹"SearchPage 在窄屏就坏"的历史包袱');
  });

  testWidgets(
      '归属证据：medium 全屏 720dp → SearchPage 不 overflow（与右列 700dp 宽度接近但挂载不同）',
      (tester) async {
    final overflowed =
        await didOverflow(tester, mountFullScreen(const Size(720, 1024)));
    expect(overflowed, isFalse,
        reason: 'medium 全屏 720dp 与右列 700dp 宽度仅差 20px；'
            '前者不 overflow 后者 overflow → 差异因子只可能是挂载语境（Scaffold 直挂 vs Row+SizedBox）。'
            '这条 case 是与 400dp 独立的第二个归属证据，双向锁死"宽度绝对值不是根因"');
  });

  testWidgets(
      '归属证据：expanded 全屏 1200dp（forceFullScreenDetail=true 场景）→ '
      'SearchPage 不 overflow',
      (tester) async {
    final overflowed =
        await didOverflow(tester, mountFullScreen(const Size(1200, 800)));
    expect(overflowed, isFalse,
        reason: 'forceFullScreenDetail=true 用户偏好路径下 SearchPage 也是全屏 Scaffold 挂载。'
            '与 compact / medium 全屏三档一致不 overflow → 只要 SearchPage 不进 Row+SizedBox 约束就不出问题。'
            '归属结论：本轮"canShowTwoPane=true 让 Search 落右列"路径下才需要额外处理 AppBar.bottom 高度约束');
  });
}
