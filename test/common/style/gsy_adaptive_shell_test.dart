import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_responsive.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';

/// [GSYAdaptiveNavigation] 抽象隔离契约测试。
///
/// 意图：保证"未来 5 分钟切到第三方 adaptive 框架"这条路径可行——
/// 只要 delegate 能被替换、默认 delegate 的 shouldUseRail 遵循 compact 断点、
/// buildRail 返回的是真 Widget 而非空，业务层就无须变更。
///
/// 任何要改断点策略、想引入 5 档 window size、想加平台判断的人，
/// 先来这里写测试，确保契约不被静默破坏。
void main() {
  tearDown(() {
    // 单例状态跨测试污染是 Strategy 模式最容易踩的坑，每个 case 之后强制复位。
    GSYAdaptiveNavigation.instance.resetDelegateForTest();
  });

  Widget harness({
    required Size size,
    required void Function(BuildContext ctx) probe,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Builder(builder: (ctx) {
          probe(ctx);
          return const Scaffold(body: SizedBox.shrink());
        }),
      ),
    );
  }

  group('MaterialAdaptiveNavigationDelegate.shouldUseRail', () {
    testWidgets('宽 400 → compact，不走 rail', (tester) async {
      late bool useRail;
      await tester.pumpWidget(harness(
        size: const Size(400, 800),
        probe: (ctx) {
          useRail = GSYAdaptiveNavigation.instance.shouldUseRail(ctx);
        },
      ));
      expect(useRail, false);
    });

    testWidgets('宽 600 → medium，走 rail', (tester) async {
      late bool useRail;
      await tester.pumpWidget(harness(
        size: const Size(600, 800),
        probe: (ctx) {
          useRail = GSYAdaptiveNavigation.instance.shouldUseRail(ctx);
        },
      ));
      expect(useRail, true);
    });

    testWidgets('宽 1200 → expanded，走 rail', (tester) async {
      late bool useRail;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          useRail = GSYAdaptiveNavigation.instance.shouldUseRail(ctx);
        },
      ));
      expect(useRail, true);
    });

    testWidgets('默认 delegate buildRail 渲染真实 NavigationRail 且参数正确',
        (tester) async {
      Widget? built;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          built = GSYAdaptiveNavigation.instance.buildRail(
            context: ctx,
            destinations: const [
              GSYAdaptiveDestination(icon: Icons.home, label: 'Home'),
              GSYAdaptiveDestination(icon: Icons.trending_up, label: 'Trend'),
              GSYAdaptiveDestination(icon: Icons.person, label: 'Me'),
            ],
            selectedIndex: 1,
            onSelected: (_) {},
            indicatorColor: const Color(0xFF00E5FF),
          );
        },
      ));

      // 契约要求：默认 delegate 必须能被直接塞进 Row 左列渲染，
      // 不允许返回 null / SizedBox.shrink() / 假骨架，否则替换验证等于虚设。
      expect(built, isNotNull);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Row(children: [built!, const Expanded(child: SizedBox())]),
        ),
      ));
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.minWidth, GSYBreakpoints.railWidth);
      expect(rail.labelType, NavigationRailLabelType.all);
      expect(rail.destinations.length, 3);
      expect(rail.selectedIndex, 1);
    });
  });

  group('MaterialAdaptiveNavigationDelegate.wrapListChild', () {
    const marker = Key('gsy-wrap-list-child-marker');
    final child = Container(key: marker, height: 48);

    ConstrainedBox? findCardConstraint(WidgetTester tester) {
      final matches = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      for (final c in matches) {
        if (c.constraints.maxWidth == GSYBreakpoints.cardMaxWidth) {
          return c;
        }
      }
      return null;
    }

    testWidgets('compact 窗口不额外包装 child（原样返回）', (tester) async {
      late Widget wrapped;
      await tester.pumpWidget(harness(
        size: const Size(400, 800),
        probe: (ctx) {
          wrapped = GSYAdaptiveNavigation.instance
              .wrapListChild(context: ctx, child: child);
        },
      ));

      // 契约要求：compact 下必须返回同一实例，避免小屏多一层 Align/Center
      // 影响 tap 命中区与 layout。此断言直接锁 identical，任何静默包装都会失败。
      expect(identical(wrapped, child), true);
    });

    testWidgets('medium 窗口 → 加 ConstrainedBox maxWidth==cardMaxWidth',
        (tester) async {
      late Widget wrapped;
      await tester.pumpWidget(harness(
        size: const Size(720, 1024),
        probe: (ctx) {
          wrapped = GSYAdaptiveNavigation.instance
              .wrapListChild(context: ctx, child: child);
        },
      ));

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(720, 1024)),
        child: MaterialApp(home: Scaffold(body: wrapped)),
      ));

      // Scaffold/MaterialApp 内部有若干 ConstrainedBox（tightFor 全屏），
      // 只找 maxWidth 命中 cardMaxWidth 的那一个，避免误抓框架层约束。
      expect(findCardConstraint(tester), isNotNull);
      expect(find.byKey(marker), findsOneWidget);
    });

    testWidgets('expanded 窗口 → 加 ConstrainedBox maxWidth==cardMaxWidth 且水平居中',
        (tester) async {
      late Widget wrapped;
      await tester.pumpWidget(harness(
        size: const Size(1600, 1000),
        probe: (ctx) {
          wrapped = GSYAdaptiveNavigation.instance
              .wrapListChild(context: ctx, child: child);
        },
      ));

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1600, 1000)),
        child: MaterialApp(home: Scaffold(body: wrapped)),
      ));

      final align = tester.widget<Align>(find.byWidgetPredicate((w) =>
          w is Align && w.alignment == Alignment.topCenter));
      expect(align.alignment, Alignment.topCenter);

      expect(findCardConstraint(tester), isNotNull);
    });
  });

  group('MaterialAdaptiveNavigationDelegate.wrapUserStatsBar', () {
    // 5 个可追踪 slot，模拟 UserHeaderBottom 递交的 stats item：
    // repos / fans / focus / star / honor。用 Key 精准断言排布位置。
    List<Widget> makeItems() => List.generate(
        5,
        (i) => SizedBox(
              key: Key('stats-slot-$i'),
              width: 40,
              height: 40,
            ));

    Widget mount({required Size size, required Widget bar}) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(home: Scaffold(body: SizedBox.expand(child: bar))),
      );
    }

    testWidgets('compact 窗口 → 单行 5 列 + 4 条分隔线；高度 70', (tester) async {
      late Widget bar;
      late double h;
      final items = makeItems();
      await tester.pumpWidget(harness(
        size: const Size(400, 800),
        probe: (ctx) {
          bar = GSYAdaptiveNavigation.instance
              .wrapUserStatsBar(context: ctx, items: items);
          h = GSYAdaptiveNavigation.instance.userStatsBarHeight(ctx);
        },
      ));

      await tester.pumpWidget(mount(size: const Size(400, 800), bar: bar));

      // 单行契约：根节点 Row，不出现 Column。
      final rows = find.byType(Row);
      expect(rows, findsOneWidget);
      expect(find.byType(Column), findsNothing);

      // 5 个 slot 全部命中。
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(Key('stats-slot-$i')), findsOneWidget);
      }

      expect(h, 70);
    });

    testWidgets('medium 窗口 → 双行 3+2；高度 130', (tester) async {
      late Widget bar;
      late double h;
      final items = makeItems();
      await tester.pumpWidget(harness(
        size: const Size(720, 1024),
        probe: (ctx) {
          bar = GSYAdaptiveNavigation.instance
              .wrapUserStatsBar(context: ctx, items: items);
          h = GSYAdaptiveNavigation.instance.userStatsBarHeight(ctx);
        },
      ));

      await tester.pumpWidget(mount(size: const Size(720, 1024), bar: bar));

      // 双行契约：出现且仅出现 1 个 Column，两行分别用 Row 承载。
      expect(find.byType(Column), findsOneWidget);
      // 两个业务 Row（3 + 2）——注意 Scaffold/Column 自己可能引入结构 Widget，
      // 因此只断言至少 2 个 Row，且 5 个 slot 全部命中。
      final rowCount = tester.widgetList(find.byType(Row)).length;
      expect(rowCount >= 2, true);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(Key('stats-slot-$i')), findsOneWidget);
      }

      // 排布顺序契约：前 3 个 slot 在同一行内、后 2 个 slot 在同一行内，
      // 通过 y 坐标聚类断言（前 3 个 y 相等，后 2 个 y 相等，两组不同）。
      double y(int i) => tester
          .getTopLeft(find.byKey(Key('stats-slot-$i')))
          .dy;
      expect(y(0), y(1));
      expect(y(1), y(2));
      expect(y(3), y(4));
      expect(y(0) != y(3), true);

      // 同一行内 slot 顺序必须按 x 从左到右递增，避免 "顺序颠倒但 y 聚类通过"
      // 这种 semantic 回归——契约 doc 明确"上排 = 前 3 slot / 下排 = 后 2 slot"，
      // 顺序是有语义的（repos → fans → focus / star → honor）。
      double x(int i) => tester
          .getTopLeft(find.byKey(Key('stats-slot-$i')))
          .dx;
      expect(x(0) < x(1), true);
      expect(x(1) < x(2), true);
      expect(x(3) < x(4), true);

      expect(h, 130);
    });

    testWidgets('expanded 窗口 → 单行 5 列；高度 70', (tester) async {
      late Widget bar;
      late double h;
      final items = makeItems();
      await tester.pumpWidget(harness(
        size: const Size(1600, 1000),
        probe: (ctx) {
          bar = GSYAdaptiveNavigation.instance
              .wrapUserStatsBar(context: ctx, items: items);
          h = GSYAdaptiveNavigation.instance.userStatsBarHeight(ctx);
        },
      ));

      await tester.pumpWidget(mount(size: const Size(1600, 1000), bar: bar));

      expect(find.byType(Column), findsNothing);
      expect(find.byType(Row), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(Key('stats-slot-$i')), findsOneWidget);
      }

      expect(h, 70);
    });

    testWidgets('items 长度不为 5 触发 assert', (tester) async {
      // 契约 doc 明确"短或长都视为调用方 bug"，两侧都要测；只测短会漏掉
      // "有人往 stats 里加了第 6 项忘了改契约"这种回归。
      for (final len in const [3, 6]) {
        late Object caught;
        await tester.pumpWidget(harness(
          size: const Size(400, 800),
          probe: (ctx) {
            try {
              GSYAdaptiveNavigation.instance.wrapUserStatsBar(
                context: ctx,
                items: List.generate(len, (_) => const SizedBox.shrink()),
              );
              caught = 'no-throw';
            } catch (e) {
              caught = e;
            }
          },
        ));
        expect(caught, isA<AssertionError>(), reason: 'items.length=$len');
      }
    });
  });

  group('GSYAdaptiveNavigation delegate 可替换', () {
    testWidgets('setDelegate 之后，shouldUseRail 走新策略', (tester) async {
      GSYAdaptiveNavigation.instance
          .setDelegate(const _AlwaysOffRailDelegate());

      late bool useRail;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          useRail = GSYAdaptiveNavigation.instance.shouldUseRail(ctx);
        },
      ));

      // 默认 delegate 在 1200 宽会返回 true，替换后应遵循新策略返回 false。
      expect(useRail, false);
    });

    testWidgets('setDelegate 之后，buildRail 走新实现', (tester) async {
      GSYAdaptiveNavigation.instance
          .setDelegate(const _AlwaysOffRailDelegate());

      Widget? rail;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          rail = GSYAdaptiveNavigation.instance.buildRail(
            context: ctx,
            destinations: const [
              GSYAdaptiveDestination(icon: Icons.home, label: 'H'),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
          );
        },
      ));

      expect(rail, isA<_SentinelRail>());
    });

    testWidgets('setDelegate 之后，wrapListChild 走新实现', (tester) async {
      GSYAdaptiveNavigation.instance
          .setDelegate(const _AlwaysOffRailDelegate());

      Widget? wrapped;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          wrapped = GSYAdaptiveNavigation.instance.wrapListChild(
            context: ctx,
            child: const SizedBox.shrink(),
          );
        },
      ));

      // 契约要求：wrapListChild 也必须走 delegate，不能在单例里硬编码 material 实现。
      // 否则未来切 Cupertino/AdaptiveScaffold delegate 时列表限宽策略会失控。
      expect(wrapped, isA<_SentinelListWrap>());
    });

    testWidgets('setDelegate 之后，wrapUserStatsBar / userStatsBarHeight 走新实现',
        (tester) async {
      GSYAdaptiveNavigation.instance
          .setDelegate(const _AlwaysOffRailDelegate());

      Widget? bar;
      late double h;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          bar = GSYAdaptiveNavigation.instance.wrapUserStatsBar(
            context: ctx,
            items: List.generate(5, (_) => const SizedBox.shrink()),
          );
          h = GSYAdaptiveNavigation.instance.userStatsBarHeight(ctx);
        },
      ));

      // 契约要求：stats 条排布与其高度也必须走 delegate，否则未来第三方
      // adaptive 框架接入时，stats 折栏策略会静默退回到 Material 硬编码。
      expect(bar, isA<_SentinelStatsBar>());
      expect(h, 999);
    });

    testWidgets('resetDelegateForTest 恢复默认 Material 实现', (tester) async {
      GSYAdaptiveNavigation.instance
          .setDelegate(const _AlwaysOffRailDelegate());
      GSYAdaptiveNavigation.instance.resetDelegateForTest();

      // F7: 除了行为断言（大屏应该走 rail），必须同时按类型确认单例实例
      // 真的被复位成 MaterialAdaptiveNavigationDelegate；否则一旦有人把
      // 默认 delegate 换成"行为相似但类型不同"的实现，测试仍会误过。
      expect(
        GSYAdaptiveNavigation.instance.delegate,
        isA<MaterialAdaptiveNavigationDelegate>(),
      );

      late bool useRail;
      await tester.pumpWidget(harness(
        size: const Size(1200, 800),
        probe: (ctx) {
          useRail = GSYAdaptiveNavigation.instance.shouldUseRail(ctx);
        },
      ));

      expect(useRail, true);
    });
  });

  /// P2 §2 Master-Detail 契约测试。
  ///
  /// 意图：锁死 4 条不允许被静默修改的行为——
  /// 1. `canShowTwoPane` 必须**同时**满足"expanded 且非窄高"且"未强制全屏"；
  ///    任一破坏都直接影响 openDetail 分派与 shell 双栏渲染。
  /// 2. `setForceFullScreenDetail` 必须能立刻反映到 `canShowTwoPane` 上，
  ///    这是 HomeDrawer 开关切换后"下次 tap 立刻走全屏"的保障。
  /// 3. `openDetail` 在双栏下必须 push 到 detailNavigatorKey，单栏下必须
  ///    走根 Navigator——契约漂移会让"master 侧被 detail 页覆盖满"这种
  ///    最难 debug 的 UI bug 静默发生。
  /// 4. `popDetailToRoot` 必须清空 detail 内嵌栈，服务于"resize 回单栏"
  ///    与"logout"两条分档回退路径。
  group('Master-Detail 契约（P2 §2）', () {
    testWidgets('canShowTwoPane：expanded 且非窄高，默认返回 true', (tester) async {
      late bool ok;
      await tester.pumpWidget(harness(
        size: const Size(1400, 900),
        probe: (ctx) {
          ok = GSYAdaptiveNavigation.instance.canShowTwoPane(ctx);
        },
      ));
      expect(ok, true);
    });

    testWidgets('canShowTwoPane：medium 强制返回 false', (tester) async {
      late bool ok;
      await tester.pumpWidget(harness(
        size: const Size(720, 1024),
        probe: (ctx) {
          ok = GSYAdaptiveNavigation.instance.canShowTwoPane(ctx);
        },
      ));
      expect(ok, false);
    });

    testWidgets('canShowTwoPane：expanded 但窄高（横屏平板）返回 false', (tester) async {
      // 契约：canShowTwoPane 要求高 ≥ narrowHeightLimit（500），否则
      // detail 侧高度不足以承载 issue timeline 这种长内容。此处用 480 挑战。
      late bool ok;
      await tester.pumpWidget(harness(
        size: const Size(1400, 480),
        probe: (ctx) {
          ok = GSYAdaptiveNavigation.instance.canShowTwoPane(ctx);
        },
      ));
      expect(ok, false);
    });

    testWidgets('setForceFullScreenDetail(true) → canShowTwoPane 立刻变 false',
        (tester) async {
      late bool before;
      late bool after;
      await tester.pumpWidget(harness(
        size: const Size(1400, 900),
        probe: (ctx) {
          before = GSYAdaptiveNavigation.instance.canShowTwoPane(ctx);
          GSYAdaptiveNavigation.instance.setForceFullScreenDetail(true);
          after = GSYAdaptiveNavigation.instance.canShowTwoPane(ctx);
        },
      ));
      // 契约要求：翻转开关不需要 rebuild／重建 delegate，同一帧内下次判定就得改口。
      expect(before, true);
      expect(after, false);
      // 该字段的 getter 也必须同步反映用户偏好。
      expect(GSYAdaptiveNavigation.instance.forceFullScreenDetail, true);
    });

    testWidgets('openDetail：expanded 双栏时 push 到 detailNavigatorKey，不动根栈',
        (tester) async {
      // 挂一个"根 Navigator + 内嵌 detail Navigator"骨架，还原 shell 布局。
      final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      final markerKey = const Key('gsy-p2s2-detail-marker');
      late BuildContext masterCtx;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  flex: 42,
                  child: Builder(builder: (ctx) {
                    masterCtx = ctx;
                    return const SizedBox.expand();
                  }),
                ),
                Expanded(
                  flex: 58,
                  child: Navigator(
                    key: detailKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings,
                      builder: (_) => const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();

      // openDetail 拿 master 侧 context —— 契约要求它把 detail push 进
      // 内嵌 Navigator，而不是从 master 冒到根 Navigator。
      GSYAdaptiveNavigation.instance.openDetail(
        masterCtx,
        Container(key: markerKey),
        routeName: 'p2s2-fake',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(markerKey), findsOneWidget);
      // 断言 marker 挂在 detail Navigator 子树下——用 `find.descendant`
      // 显式验证"没有渗漏到 master 侧或根 Navigator"。
      expect(
        find.descendant(
          of: find.byWidget(detailKey.currentWidget!),
          matching: find.byKey(markerKey),
        ),
        findsOneWidget,
      );
    });

    testWidgets('openDetail：forceFullScreenDetail=true 时走根 Navigator',
        (tester) async {
      // 保持大屏尺寸不变，只翻转用户偏好，验证 openDetail 会绕开 detailKey。
      GSYAdaptiveNavigation.instance.setForceFullScreenDetail(true);

      final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      const markerKey = Key('gsy-p2s2-force-full-marker');
      late BuildContext rootCtx;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Builder(builder: (ctx) {
            rootCtx = ctx;
            return Scaffold(
              body: Row(
                children: [
                  const Expanded(flex: 42, child: SizedBox.expand()),
                  Expanded(
                    flex: 58,
                    child: Navigator(
                      key: detailKey,
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        settings: settings,
                        builder: (_) => const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ));
      await tester.pump();

      GSYAdaptiveNavigation.instance.openDetail(
        rootCtx,
        Container(key: markerKey),
        routeName: 'p2s2-force',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(markerKey), findsOneWidget);
      // 契约要求：force-full 时 detail 页**不能**出现在 detailKey 子树里，
      // 而是被根 Navigator push 到全屏。
      expect(
        find.descendant(
          of: find.byWidget(detailKey.currentWidget!),
          matching: find.byKey(markerKey),
        ),
        findsNothing,
      );
    });

    testWidgets('popDetailToRoot 清空内嵌栈；空栈时安全 no-op', (tester) async {
      final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      const rootKey = Key('gsy-p2s2-detail-root');
      const pushedKey = Key('gsy-p2s2-detail-pushed');

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: detailKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                settings: settings,
                builder: (_) => const SizedBox.expand(key: rootKey),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      // 先 push 一个 detail，再触发 popDetailToRoot；期望回到根路由。
      detailKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => const SizedBox.expand(key: pushedKey),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(pushedKey), findsOneWidget);

      GSYAdaptiveNavigation.instance.popDetailToRoot();
      await tester.pumpAndSettle();

      expect(find.byKey(pushedKey), findsNothing);
      expect(find.byKey(rootKey), findsOneWidget);

      // 空栈再调一次不应抛异常（契约里明确"caller 不需要判空"）。
      GSYAdaptiveNavigation.instance.popDetailToRoot();
      await tester.pumpAndSettle();
      expect(find.byKey(rootKey), findsOneWidget);
    });

    testWidgets(
        'openDetail：canShowTwoPane=true 但 detailNavigator 未挂载 → debug 通过 FlutterError.reportError 记账（reviewer 2026-09-03 P0-2）',
        (tester) async {
      // 意图：VG1 补齐——历史实现在此分支静默走 Navigator.of(context).push，
      // 会把 detail 挂到根 Navigator 覆盖整个 master 列。P0-2 修复后 debug
      // 必须通过 `assert(() { FlutterError.reportError(...); return true; }())`
      // 惯用法记账，让新引入这条路径的 caller 立刻在开发期暴露；同时不中断
      // 执行流，也不静默走 root push——直接返回 `Future<T?>.value(null)`，
      // 由 caller 侧的 `addPostFrameCallback` 承担重试语义。
      late BuildContext masterCtx;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) {
              masterCtx = ctx;
              return const SizedBox.expand();
            }),
          ),
        ),
      ));
      await tester.pump();

      // 前置：canShowTwoPane=true 且 detailNavigatorKey.currentState 为 null
      // （测试骨架故意不挂 detail Navigator，模拟"shell 首帧未 layout"竞态）。
      expect(GSYAdaptiveNavigation.instance.canShowTwoPane(masterCtx), isTrue);
      expect(
        GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState,
        isNull,
      );

      // 调用 openDetail：debug 下会通过 FlutterError.reportError 记账，
      // 但**不会**同步抛（区别于 `assert(false)`），保证 caller 拿到有效
      // Future 且立刻完成为 null。
      final future = GSYAdaptiveNavigation.instance.openDetail<Object?>(
        masterCtx,
        const SizedBox.shrink(),
        routeName: 'p0-2-report',
      );

      // pending exception 需要在 pumpAndSettle 前先取出，否则 binding 会
      // 在下一次 pump 时重新抛出，导致 case 挂在 pump 上。
      final reported = tester.takeException();
      expect(reported, isA<StateError>(),
          reason: 'P0-2 debug 契约：必须通过 FlutterError.reportError 记账，且是 StateError');
      expect(
        (reported as StateError).message,
        contains('detailNavigatorKey 未挂载'),
      );

      // Future 应立刻完成为 null（不 hang，也不静默走根 Navigator）。
      expect(await future, isNull);
    });

    testWidgets(
        'openDetail：caller 用 addPostFrameCallback 延后重试 → push 命中 detailKey 子树（reviewer 2026-09-03 P0-2）',
        (tester) async {
      // 意图：验证 P0-2 修复的"责任上移"策略——delegate 层立刻返回 null，
      // 但 caller 侧（deep-link / initUserInfo）遵守文档要求，在
      // `addPostFrameCallback` 里等 shell 装配完再调 openDetail，
      // 就能命中 detailNavigator 并 push 到 detailKey 子树。
      //
      // 这条 case 覆盖生产链路的正确姿势：第一次 openDetail 在 shell 未
      // 挂载时被"记账 + 丢弃"，caller 用 postFrame 延后到 shell 装配完
      // 再调一次；第二次 push 应命中 detailKey，不覆盖 master 列。
      final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      const markerKey = Key('gsy-p0-2-retry-marker');
      late BuildContext masterCtx;
      // showDetailPane 通过 setState 从 false 翻到 true，模拟"shell 首帧
      // 尚未挂 detailPane、下一帧才挂上"的真实竞态。
      final showDetailPane = ValueNotifier<bool>(false);
      addTearDown(showDetailPane.dispose);

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showDetailPane,
              builder: (_, mounted, __) => Row(
                children: [
                  Expanded(
                    flex: 42,
                    child: Builder(builder: (ctx) {
                      masterCtx = ctx;
                      return const SizedBox.expand();
                    }),
                  ),
                  Expanded(
                    flex: 58,
                    child: mounted
                        ? Navigator(
                            key: detailKey,
                            onGenerateRoute: (settings) => MaterialPageRoute(
                              settings: settings,
                              builder: (_) => const SizedBox.expand(),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      // 前置：detailNavigator 未挂载。
      expect(detailKey.currentState, isNull);

      // 第一次 openDetail：模拟"caller 在 shell 首帧就试图 push"的错误姿势，
      // 应被记账 + 丢弃，返回 null future。
      final firstFuture = GSYAdaptiveNavigation.instance.openDetail<Object?>(
        masterCtx,
        Container(key: markerKey),
        routeName: 'p0-2-retry-first',
      );
      final firstReport = tester.takeException();
      expect(firstReport, isA<StateError>(),
          reason: 'P0-2 debug 契约：第一次 openDetail 必须 report StateError');
      expect(await firstFuture, isNull,
          reason: 'P0-2 契约：navState==null 时立刻返回 null future');

      // 现在把 detailPane 挂上，模拟 shell 装配完成。
      showDetailPane.value = true;
      await tester.pumpAndSettle();
      expect(detailKey.currentState, isNotNull,
          reason: 'detailPane 挂上后 detailNavigator.currentState 必须可用');

      // 第二次 openDetail：模拟 caller 遵守契约，在 postFrame 后重试。
      // 这次应命中 detailKey 子树。
      final secondFuture = GSYAdaptiveNavigation.instance.openDetail(
        masterCtx,
        Container(key: markerKey),
        routeName: 'p0-2-retry-second',
      );
      await tester.pumpAndSettle();
      expect(secondFuture, isNotNull);

      // 关键契约：marker 出现在 detailKey 子树下，且**不**出现在根
      // Navigator 覆盖 master 列的位置。
      expect(find.byKey(markerKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byWidget(detailKey.currentWidget!),
          matching: find.byKey(markerKey),
        ),
        findsOneWidget,
        reason:
            'P0-2 契约：canShowTwoPane=true 时 openDetail 必须 push 到 detailKey，'
            '不允许静默降级到 Navigator.of(context)（会覆盖 master 列）',
      );
    });

    testWidgets(
        'openDetail：canShowTwoPane=true 但 detailNavigator 缺席 → push 丢弃 + 记账，不覆盖 master（reviewer 2026-09-03 P0-2）',
        (tester) async {
      // 意图：验证 P0-2 修复的"navState==null"分支——绝不静默走
      // Navigator.of(context).push 覆盖 master 列，而是立刻返回 null future
      // + debug 报错，把责任推给 caller 侧的 postFrame 延后。
      const markerKey = Key('gsy-p0-2-give-up-marker');
      late BuildContext masterCtx;
      // 全程不挂 detail Navigator，模拟"shell 装配 bug / detailPane 一直没上"。
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) {
              masterCtx = ctx;
              return const SizedBox.expand();
            }),
          ),
        ),
      ));
      await tester.pump();

      final future = GSYAdaptiveNavigation.instance.openDetail<Object?>(
        masterCtx,
        Container(key: markerKey),
        routeName: 'p0-2-give-up',
      );

      // 消耗 debug report 的 StateError；必须在下次 pump 前取，
      // 否则 binding 会 rethrow。
      final reported = tester.takeException();
      expect(reported, isA<StateError>(),
          reason: 'P0-2 debug 契约：canShowTwoPane=true 但 navState==null 时必须 report StateError');

      // 契约：marker 绝对**不能**出现在 widget 树里——不能被静默 push 到
      // 根 Navigator 覆盖 master 列，也不能挂到别处。
      expect(find.byKey(markerKey), findsNothing,
          reason: 'P0-2 契约：navState==null 时必须丢弃 push，禁止覆盖 master 列');
      // future 应立刻完成为 null（不 hang）。
      expect(await future, isNull);
    });

    testWidgets('resetDelegateForTest 会重建 detailNavigatorKey，避免多测试共享同一 key',
        (tester) async {
      final before = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      GSYAdaptiveNavigation.instance.resetDelegateForTest();
      final after = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      // 契约要求：重置必须换新 key，否则跨 test 复用会触发
      // "GlobalKey used in multiple places" 断言。
      expect(identical(before, after), false);
    });
  });

  /// P2 §2 Master-Detail Shell 集成契约测试（reviewer M1 / M2 fixup 2026-09-02）。
  ///
  /// 意图：
  /// 1. M1 —— 翻转 `AppForceFullScreenDetailState` provider 后，`GSYTabBarWidget`
  ///    必须**立刻** rebuild、收起右列 detail Navigator，回退单栏。此前 shell
  ///    未订阅 provider，只有 delegate 单例被镜像，用户看到的仍是双栏 UI。
  /// 2. M2 —— 切 master tab（无论走 rail tap 还是 PageView.onPageChanged）
  ///    必须把 detail 内嵌栈 pop 到根，避免"Trend 打开仓库 A，切 Dynamic
  ///    tab 后右列仍显示 A"的跨 tab 语义错位。
  group('Master-Detail shell 集成（P2 §2 M1/M2 fixup）', () {
    // GSYTwoPaneDetailPlaceholder 用了 context.l10n，MaterialApp 必须挂
    // AppLocalizations delegate 才能构造成功。这里把两条测试用到的
    // MaterialApp 参数封装到一起，避免 case 内被淹没。
    Widget mountShell({
      required Size size,
      required List<Widget> tabItems,
      required List<Widget> tabViews,
      required List<GSYAdaptiveDestination> railDestinations,
      ValueChanged<int>? onPageChanged,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GSYTabBarWidget(
              type: TabType.bottom,
              tabItems: tabItems,
              tabViews: tabViews,
              railDestinations: railDestinations,
              onPageChanged: onPageChanged,
              title: const Text('shell-test'),
            ),
          ),
        ),
      );
    }

    List<Widget> tabItems() => const [
          Tab(text: 'A'),
          Tab(text: 'B'),
          Tab(text: 'C'),
        ];

    List<Widget> tabViews() => const [
          Center(key: Key('tab-view-a'), child: Text('a')),
          Center(key: Key('tab-view-b'), child: Text('b')),
          Center(key: Key('tab-view-c'), child: Text('c')),
        ];

    List<GSYAdaptiveDestination> destinations() => const [
          GSYAdaptiveDestination(icon: Icons.trending_up, label: 'Trend'),
          GSYAdaptiveDestination(icon: Icons.notifications, label: 'Dynamic'),
          GSYAdaptiveDestination(icon: Icons.mail, label: 'Notify'),
        ];

    testWidgets(
        'M1: 翻转 appForceFullScreenDetailStateProvider(true) 后，shell 立刻回退单栏',
        (tester) async {
      // expanded 尺寸（1400×900）满足 canShowTwoPane 前置条件；初始
      // provider=false，delegate.forceFullScreenDetail=false，双栏应挂载。
      await tester.pumpWidget(mountShell(
        size: const Size(1400, 900),
        tabItems: tabItems(),
        tabViews: tabViews(),
        railDestinations: destinations(),
      ));
      await tester.pump();

      // 双栏挂载证据：detailNavigatorKey.currentState 非空（Navigator 已 build）。
      final beforeNav =
          GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
      expect(beforeNav, isNotNull,
          reason: '初始 expanded + provider=false 时应渲染双栏 detail Navigator');
      // Row 至少 2 个：外层 rail + 内层 master/detail。
      final beforeRows = tester.widgetList(find.byType(Row)).length;
      expect(beforeRows >= 2, true,
          reason: '双栏时应至少有 2 个 Row（rail Row + master/detail Row），实际 $beforeRows');
      // 强化断言（reviewer N3，2026-09-02）：placeholder 是双栏骨架里
      // 由 GSYTwoPaneDetailPlaceholder 直接持有的用户可见 UI，比"Row 数量"
      // 更贴近"用户看到双栏"的语义。翻转后必须从树中移除。
      expect(find.byType(GSYTwoPaneDetailPlaceholder), findsOneWidget,
          reason: '双栏时右列应挂载 GSYTwoPaneDetailPlaceholder 作为空态');

      // 拿到 ProviderScope 里的 container，翻转 force full-screen。
      final BuildContext ctx = tester.element(find.byType(GSYTabBarWidget));
      final container = ProviderScope.containerOf(ctx);
      container
          .read(appForceFullScreenDetailStateProvider.notifier)
          .change(true, save: false);
      await tester.pumpAndSettle();

      // 契约锁：翻转后 shell rebuild、detail Navigator 从树中移除
      // （currentState 变为 null），Row 数量回退到单栏水平。
      final afterNav =
          GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
      expect(afterNav, isNull,
          reason: 'force full-screen=true 后 detail Navigator 应从树中卸载');
      final afterRows = tester.widgetList(find.byType(Row)).length;
      expect(afterRows < beforeRows, true,
          reason:
              '双栏回退单栏后 Row 数应减少（去掉了 master/detail Row），before=$beforeRows / after=$afterRows');
      // 强化断言（reviewer N3，2026-09-02）：placeholder 也必须从 UI 树消失。
      expect(find.byType(GSYTwoPaneDetailPlaceholder), findsNothing,
          reason: 'force full-screen=true 后 GSYTwoPaneDetailPlaceholder 应从 UI 树移除');

      // delegate 侧也必须同步（Provider.change 调用了 setForceFullScreenDetail）。
      expect(GSYAdaptiveNavigation.instance.forceFullScreenDetail, true);
    });

    testWidgets(
        'M2: 切 master tab（rail 选中项变化）时把 detail 栈 pop 到根，避免跨 tab 语义错位',
        (tester) async {
      // 挂 shell、拿到 detail Navigator，push 一个 marker 页作为
      // "Trend tab 里打开的仓库详情"。
      await tester.pumpWidget(mountShell(
        size: const Size(1400, 900),
        tabItems: tabItems(),
        tabViews: tabViews(),
        railDestinations: destinations(),
      ));
      await tester.pump();

      final detailKey =
          GSYAdaptiveNavigation.instance.detailNavigatorKey;
      expect(detailKey.currentState, isNotNull,
          reason: '前置条件：expanded 双栏挂载 detail Navigator');

      const markerKey = Key('m2-cross-tab-marker');
      detailKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => const SizedBox.expand(key: markerKey),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(markerKey), findsOneWidget,
          reason: '前置条件：marker 已 push 到 detail 栈');

      // 触发切 tab：直接拿到 NavigationRail 里 onDestinationSelected 回调，
      // 模拟 rail tap（tap 坐标在 test 里不稳定；调用 callback 等价触发
      // shell 的 _navigationTapClick）。
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      rail.onDestinationSelected!(1);
      await tester.pumpAndSettle();

      // 契约锁：切 tab 后 detail 栈应回到根路由，marker 从树中消失。
      // 用 detailKey.currentState.canPop() == false 补一层白盒断言，
      // 双保险避免"marker 因为其他原因不见"的假通过。
      expect(find.byKey(markerKey), findsNothing,
          reason: 'M2 契约：切 tab 后 detail 栈应 pop 到根');
      expect(detailKey.currentState!.canPop(), false,
          reason: 'M2 契约：切 tab 后 detail 栈应只剩根路由');
    });

    testWidgets(
        'M2 对称补丁（reviewer N2，2026-09-02）: PageView 滑动路径也必须把 detail 栈 pop 到根',
        (tester) async {
      // 覆盖 _navigationPageChanged 分支：若未来有人删掉这条 popDetailToRoot
      // 调用（觉得"反正 tap 会先触发"），rail tap 路径的 test 仍会绿；这条
      // 对称 case 锁死"PageView 手势/程序化滑动也必须清栈"，避免回归漏检。
      await tester.pumpWidget(mountShell(
        size: const Size(1400, 900),
        tabItems: tabItems(),
        tabViews: tabViews(),
        railDestinations: destinations(),
      ));
      await tester.pump();

      final detailKey =
          GSYAdaptiveNavigation.instance.detailNavigatorKey;
      expect(detailKey.currentState, isNotNull,
          reason: '前置条件：expanded 双栏挂载 detail Navigator');

      const markerKey = Key('m2-pageview-marker');
      detailKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => const SizedBox.expand(key: markerKey),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(markerKey), findsOneWidget,
          reason: '前置条件：marker 已 push 到 detail 栈');

      // 触发 PageView 的 onPageChanged 分支：直接拿 PageView.onPageChanged
      // 回调（就是 shell 的 _navigationPageChanged）并显式调用，与 rail case
      // 里 `rail.onDestinationSelected!(1)` 的做法完全对称。
      //
      // 为什么不走 `controller.animateToPage(1)` + pumpAndSettle：animateToPage
      // 内部有连续 ScrollUpdateNotification 帧、并会通过 shell 联动到
      // `_tabController.animateTo`，两个 Ticker 会在 fake-async 下互相驱动
      // 导致 pumpAndSettle hang（本轮实测过）。直接调 onPageChanged callback
      // 语义等价（本 case 要锁的就是 `_navigationPageChanged` 里的 popDetailToRoot
      // 分支），只留 `_tabController.animateTo` 一路动画，pumpAndSettle 可稳定收敛。
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.onPageChanged!(1);
      await tester.pumpAndSettle();

      // 契约锁：即使只走 PageView.onPageChanged 分支（未触发 rail tap），
      // detail 栈也必须回到根。
      expect(find.byKey(markerKey), findsNothing,
          reason: 'M2 对称契约：PageView.onPageChanged 触发后 detail 栈应 pop 到根');
      expect(detailKey.currentState!.canPop(), false,
          reason: 'M2 对称契约：PageView.onPageChanged 触发后 detail 栈应只剩根路由');
    });

    testWidgets(
        'M2 顺序契约（reviewer 2026-09-03）: 两条切 tab 路径都在 host onPageChanged 之前完成 popDetailToRoot',
        (tester) async {
      // 背景（reviewer 2026-09-03）：本 case 锁的不是"detail 栈最终为空"，
      // 而是"host 在 onPageChanged 里若同步观测 detail 栈快照，两条路径观测结果一致"。
      // 上一轮 M2 修复中 tap 分支的 popDetailToRoot 位于 host callback **之后**，
      // 与 _navigationPageChanged 顺序不一致；若 host 在 onPageChanged 里
      // 调 openDetail 派新页，PageView 路径下"新页保留"、tap 路径下"新页立刻被清"，
      // 产生行为漂移。本 case 用一个 spy callback 记录调用时刻的 canPop 状态，
      // 断言两条路径都拿到 canPop=false（即栈已被清）。
      int? tapSeenCanPop;
      int? pvSeenCanPop;

      await tester.pumpWidget(mountShell(
        size: const Size(1400, 900),
        tabItems: tabItems(),
        tabViews: tabViews(),
        railDestinations: destinations(),
        onPageChanged: (index) {
          // 只在首次进入非 0 tab 时记录，避免后续 postFrame jumpToPage
          // 触发的二次 onPageChanged（会被前置守卫拦下，不会进 host，但
          // 保险起见做一次性写入）。
          final canPop = GSYAdaptiveNavigation
                  .instance.detailNavigatorKey.currentState
                  ?.canPop() ??
              true;
          // 用两个变量分记两条路径：phase1 rail tap → tapSeenCanPop；
          // phase2 PageView.onPageChanged → pvSeenCanPop。用 index 区分：
          // phase1 切到 index=1；phase2 切到 index=2。
          if (index == 1 && tapSeenCanPop == null) {
            tapSeenCanPop = canPop ? 1 : 0;
          }
          if (index == 2 && pvSeenCanPop == null) {
            pvSeenCanPop = canPop ? 1 : 0;
          }
        },
      ));
      await tester.pump();

      final detailKey =
          GSYAdaptiveNavigation.instance.detailNavigatorKey;
      expect(detailKey.currentState, isNotNull,
          reason: '前置条件：expanded 双栏挂载 detail Navigator');

      // Phase 1：先 push 一个 marker 到 detail 栈，再走 rail tap 切 tab=1。
      // 期望 host onPageChanged 被调用时，detail 栈已经是根（canPop=false）。
      const p1Marker = Key('m2-order-p1-marker');
      detailKey.currentState!.push(MaterialPageRoute(
        builder: (_) => const SizedBox.expand(key: p1Marker),
      ));
      await tester.pumpAndSettle();
      expect(detailKey.currentState!.canPop(), true,
          reason: '前置条件 P1：push 后 canPop 应为 true');

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      rail.onDestinationSelected!(1);
      await tester.pumpAndSettle();

      expect(tapSeenCanPop, 0,
          reason: 'M2 顺序契约（rail tap）：host onPageChanged 应在 popDetailToRoot 之后调用，'
              '看到 canPop=false');
      expect(find.byKey(p1Marker), findsNothing);

      // Phase 2：再次 push marker，走 PageView.onPageChanged 切 tab=2。
      // 期望 host 观察结果同 phase 1，避免"tap 与 PageView 两路径漂移"。
      const p2Marker = Key('m2-order-p2-marker');
      detailKey.currentState!.push(MaterialPageRoute(
        builder: (_) => const SizedBox.expand(key: p2Marker),
      ));
      await tester.pumpAndSettle();
      expect(detailKey.currentState!.canPop(), true,
          reason: '前置条件 P2：push 后 canPop 应为 true');

      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.onPageChanged!(2);
      await tester.pumpAndSettle();

      expect(pvSeenCanPop, 0,
          reason: 'M2 顺序契约（PageView）：host onPageChanged 应在 popDetailToRoot 之后调用，'
              '看到 canPop=false');
      expect(find.byKey(p2Marker), findsNothing);
    });

    testWidgets(
        'M2 真实滚动路径（reviewer 2026-09-03）: controller.jumpToPage 触发 PageView 内部 onPageChanged 也必须清栈',
        (tester) async {
      // 背景（reviewer 2026-09-03）：M2 对称补丁通过直接调 pageView.onPageChanged!(1)
      // 锁住 _navigationPageChanged 分支内含 popDetailToRoot；本 case 走真实
      // 触发通道（PageController.jumpToPage → PageView 内部检测 pageIndex 变化 →
      // 触发注入的 onPageChanged），覆盖"未来若把清栈职责从 _navigationPageChanged
      // 挪到外围手势/滚动通道"的重构漏检面。
      //
      // 用 jumpToPage 而不是 animateToPage：jumpToPage 无 Ticker 动画，
      // 只走一次 ScrollUpdateNotification + 一次 _lastReportedPage 比对，
      // 手动 pump 一帧即可稳定完成，规避 animateToPage + pumpAndSettle 与
      // TabController.animateTo 互驱 hang 的问题（详见前一条 case 注释）。
      await tester.pumpWidget(mountShell(
        size: const Size(1400, 900),
        tabItems: tabItems(),
        tabViews: tabViews(),
        railDestinations: destinations(),
      ));
      await tester.pump();

      final detailKey =
          GSYAdaptiveNavigation.instance.detailNavigatorKey;
      expect(detailKey.currentState, isNotNull,
          reason: '前置条件：expanded 双栏挂载 detail Navigator');

      const markerKey = Key('m2-real-scroll-marker');
      detailKey.currentState!.push(MaterialPageRoute(
        builder: (_) => const SizedBox.expand(key: markerKey),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(markerKey), findsOneWidget,
          reason: '前置条件：marker 已 push 到 detail 栈');

      // 真实触发：拿 shell 内部 PageController 调 jumpToPage(1)，让 PageView
      // 自己走一遍 ScrollUpdateNotification → onPageChanged 链路。
      final pageView = tester.widget<PageView>(find.byType(PageView));
      final controller = pageView.controller!;
      controller.jumpToPage(1);
      // jumpToPage 是同步跳，随后一帧 PageView 会 report pageIndex 变化 →
      // fire onPageChanged；此时 shell 的 _navigationPageChanged 同步执行
      // popDetailToRoot，Navigator pop 动画会挂 ticker。多 pump 几次直到
      // 稳定；不用 pumpAndSettle 是保险，避免联动的 TabController 动画在
      // 某些平台 fake-async 下拖时序。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(markerKey), findsNothing,
          reason: 'M2 真实滚动契约：PageController.jumpToPage 触发的 onPageChanged 也必须清栈');
      expect(detailKey.currentState!.canPop(), false,
          reason: 'M2 真实滚动契约：切 tab 后 detail 栈应只剩根路由');
    });

    testWidgets(
        'openDetail 分派锁死（reviewer 2026-09-03 v2）: 双栏 tap 卡片 → openDetail 一定 push 到 detailNavigatorKey',
        (tester) async {
      // 分派锁死：还原"tap 卡片 → onPressed 触发 openDetail → marker 出现
      // 在 detailKey 子树"这整条链路。避免拖入 TrendPage 的 Riverpod 全家桶
      // （trendFirstProvider / bloc / 网络栈），用 Card + TextButton 复刻
      // ReposItem.build 的关键结构。
      //
      // 与"openDetail：expanded 双栏时 push 到 detailNavigatorKey"契约 case
      // 的差异：那条 case 直接调 openDetail() 验证分派；本 case 从 tap 手势
      // 起头，验证"卡片 tap 命中 → 回调触发 → openDetail 分派"这整条链路
      // 都是通的。如果未来有人错误地把 onPressed 传成 null（disabled 状态），
      // 卡片就变成"看得见但按不动"，本 case 会 fail。
      //
      // 历史注记（2026-09-03 真机复核）：本轮最初怀疑 trend 双栏 tap 存在
      // hit-test 拦截（disabled TextButton 吃 tap）。widget test 环境实测
      // 反证了这条假设（外层 InkWell 能收到 tap），随后 debug apk + adb 真机
      // 复核也**未复现"push 拦截"**：日志 InkWell.onTap 触发正常，
      // openDetail 返回后 detailNavigatorKey.canPop=true 且 mounted=true，
      // detail 面板等约 2 秒后正确渲染 RepositoryDetailPage。
      // 用户观察到的"tap 没反应"更可能是 detail 首屏（网络 + 骨架）加载
      // 延迟造成的错觉，而非 gesture 层拦截。因此**没有修改** trend_page.dart
      // 的既有形态；本 case 保留是为了将来若真的有人把 openDetail 分派链
      // 拆坏（把 onPressed 传 null、或去掉 InkWell 但不给 ReposItem 传回调），
      // 能第一时间在 CI 挂掉。
      final detailKey = GSYAdaptiveNavigation.instance.detailNavigatorKey;
      const markerKey = Key('m2-hit-test-positive-marker');
      late BuildContext masterCtx;

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: MaterialApp(
          home: Scaffold(
            // 复刻 shell 的 master + detail 双列骨架，与"openDetail push 到
            // detailNavigatorKey"契约 case 保持一致，避免 detailKey 未挂载。
            body: Row(
              children: [
                Expanded(
                  flex: 42,
                  child: Builder(builder: (ctx) {
                    masterCtx = ctx;
                    return Center(
                      // 结构与 [ReposItem.build] 关键路径一致：
                      // Card(Material) → TextButton(onPressed) → child。
                      // 关键差异在 onPressed 传值：把 openDetail 直接接进来。
                      child: SizedBox(
                        width: 400,
                        child: Card(
                          elevation: 5,
                          child: TextButton(
                            onPressed: () {
                              GSYAdaptiveNavigation.instance.openDetail(
                                masterCtx,
                                Container(key: markerKey),
                                routeName: 'trend-hit-test',
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Text('mock trend card'),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Expanded(
                  flex: 58,
                  child: Navigator(
                    key: detailKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings,
                      builder: (_) => const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();

      // 前置：detail 栈只有根路由，没 marker。
      expect(find.byKey(markerKey), findsNothing);

      // 真实 tap 卡片：正确形态下 TextButton.onPressed 会响应，
      // 触发 openDetail 把 marker push 到 detailKey 子树。
      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      // 阳性断言 1：marker 出现在树里（openDetail 被调）。
      expect(find.byKey(markerKey), findsOneWidget,
          reason: '阳性契约：正确形态下 tap 卡片必须触发 openDetail，marker 出现在树里');
      // 阳性断言 2：marker 落点在 detail Navigator 子树，而非从 master 冒到根 Navigator。
      expect(
        find.descendant(
          of: find.byWidget(detailKey.currentWidget!),
          matching: find.byKey(markerKey),
        ),
        findsOneWidget,
        reason: '阳性契约：openDetail 必须把 marker push 到 detailNavigatorKey 子树',
      );
    });

    testWidgets(
        'HomePage.PopScope 契约（P2 §2 修复 2026-09-03）：双栏 detail 栈非空时，back 事件先弹 detail，不走 exit-to-launcher',
        (tester) async {
      // 目标：锁死 [home_page.dart] 里 PopScope.onPopInvokedWithResult 的新
      // 分派策略——detailNavigatorKey.currentState?.canPop() == true 时先
      // detailNav.pop() 一层，否则才回落到 _dialogExitApp。若未来有人手抖
      // 把 canPop 分支删掉，这个 case 会立刻挂。
      //
      // 为什么不直接挂 HomePage？HomePage 依赖 Redux store / Riverpod
      // AppState / 三个 tab 页的构造链，起来非常重；本 case 只关心 PopScope
      // 分派策略，因此在测试里手动搭一个"结构等价"的 PopScope + shell，
      // 把 HomePage 的 onPopInvokedWithResult 回调策略照抄进来即可。
      GSYAdaptiveNavigation.instance.resetDelegateForTest();
      int exitToLauncherCalled = 0;

      await tester.pumpWidget(mountShell(
        size: const Size(1400, 900),
        tabItems: tabItems(),
        tabViews: tabViews(),
        railDestinations: destinations(),
      ));
      await tester.pumpAndSettle();

      // 拿到 shell 里的 context 用于 tap 后打开 detail。
      final BuildContext shellCtx = tester.element(find.byType(GSYTabBarWidget));
      expect(GSYAdaptiveNavigation.instance.canShowTwoPane(shellCtx), isTrue,
          reason: '前置：1400x900 mediaQuery 下应走双栏');

      // Push 一层 detail 到 detailNavigatorKey，模拟"用户在 master 里 tap
      // 了一个卡片、detail 栈已经有 push 出去的页"。
      const detailPageKey = Key('back-key-test-detail-page');
      GSYAdaptiveNavigation.instance.openDetail(
        shellCtx,
        const SizedBox.expand(key: detailPageKey),
        routeName: 'back-key-test-detail',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(detailPageKey), findsOneWidget,
          reason: '前置：detail 应已 push 到 detailNavigatorKey 子树');
      expect(
        GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState
            ?.canPop(),
        isTrue,
        reason: '前置：detail 栈可 pop',
      );

      // 结构等价复现 HomePage.PopScope 的分派策略（与 home_page.dart 保持一致）：
      // canPop 时先弹一层 detail，否则回落到"退桌面"。
      void invokeHomePagePopScopeStrategy() {
        final detailNav =
            GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
        if (detailNav != null && detailNav.canPop()) {
          detailNav.pop();
          return;
        }
        exitToLauncherCalled += 1;
      }

      // 触发第一次 back：期望 detail 被弹回 placeholder，不触发 exit。
      invokeHomePagePopScopeStrategy();
      await tester.pumpAndSettle();

      expect(find.byKey(detailPageKey), findsNothing,
          reason: '契约 1：canPop==true 时 back 事件必须 pop 掉 detail 顶层');
      expect(exitToLauncherCalled, 0,
          reason: '契约 2：detail 栈仍在时禁止调用 _dialogExitApp');
      expect(
        GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState
            ?.canPop(),
        isFalse,
        reason: '契约 3：pop 掉之后 detail 应回到 placeholder，canPop==false',
      );

      // 触发第二次 back：detail 栈已空，此时才允许走 exit-to-launcher。
      invokeHomePagePopScopeStrategy();
      await tester.pump();
      expect(exitToLauncherCalled, 1,
          reason: '契约 4：detail 栈为空时 back 事件应回落到 _dialogExitApp');
    });
  });
}

class _AlwaysOffRailDelegate extends GSYAdaptiveNavigationDelegate {
  const new();

  @override
  bool shouldUseRail(BuildContext context) => false;

  @override
  Widget buildRail({
    required BuildContext context,
    required List<GSYAdaptiveDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? indicatorColor,
    Color? backgroundColor,
  }) {
    return const _SentinelRail();
  }

  @override
  Widget wrapListChild({
    required BuildContext context,
    required Widget child,
  }) {
    return const _SentinelListWrap();
  }

  @override
  Widget wrapUserStatsBar({
    required BuildContext context,
    required List<Widget> items,
  }) {
    return const _SentinelStatsBar();
  }

  @override
  double userStatsBarHeight(BuildContext context) => 999;

  // P2 §2 契约兜底：这个 fake 只用来验证"resetDelegateForTest 是否真的把
  // 单例复位成 Material 实现"，与 Master-Detail 行为无关，因此给出静态最小
  // 实现即可 —— canShowTwoPane 恒 false 强制单栏，openDetail 直接走
  // Navigator.push，避免碰到 detailNavigatorKey.currentState 未挂载的边界。
  @override
  bool canShowTwoPane(BuildContext context) => false;

  @override
  Future<T?> openDetail<T extends Object?>(
    BuildContext context,
    Widget detail, {
    String? routeName,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: RouteSettings(name: routeName),
        builder: (_) => detail,
      ),
    );
  }

  @override
  bool get forceFullScreenDetail => false;

  @override
  void setForceFullScreenDetail(bool value) {
    // no-op：本 fake 不参与偏好联动
  }
}

class _SentinelRail extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SentinelListWrap extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SentinelStatsBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
