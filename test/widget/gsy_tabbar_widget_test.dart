import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';

/// 契约测试：确保 [GSYTabBarWidget] 的 `_navigationTapClick` /
/// `_navigationPageChanged` 里的 `popDetailToRoot()` 与 `dispose` 三条路径
/// 统一走 [GSYTabBarWidget.clearDetailStackOnDispose] 门控，避免
/// [RepositoryDetailPage] 之类"内嵌 tabbar"在 tap 切 tab 时把宿主自己弹掉。
///
/// 事故复盘 & root cause：
/// [debug-repos-detail-self-pop.md 附录 A](file:///d:/workspace/project/gsy_github_app_flutter/debug-repos-detail-self-pop.md)
void main() {
  tearDown(() {
    GSYAdaptiveNavigation.instance.resetDelegateForTest();
  });

  /// 构造一个"master 列 + expanded 双栏 detail navigator"的最小 harness：
  /// - detail navigator 挂在 `GSYAdaptiveNavigation.instance.detailNavigatorKey` 上，
  ///   初始塞一个 sentinel route 代表"当前 detail 栈里有仓库详情"
  /// - master 列是被测的 [GSYTabBarWidget]，`clearDetailStackOnDispose` 由参数控制
  Widget buildHarness({
    required bool clearDetailStackOnDispose,
    required GlobalKey<NavigatorState> masterNavKey,
  }) {
    final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 500,
                  child: Navigator(
                    key: masterNavKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings,
                      builder: (_) => GSYTabBarWidget(
                        type: TabType.top,
                        tabItems: const [
                          Tab(text: 'A'),
                          Tab(text: 'B'),
                        ],
                        tabViews: const [
                          Center(child: Text('tabA')),
                          Center(child: Text('tabB')),
                        ],
                        clearDetailStackOnDispose:
                            clearDetailStackOnDispose,
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
                        key: ValueKey('detail-sentinel'),
                        child: Text('sentinel-detail-page'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 判断 detail 栈是否还残留 sentinel route。`canPop()==true` 表示栈里除
  /// 根路由外还有页面（sentinel 就是根之上 push 的第一层），栈被清空后
  /// `canPop()==false`。
  bool detailStackHasSentinel() {
    final s = GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
    return s != null && s.canPop();
  }

  Future<void> pushSentinelDetail() async {
    // 让 detail 栈变成 [root, sentinel]，模拟"用户已经打开了仓库详情"的场景
    GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState!.pushNamed(
      '/sentinel',
    );
  }

  group('_navigationTapClick 门控（tap tab 切换）', () {
    testWidgets(
        'clearDetailStackOnDispose=false（detail 内嵌 tabbar）'
        '→ tap 切 tab 不弹 detail 栈，宿主保留',
        (tester) async {
      final masterNavKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildHarness(
        clearDetailStackOnDispose: false,
        masterNavKey: masterNavKey,
      ));
      await tester.pumpAndSettle();
      await pushSentinelDetail();
      await tester.pumpAndSettle();
      expect(detailStackHasSentinel(), true,
          reason: '前置：detail 栈里已挂了 sentinel route');

      // tap 第二个 tab（TabBar 的 onTap → _navigationTapClick）
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(detailStackHasSentinel(), true,
          reason:
              'flag=false 时 tap 切 tab 不应调用 popDetailToRoot，'
              '否则会把宿主 RepositoryDetailPage 自己弹掉');
    });

    testWidgets(
        'clearDetailStackOnDispose=true（shell 顶层 host）'
        '→ tap 切 tab 触发 popDetailToRoot，跨 master tab 语义收敛',
        (tester) async {
      final masterNavKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildHarness(
        clearDetailStackOnDispose: true,
        masterNavKey: masterNavKey,
      ));
      await tester.pumpAndSettle();
      await pushSentinelDetail();
      await tester.pumpAndSettle();
      expect(detailStackHasSentinel(), true);

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(detailStackHasSentinel(), false,
          reason:
              'flag=true 时 shell 顶层 tabbar 切 tab 应清空 detail 栈，'
              '避免"Trend 打开 A → 切 Dynamic tab 右列仍显示 A"的错位');
    });
  });

  group('_navigationPageChanged 门控（PageView 滑动切换）', () {
    testWidgets(
        'clearDetailStackOnDispose=false 时 PageView 滑动不弹 detail 栈',
        (tester) async {
      final masterNavKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildHarness(
        clearDetailStackOnDispose: false,
        masterNavKey: masterNavKey,
      ));
      await tester.pumpAndSettle();
      await pushSentinelDetail();
      await tester.pumpAndSettle();

      // 水平滑动 PageView 到第二页；PageView 的 onPageChanged →
      // _navigationPageChanged，flag=false 应不清栈
      await tester.drag(find.text('tabA'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(detailStackHasSentinel(), true,
          reason: 'flag=false 时 pageChange 也不应清 detail 栈');
    });
  });
}
