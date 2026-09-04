import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 路由拓扑契约测试：`NavigatorUtils.goSearchPage` 在 canShowTwoPane=true 时
/// 必须 push 到 [GSYAdaptiveNavigation.detailNavigatorKey] 挂载的右列 Navigator，
/// 而不是 caller 侧的 root Navigator。
///
/// 事故与决策见 [docs/01-architecture/route-topology.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md)
/// §2 方向 A：Search 收敛为 shellDetail 语义，避免 root overlay 覆盖 shell 后
/// tap 卡片时右列 detail 变化不可见（用户"点了没反应"）。
void main() {
  setUp(() {
    // SearchPage.initState 里会 _loadHistory → SharedPreferences.getInstance()，
    // 单测环境未挂 platform channel 会抛 MissingPluginException 中断 pump。
    // 用空 map 让 SearedPreferences 走 in-memory mock，_loadHistory 得到空历史列表。
    SharedPreferences.setMockInitialValues(const {});
  });

  tearDown(() {
    GSYAdaptiveNavigation.instance.resetDelegateForTest();
  });

  /// 构造与 [buildHarness in gsy_tabbar_widget_test.dart] 同构的 Master/Detail 双栏 harness：
  /// - master 侧 Navigator 显示一个"入口"页面，用于触发 goSearchPage；
  /// - detail 侧 Navigator 挂 [GSYAdaptiveNavigation.detailNavigatorKey]，
  ///   契约要求 goSearchPage 在 canShowTwoPane=true 下 push 到这里。
  Widget buildHarness({
    required Size size,
    required GlobalKey<NavigatorState> masterNavKey,
  }) {
    final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 500,
                child: Navigator(
                  key: masterNavKey,
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => Center(
                      child: Builder(builder: (innerCtx) {
                        return ElevatedButton(
                          key: const ValueKey('trigger-search'),
                          onPressed: () {
                            NavigatorUtils.goSearchPage(
                              innerCtx,
                              const Offset(200, 200),
                            );
                          },
                          child: const Text('open-search'),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Navigator(
                  key: detailKey,
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const Center(
                      key: ValueKey('detail-placeholder'),
                      child: Text('detail-placeholder'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
      'canShowTwoPane=true（宽 1200） → goSearchPage push 到 detailNavigator，'
      'master 侧 Navigator 保持不变',
      (tester) async {
    final masterNavKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(buildHarness(
      size: const Size(1200, 800),
      masterNavKey: masterNavKey,
    ));
    await tester.pumpAndSettle();

    final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
    expect(detailKey.currentState!.canPop(), false,
        reason: '前置：detail 栈只有 placeholder 根路由，canPop 应为 false');
    expect(masterNavKey.currentState!.canPop(), false,
        reason: '前置：master 栈只有入口页面');

    await tester.tap(find.byKey(const ValueKey('trigger-search')));
    // SearchPage 内部 initState 用 Future.delayed(Duration.zero) 起 controller，
    // pumpAndSettle 会把这些异步微任务全部消化掉。
    await tester.pumpAndSettle();

    // SearchPage 的 AppBar.bottom 是 PreferredSize(100)，包 Column 装
    // GSYSearchInputWidget + GSYSelectItemWidget，在 detail 侧 700dp 宽度
    // 分档下 intrinsic 高度会溢出 ~22px（"A RenderFlex overflowed"）。
    // 这是 SearchPage 既有的窄栏渲染缺口，不属于本次路由拓扑契约验证目标；
    // 但 takeException 必须做白名单校验（reviewer P1-1）——无参 takeException 会
    // 静默吞任何 exception，未来若本轮/后续在 openDetail 路径上引入别的异常
    // （GlobalKey 冲突、Animation cast、_openDetailOrRouter push 抛异常）会被
    // 一起吞掉、测试仍绿，等于用测试掩盖新引入的 bug。这里锁死 overflow
    // 白名单，任何非 overflow 异常都会重新抛出让测试红。
    final ex = tester.takeException();
    expect(ex, isA<FlutterError>(),
        reason: '本轮路由拓扑收敛期望的唯一 exception 是 AppBar.bottom overflow；'
            '若类型不是 FlutterError，说明本轮引入了别的异常，禁止被 takeException 吞掉');
    expect(ex.toString(), contains('overflowed'),
        reason: '本轮路由拓扑收敛期望的唯一 exception 是 RenderFlex overflowed（AppBar.bottom 既有窄栏缺口）；'
            '若消息里没有 overflowed 关键字，说明本轮引入了别的错误，禁止被 takeException 吞掉');

    expect(detailKey.currentState!.canPop(), true,
        reason:
            'canShowTwoPane=true 下 goSearchPage 必须走 openDetail，'
            'detail 栈从 [root] 变为 [root, SearchPage]');
    expect(masterNavKey.currentState!.canPop(), false,
        reason:
            'master 侧不应有任何 push——若 canPop=true 表明 SearchPage 又跑回 '
            'root Navigator，就是 route-topology.md §2 描述的原漏洞回归');
  });

  testWidgets(
      'forceFullScreenDetail=true 时（用户偏好关闭双栏）'
      ' → goSearchPage 走 Cupertino 全屏 push 到 caller 侧 Navigator，'
      'detail 栈保持空',
      (tester) async {
    // 用户偏好优先级高于窗口断点：即便 1200 宽也应视作单栏，
    // 与 [MaterialAdaptiveNavigationDelegate.canShowTwoPane] 契约一致。
    GSYAdaptiveNavigation.instance.setForceFullScreenDetail(true);

    final masterNavKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(buildHarness(
      size: const Size(1200, 800),
      masterNavKey: masterNavKey,
    ));
    await tester.pumpAndSettle();

    final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
    expect(detailKey.currentState!.canPop(), false);

    await tester.tap(find.byKey(const ValueKey('trigger-search')));
    await tester.pumpAndSettle();

    expect(masterNavKey.currentState!.canPop(), true,
        reason:
            'forceFullScreenDetail=true 时 _openDetailOrRouter 走 '
            'CupertinoPageRoute，Search 应 push 到 caller Navigator');
    expect(detailKey.currentState!.canPop(), false,
        reason: 'forceFullScreenDetail=true 时 detailNavigator 栈应保持空');
  });

  testWidgets(
      'compact 窗口（宽 400） → goSearchPage 全屏 push 到 caller Navigator，'
      'detail 栈保持空',
      (tester) async {
    final masterNavKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(buildHarness(
      size: const Size(400, 800),
      masterNavKey: masterNavKey,
    ));
    await tester.pumpAndSettle();

    final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;

    await tester.tap(find.byKey(const ValueKey('trigger-search')));
    await tester.pumpAndSettle();

    expect(masterNavKey.currentState!.canPop(), true,
        reason:
            'compact 下 canShowTwoPane=false → 走 CupertinoPageRoute 全屏 push，'
            '保持与改造前的窄屏体感等价');
    expect(detailKey.currentState!.canPop(), false,
        reason: 'compact 下 detailNavigator 栈应保持空');
  });
}
