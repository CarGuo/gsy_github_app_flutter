import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_responsive.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/// 与 UI 框架无关的导航项描述。
///
/// 目的是**把上游调用点（页面 / shell）与具体导航实现（Material NavigationRail、
/// Cupertino 侧栏、第三方 adaptive_scaffold_router 等）解耦**：
/// caller 只声明"我有几个 tab、图标、文案分别是什么"，具体渲染由
/// [GSYAdaptiveNavigationDelegate] 决定。
///
/// 换句话说，未来把手写 rail 换成任何第三方框架时，页面代码不需要动，
/// 只需要写一个新的 delegate 并通过 [GSYAdaptiveNavigation.setDelegate] 注入即可。
@immutable
class GSYAdaptiveDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const new({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });
}

/// 自适应导航策略接口。
///
/// 由 [GSYTabBarWidget] 内部消费，是**唯一直接依赖 Material NavigationRail 的地方**。
/// 想接入其他框架时实现该接口并调用 [GSYAdaptiveNavigation.setDelegate]：
///
/// ```dart
/// GSYAdaptiveNavigation.instance.setDelegate(AdaptiveScaffoldRouterDelegate());
/// ```
///
/// 契约要求：
/// - [shouldUseRail]：给定 BuildContext 判断是否切换成 rail/side nav；默认走
///   Material 3 window size class，非 compact 就用 rail。
/// - [buildRail]：给定 destinations / selectedIndex / onSelected / 主题色，
///   返回**可直接作为 Row 左侧列展示的 Widget**；不要自己包 Scaffold / SafeArea，
///   那是外层 shell 的职责。
abstract class GSYAdaptiveNavigationDelegate {
  const new();

  bool shouldUseRail(BuildContext context);

  Widget buildRail({
    required BuildContext context,
    required List<GSYAdaptiveDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? indicatorColor,
    Color? backgroundColor,
  });

  /// 列表 item 的自适应约束出口。
  ///
  /// 目的：大屏 / 横屏时避免整行拉到 2000dp 宽把用户脖子看歪。**只**在 shell/pull-load
  /// 层调用一次即可覆盖所有列表页，禁止在页面里手写 ConstrainedBox。
  ///
  /// 契约：
  /// - compact 窗口下**必须原样返回**，不加任何额外 Widget，避免小屏下多一层 Center
  ///   导致 tap 命中区错位或列表 layout 抽风。
  /// - medium / expanded 下应在保证水平居中的前提下把 child 约束到
  ///   [GSYBreakpoints.cardMaxWidth] 以内；具体骨架允许 delegate 覆盖。
  /// - 不允许注入任何滚动/剪裁行为，只做水平居中 + 限宽。
  Widget wrapListChild({
    required BuildContext context,
    required Widget child,
  });

  /// User profile 5 列 stats 条的自适应布局出口（repos / fans / focus / star / honor）。
  ///
  /// 目的：medium 断点下"rail 96dp + stats 5 列 Expanded 均分"会把每列压到 ~130dp
  /// 以内，`40000+` 这种长数字触发 minText fallback 一路缩到 8sp，可读性坍塌。
  /// P2 §3 把 5 列的排布决策上移到 delegate，页面只递交 5 个 slot Widget。
  ///
  /// 契约：
  /// - items 长度**必须**为 5（顺序对齐 UserHeaderBottom：repos / fans / focus / star / honor），
  ///   短或长都视为调用方 bug，delegate 可 `assert`。
  /// - compact / expanded 单行 5 列均分 + 4 条竖分隔；medium 折成两行"3 + 2"，
  ///   顺序有 semantic：**上排必须是前 3 个 slot（repos / fans / focus），
  ///   下排必须是后 2 个 slot（star / honor）**。delegate 若切成 2+2+1 之类的
  ///   其它折栏，仍需保持 items 顺序不倒转，避免第三方 delegate 悄悄换 semantic
  ///   让 caller 递交的 slot 语义漂移。
  /// - **消费方必须提供有界高度约束**（例如外层 SliverPersistentHeader 固定
  ///   `maxHeight` / `minHeight`，或显式 `SizedBox(height: userStatsBarHeight(ctx))`）。
  ///   medium 双行实现依赖 `Column + Expanded` 摊分等高两行，若在无界高度
  ///   （如未受限的 `SingleChildScrollView`）里调用，会抛
  ///   "RenderFlex children have non-zero flex but incoming height constraints are unbounded"。
  /// - 返回的 Widget 需自己撑满外层给的 SliverPersistentHeader 高度，
  ///   高度值通过 [userStatsBarHeight] 单独暴露，供 SliverPersistentHeader 消费。
  /// - 分隔线颜色 / 尺寸由 delegate 内敛，页面不感知；这是与 P2 §1 wrapListChild
  ///   一致的 "delegate 拥有骨架、caller 只拥有 slot" 分工。
  Widget wrapUserStatsBar({
    required BuildContext context,
    required List<Widget> items,
  });

  /// [wrapUserStatsBar] 对应的 SliverPersistentHeader 高度。
  ///
  /// - compact / expanded：单行，返回 70（沿用 base_person_state 原 bottomSize）
  /// - medium：双行 3+2，返回 130
  ///
  /// 单独暴露而不是让 caller 硬编码，是因为高度和排布决策必须由**同一个** delegate
  /// 拍板；一旦排布骨架换（例如某个 delegate 想 2+2+1），高度必须同步跟着走，
  /// 否则 SliverPersistentHeader 会把 stats 截掉或空出黑边。
  double userStatsBarHeight(BuildContext context);

  /// 是否可以对 detail 走双栏（Master-Detail）。
  ///
  /// P2 §2 引入。GSYTabBarWidget 与所有跳 detail 的消费点（`Trend._renderItem`、
  /// `EventUtils.ActionUtils` 里 `goReposDetail` / `goIssueDetail` 主分支）在
  /// **决定要不要把 detail 挂进右列** 时都走这一个入口，避免出现"某个页面
  /// 自己判断了断点但没读 forceFullScreenDetail"这种漂移。
  ///
  /// 默认实现的语义（[MaterialAdaptiveNavigationDelegate]）：
  /// `context.canShowTwoPane` && `!forceFullScreenDetail`。
  ///
  /// 契约要求：
  /// - 返回 true 时 [openDetail] **必须**能把 widget push 到 detailNavigator
  ///   （由 shell 通过 [GSYAdaptiveNavigation.detailNavigatorKey] 挂载）；否则
  ///   会出现 "canShowTwoPane 判定为 true，但 push 直接从 master 弹全屏 detail"
  ///   的自打脸。
  /// - 该函数是**幂等只读**，禁止在里面 setState / 触发 rebuild。
  bool canShowTwoPane(BuildContext context);

  /// 打开 detail 页面的自适应入口。
  ///
  /// 契约：
  /// - [canShowTwoPane] 为 true 时，`push` 到 [GSYAdaptiveNavigation.detailNavigatorKey]
  ///   持有的内嵌 Navigator（右列），master 侧不感知栈；back 优先 pop detail 栈。
  /// - [canShowTwoPane] 为 false 时，走 `Navigator.of(context).push`，完全等价
  ///   于原来的全屏 push，避免消费点在单栏下出任何行为变化。
  /// - 返回的 Future 语义与 `Navigator.push` 一致：detail 页 `pop(result)` 后
  ///   Future 才完成。这样 notify_page 那种 `.then((_) => _forceRefresh())`
  ///   在双栏下仍然生效（detail pop 出屏后触发 refresh）。
  /// - 传入的 [detail] widget 由消费点负责构造（含 GlobalKey / ChangeNotifier），
  ///   delegate 只负责 route/animation 骨架，不做 widget 层加工。
  Future<T?> openDetail<T extends Object?>(
    BuildContext context,
    Widget detail, {
    String? routeName,
  });

  /// 用户是否强制走全屏 detail（关闭双栏）。
  ///
  /// 由 [HomeDrawer] 里的 SwitchListTile 驱动，`Config.FORCE_FULL_SCREEN_DETAIL`
  /// 走 [LocalStorage] 持久化。默认 false。
  ///
  /// 值来源：
  /// - 进程启动时 [initUserInfo] 从 LocalStorage 读一次，塞给
  ///   [AppForceFullScreenDetailState] provider；
  /// - provider 的 `change()` 调用 [setForceFullScreenDetail] 把状态镜像到
  ///   delegate；
  /// - delegate 只保留镜像，不直接依赖 Riverpod / SharedPreferences（保证
  ///   delegate 可替换 & 可 unit test）。
  bool get forceFullScreenDetail;

  /// 由 [AppForceFullScreenDetailState] 在启动或切换时调用，把用户偏好写入
  /// delegate。默认实现 [MaterialAdaptiveNavigationDelegate] 内部只做字段
  /// 赋值，不触发 rebuild —— 组件侧靠 `ref.watch` 拿到 provider 状态自然
  /// rebuild，这里镜像的目的仅仅是让 delegate 层的
  /// [canShowTwoPane] 判定拿到最新值。
  void setForceFullScreenDetail(bool value);
}

/// 默认实现：基于 Flutter Framework 原生 [NavigationRail]。
///
/// 这里是**整个项目里唯一直接 new NavigationRail 的地方**。想换实现只需要写
/// 一个平级的 delegate，不需要动 [GSYTabBarWidget] 或任何页面。
class MaterialAdaptiveNavigationDelegate extends GSYAdaptiveNavigationDelegate {
  new();

  @override
  bool shouldUseRail(BuildContext context) => !context.isCompactWindow;

  @override
  Widget buildRail({
    required BuildContext context,
    required List<GSYAdaptiveDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? indicatorColor,
    Color? backgroundColor,
  }) {
    final Color railBg = backgroundColor ?? Theme.of(context).primaryColor;
    return Material(
      color: railBg,
      child: LayoutBuilder(builder: (context, constraints) {
        final rail = NavigationRail(
          minWidth: GSYBreakpoints.railWidth,
          backgroundColor: railBg,
          indicatorColor: indicatorColor?.withValues(alpha: 0.24),
          selectedIconTheme: IconThemeData(color: indicatorColor),
          unselectedIconTheme: const IconThemeData(color: Colors.white70),
          selectedLabelTextStyle: TextStyle(color: indicatorColor),
          unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
          labelType: NavigationRailLabelType.all,
          destinations: destinations
              .map((d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon:
                        d.selectedIcon != null ? Icon(d.selectedIcon) : null,
                    label: Text(d.label),
                  ))
              .toList(),
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: rail),
          ),
        );
      }),
    );
  }

  @override
  Widget wrapListChild({
    required BuildContext context,
    required Widget child,
  }) {
    if (context.isCompactWindow) {
      return child;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: GSYBreakpoints.cardMaxWidth,
        ),
        child: child,
      ),
    );
  }

  static const double _statsBarSingleRowHeight = 70;
  static const double _statsBarDoubleRowHeight = 130;
  static const double _statsBarDividerWidth = 0.3;
  static const double _statsBarDividerHeight = 40;

  Widget _statsVerticalDivider() => Container(
        width: _statsBarDividerWidth,
        height: _statsBarDividerHeight,
        alignment: Alignment.center,
        color: GSYColors.subLightTextColor,
      );

  Widget _statsRow(List<Widget> items) {
    assert(items.isNotEmpty);
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i != 0) children.add(_statsVerticalDivider());
      children.add(items[i]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  @override
  Widget wrapUserStatsBar({
    required BuildContext context,
    required List<Widget> items,
  }) {
    assert(items.length == 5,
        'wrapUserStatsBar 契约要求 items.length == 5，实际 ${items.length}');
    if (context.isMediumWindow) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _statsRow(items.sublist(0, 3))),
          Expanded(child: _statsRow(items.sublist(3, 5))),
        ],
      );
    }
    return _statsRow(items);
  }

  @override
  double userStatsBarHeight(BuildContext context) => context.isMediumWindow
      ? _statsBarDoubleRowHeight
      : _statsBarSingleRowHeight;

  bool _forceFullScreenDetail = false;

  @override
  bool get forceFullScreenDetail => _forceFullScreenDetail;

  @override
  void setForceFullScreenDetail(bool value) {
    _forceFullScreenDetail = value;
  }

  @override
  bool canShowTwoPane(BuildContext context) =>
      context.canShowTwoPane && !_forceFullScreenDetail;

  @override
  Future<T?> openDetail<T extends Object?>(
    BuildContext context,
    Widget detail, {
    String? routeName,
  }) {
    final route = MaterialPageRoute<T>(
      settings: RouteSettings(name: routeName),
      builder: (_) => detail,
    );

    if (canShowTwoPane(context)) {
      final navState =
          GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
      // shell 侧尚未挂载 detailPane 时兜底走原来的全屏 push，避免用户 tap
      // 后什么都没有发生。理论上只可能在 shell 首帧还没 layout 时短暂命中。
      if (navState == null) {
        return Navigator.of(context).push<T>(route);
      }
      return navState.push<T>(route);
    }
    return Navigator.of(context).push<T>(route);
  }
}

/// 自适应导航全局入口。
///
/// 采用可替换单例 + 默认实现，兼顾"不用配置直接可用"与"未来 5 分钟切换到
/// 第三方框架"。使用方式：
///
/// - 消费：`GSYAdaptiveNavigation.instance.shouldUseRail(context)`
/// - 替换：在 app 入口调用
///   `GSYAdaptiveNavigation.instance.setDelegate(YourDelegate())`
/// - 单测复位：`GSYAdaptiveNavigation.instance.resetDelegateForTest()`
class GSYAdaptiveNavigation {
  new _();

  static final GSYAdaptiveNavigation instance = GSYAdaptiveNavigation._();

  GSYAdaptiveNavigationDelegate _delegate =
      MaterialAdaptiveNavigationDelegate();

  GSYAdaptiveNavigationDelegate get delegate => _delegate;

  void setDelegate(GSYAdaptiveNavigationDelegate delegate) {
    _delegate = delegate;
  }

  @visibleForTesting
  void resetDelegateForTest() {
    _delegate = MaterialAdaptiveNavigationDelegate();
    _detailNavigatorKey = GlobalKey<NavigatorState>();
  }

  /// Master-Detail 右列内嵌 Navigator 的 GlobalKey。
  ///
  /// - shell（[GSYTabBarWidget] expanded 分支）在 canShowTwoPane 时把它挂到
  ///   `Navigator(key: adaptiveNav.detailNavigatorKey, ...)`；
  /// - 消费点通过 [openDetail] 将 detail push 到这里；
  /// - 单例持有，跨 tab 切换时 detail 栈保留（"看着仓库详情切去 dynamic，
  ///   再切回 trend detail 还在"）；
  /// - 分档 resize 回单栏 / logout 时由 shell 显式调用 [popDetailToRoot]
  ///   把栈弹到根，避免 detail 内嵌栈"渗漏"到单栏形态。
  ///
  /// 用 late 而不是 final 是为了给 [resetDelegateForTest] 换新 key 的能力，
  /// 避免同一进程多个 widget test 之间 key 复用导致 "GlobalKey used in
  /// multiple places" 断言。
  GlobalKey<NavigatorState> _detailNavigatorKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get detailNavigatorKey => _detailNavigatorKey;

  /// 把 detail 内嵌栈弹到根（用于分档切回单栏时避免栈渗漏）。
  ///
  /// 无栈或 key 未挂载时静默返回，caller 不需要判空。
  void popDetailToRoot() {
    final navState = _detailNavigatorKey.currentState;
    if (navState == null) return;
    while (navState.canPop()) {
      navState.pop();
    }
  }

  bool shouldUseRail(BuildContext context) => _delegate.shouldUseRail(context);

  Widget buildRail({
    required BuildContext context,
    required List<GSYAdaptiveDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? indicatorColor,
    Color? backgroundColor,
  }) =>
      _delegate.buildRail(
        context: context,
        destinations: destinations,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        indicatorColor: indicatorColor,
        backgroundColor: backgroundColor,
      );

  Widget wrapListChild({
    required BuildContext context,
    required Widget child,
  }) =>
      _delegate.wrapListChild(context: context, child: child);

  Widget wrapUserStatsBar({
    required BuildContext context,
    required List<Widget> items,
  }) =>
      _delegate.wrapUserStatsBar(context: context, items: items);

  double userStatsBarHeight(BuildContext context) =>
      _delegate.userStatsBarHeight(context);

  bool canShowTwoPane(BuildContext context) =>
      _delegate.canShowTwoPane(context);

  Future<T?> openDetail<T extends Object?>(
    BuildContext context,
    Widget detail, {
    String? routeName,
  }) =>
      _delegate.openDetail<T>(context, detail, routeName: routeName);

  bool get forceFullScreenDetail => _delegate.forceFullScreenDetail;

  void setForceFullScreenDetail(bool value) =>
      _delegate.setForceFullScreenDetail(value);
}

/// 双栏 detail 未选中时的占位 widget。
///
/// 只在 shell 挂载了内嵌 Navigator 的初始 route 时使用；用户 tap master 里
/// 任一条目后，[GSYAdaptiveNavigation.openDetail] 会把真正的 detail 页
/// push 到内嵌 Navigator 上覆盖它。
///
/// 拆到独立类而不是塞回 GSYTabBarWidget，是为了：
/// 1. 让 delegate / shell 各司其职：shell 只提供"容器 + Navigator"，占位视觉
///    是 UI 关切，属于 gsy_adaptive_shell 的语义边界；
/// 2. 单元测试可以直接 `find.byType(GSYTwoPaneDetailPlaceholder)` 断言"没
///    push 过任何 detail 时右列是占位"。
class GSYTwoPaneDetailPlaceholder extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: GSYColors.subLightTextColor,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.two_pane_detail_empty_title,
                style: GSYConstant.normalTextBold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.two_pane_detail_empty_hint,
                style: GSYConstant.smallSubText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
