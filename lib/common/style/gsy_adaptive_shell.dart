import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
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

    final bool two = canShowTwoPane(context);
    if (two) {
      final navState =
          GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
      if (navState != null) {
        return navState.push<T>(route);
      }
      // canShowTwoPane==true 但 detailNavigator 尚未挂载：只可能是 shell
      // 首帧还没 layout 就有 caller 触发 openDetail（例如启动路由里的
      // deep-link push）。历史实现走 `Navigator.of(context).push` 兜底，
      // 但 caller 传的 context 位于 master 侧，`Navigator.of(context)`
      // 会把 detail push 到**根 Navigator**，直接把 master 列覆盖满，
      // 违反 P2 §2 的双栏契约（reviewer 2026-09-03 P0-2）。
      //
      // 修复策略：
      // - 立刻返回 `Future<T?>.value(null)`：caller 拿到的 Future 有效，
      //   不会静默走全屏 push 覆盖 master 列；
      // - debug 用 `assert(() { reportError; return true; }())` 惯用法
      //   把这条竞态 report 到 FlutterError，让新引入这条路径的调用点
      //   立刻在开发期暴露；release AOT 会把整个 assert 表达式移除；
      // - **release 侧**用 talker.warning 兜住可观测性（reviewer S1，
      //   2026-09-03）：本文件里的 `logger.dart::talker` 是全局单例，
      //   `useHistory=true, maxHistoryItems=100`，release 也会写进
      //   talker 历史，让线上排查"tap detail 无反应但 Future 已 complete"
      //   有据可查；不会在 caller 侧引入行为漂移；
      // - **修复责任上移到 caller**：deep-link / initUserInfo 里触发
      //   openDetail 前先 `WidgetsBinding.instance.addPostFrameCallback`
      //   等 shell 装配完，避免这条竞态；把 retry 塞在 delegate 里会引入
      //   `postFrame -> talker -> zone rethrow` 的隐式死锁面，得不偿失。
      assert(() {
        FlutterError.reportError(FlutterErrorDetails(
          exception: StateError(
            'openDetail: canShowTwoPane=true 但 detailNavigatorKey 未挂载。'
            'shell 首帧竞态或 deep-link 起飞过早，请把该 push 延后到 '
            'WidgetsBinding.instance.addPostFrameCallback 内。'
            'route=${route.settings.name}',
          ),
          library: 'gsy adaptive shell',
          context: ErrorDescription(
              'while openDetail() attempting push to detailNavigator'),
        ));
        return true;
      }());
      talker.warning(
        'openDetail dropped: canShowTwoPane=true but detailNavigatorKey '
        'not mounted. route=${route.settings.name}. '
        'Caller should defer push into addPostFrameCallback.',
      );
      return Future<T?>.value(null);
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
    _shellDetailStack.clear();
    _rootNavigatorKey = null;
    _migrating = false;
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

  /// Root Navigator 引用。由 app.dart 在 [MaterialApp.navigatorKey] 挂载后
  /// 通过 [attachRootNavigator] 注入。断点迁移时需要在源/目标两个 Navigator
  /// 之间 pop/push shellDetail 路由，本字段是"root 侧 Navigator"的稳定 handle。
  ///
  /// 值来源约束：只允许 app.dart 在启动装配阶段调用一次
  /// [attachRootNavigator]；框架层不主动读 MaterialApp.navigatorKey 避免与
  /// build 顺序耦合。
  GlobalKey<NavigatorState>? _rootNavigatorKey;

  GlobalKey<NavigatorState>? get rootNavigatorKey => _rootNavigatorKey;

  /// 由 app 装配阶段注入 root Navigator key，仅接受一次。
  void attachRootNavigator(GlobalKey<NavigatorState> key) {
    _rootNavigatorKey = key;
  }

  /// shellDetail 路由记账栈。
  ///
  /// 每次 [openDetail] push 都追加一个 entry（含 routeName + WidgetBuilder），
  /// pop 时通过 [_ShellDetailRouteObserver] 同步移除。
  /// 断点迁移（[migrateShellDetailStack]）依赖它把源侧 pop 完的 route 用
  /// builder 在目标侧重放，保证跨断点业务参数不丢。
  final List<GSYShellDetailEntry> _shellDetailStack = <GSYShellDetailEntry>[];

  /// 只暴露只读快照（routeName 列表），避免调用点越权修改内部记账；
  /// 契约测试与真机诊断可以按序读取当前 shellDetail 栈顶。
  List<String> get debugShellDetailRouteNames =>
      List.unmodifiable(_shellDetailStack.map((e) => e.routeName));

  /// 迁移中标志。true 时禁止 [_ShellDetailRouteObserver] 把迁移过程中的
  /// `didPop` / `didPush` 计入用户栈（否则会把"迁移用的 pop"当成"用户返回"
  /// 从 entry 栈里抹掉）。
  bool _migrating = false;

  /// 把 detail 内嵌栈弹到根（用于分档切回单栏时避免栈渗漏）。
  ///
  /// 无栈或 key 未挂载时静默返回，caller 不需要判空。
  /// 注意：此方法**只 pop 当前挂载的 detail Navigator**，不清理 root Navigator
  /// 上遗留的 shellDetail 路由 —— compact 分档下 shellDetail 也 push 到 root，
  /// 用户 tap tab 切换语义希望"当前 detail 关掉"，但不能把 root 栈其它 route
  /// （比如 LoginPage / GSYWebView）也 pop 掉。
  void popDetailToRoot() {
    final navState = _detailNavigatorKey.currentState;
    if (navState == null) return;
    while (navState.canPop()) {
      navState.pop();
    }
    _shellDetailStack.clear();
  }

  /// 断点跨越时的路由迁移入口。
  ///
  /// 由 [GSYTabBarWidget.didChangeMetrics] 检测到 `canShowTwoPane` 翻转后
  /// 调用；根据当前 `canShowTwoPane` 结论把 shellDetail 记账栈里的 entries
  /// 全部搬到目标 Navigator：
  /// - `toTwoPane=true`：把 root 栈上的 shellDetail routes 依次 pop → 用
  ///   entry 的 builder 在 detail Navigator 上重放；
  /// - `toTwoPane=false`：把 detail Navigator 上的 shellDetail routes 依次
  ///   pop → 用 entry 的 builder 在 root Navigator 上重放。
  ///
  /// 迁移过程中 [_migrating] = true，防止 [_ShellDetailRouteObserver] 把
  /// 迁移的 pop/push 当作用户操作把 entry 栈错乱。
  Future<void> migrateShellDetailStack({required bool toTwoPane}) async {
    if (_shellDetailStack.isEmpty) return;
    final rootNav = _rootNavigatorKey?.currentState;
    final detailNav = _detailNavigatorKey.currentState;
    if (rootNav == null) {
      talker.warning(
        'migrateShellDetailStack: rootNavigatorKey 未 attach，跳过迁移。'
        '请在 app 装配阶段调用 GSYAdaptiveNavigation.instance.attachRootNavigator。',
      );
      return;
    }
    if (toTwoPane && detailNav == null) {
      talker.warning(
        'migrateShellDetailStack: 目标 detail Navigator 未挂载，跳过迁移。',
      );
      return;
    }

    final entries = List<GSYShellDetailEntry>.from(_shellDetailStack);
    _migrating = true;
    try {
      // 1. 从源 Navigator 弹掉所有 shellDetail routes（自栈顶向下）。
      //
      // 反向迁移（expanded→compact）时源是 detailNav，但**这时 shell 已经
      // rebuild**（[GSYTabBarWidget.build] 里 expanded 分支的 Row 已不再
      // 装配右列 Navigator），`_detailNavigatorKey.currentState` 已经变成
      // null；对应的 detail Navigator element 已被 dispose，栈里的 routes
      // 也随之释放，**不需要也不能再 pop**（`detailNav!` 会 NPE）。
      //
      // 事故复盘（2026-09-04）：初版写成 `source = toTwoPane ? rootNav :
      // detailNav!`，expanded→compact 触发 didChangeMetrics 时 detail
      // Navigator 已 unmount，`detailNav!` 直接抛 "Null check operator used
      // on a null value" @ line 504，导致迁移中断、Search 页丢失。
      // 修复：source 允许为 null，null 时视作"源已释放，直接跳到 target
      // 重放"即可。
      final NavigatorState? source = toTwoPane ? rootNav : detailNav;
      if (source != null) {
        for (var i = entries.length - 1; i >= 0; i--) {
          if (source.canPop()) {
            source.pop();
          }
        }
      }
      // 2. 在目标 Navigator 用 builder 依次 push（栈底→栈顶顺序）
      final NavigatorState target = toTwoPane ? detailNav! : rootNav;
      _shellDetailStack.clear();
      for (final entry in entries) {
        final route = _buildShellDetailRoute(entry, toTwoPane: toTwoPane);
        _shellDetailStack.add(entry);
        // ignore: unawaited_futures
        target.push(route);
      }
    } finally {
      _migrating = false;
    }
  }

  Route<Object?> _buildShellDetailRoute(
    GSYShellDetailEntry entry, {
    required bool toTwoPane,
  }) {
    // 目标 Navigator 是 detail（toTwoPane=true）→ MaterialPageRoute（右列滑入）；
    // 目标 Navigator 是 root（toTwoPane=false）→ CupertinoPageRoute（与 compact
    // 常规 push 观感一致）。
    final settings = RouteSettings(name: entry.routeName);
    if (toTwoPane) {
      return MaterialPageRoute<Object?>(
        settings: settings,
        builder: entry.builder,
      );
    }
    return CupertinoPageRoute<Object?>(
      settings: settings,
      builder: entry.builder,
    );
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

  /// 记录一条 shellDetail entry（供 [NavigatorUtils._openDetailOrRouter] 调用）。
  ///
  /// 与 [openDetail] 分离是刻意：openDetail 直接接受已构造的 Widget（历史签名，
  /// 兼容第三方 delegate 不认识 builder 的场景），而断点迁移需要 builder。
  /// 由 caller 侧同时把 builder 和 push 结果登记进来，观察者负责在 pop 时
  /// 从栈里移除。
  void trackShellDetailEntry(GSYShellDetailEntry entry) {
    _shellDetailStack.add(entry);
  }

  /// 从记账栈里移除最新一条（供 [_ShellDetailRouteObserver.didPop] 使用）。
  void _popShellDetailEntry(String? routeName) {
    if (_migrating) return;
    if (_shellDetailStack.isEmpty) return;
    // 通常 pop 的就是栈顶，routeName 可用作诊断/防御。
    if (routeName == null || _shellDetailStack.last.routeName == routeName) {
      _shellDetailStack.removeLast();
      return;
    }
    // 出现顺序错乱（例如 route 通过 pushReplacement 更替），退化为按名字找
    for (var i = _shellDetailStack.length - 1; i >= 0; i--) {
      if (_shellDetailStack[i].routeName == routeName) {
        _shellDetailStack.removeAt(i);
        return;
      }
    }
  }

  /// 工厂方法：为每个需要 observe 的 Navigator 创建一个**独立**的
  /// [NavigatorObserver] 实例。
  ///
  /// **不能返回单例**。Flutter framework 在 [NavigatorState.initState] 里
  /// 走 `_effectiveObservers.forEach((o) { assert(o.navigator == null); ... })`
  /// —— 同一个 [NavigatorObserver] 实例**只允许绑定到一个** [NavigatorState]。
  /// 如果把同一个 observer 同时挂到 [MaterialApp.navigatorObservers]（root）
  /// 与 shell 内嵌 detail Navigator 的 `observers`，第二个 Navigator 初始化
  /// 时会命中 assert，debug build 直接 throw、release build 行为未定义
  /// （实测表现为 detail Navigator 挂载异常，master 侧的 `Navigator.push`
  /// 拿到的是坏掉的 NavigatorState，导致 "tap item 无反应"）。
  ///
  /// 事故复盘（2026-09-04）：初版把 `shellDetailObserver` 写成
  /// `late final NavigatorObserver = _ShellDetailRouteObserver(this)` 单例，
  /// 同时挂在 app.dart 与 gsy_tabbar_widget.dart，导致动态列表点击失效。
  /// 改成工厂方法后每处 Navigator 各持一个实例，事件通过共享的 `_owner`
  /// （= `this`）forward 到同一个 [_shellDetailStack]，记账语义不变。
  NavigatorObserver createShellDetailObserver() =>
      _ShellDetailRouteObserver(this);

  bool get forceFullScreenDetail => _delegate.forceFullScreenDetail;

  void setForceFullScreenDetail(bool value) =>
      _delegate.setForceFullScreenDetail(value);
}

/// shellDetail 记账 entry。
///
/// [routeName]：与 route settings.name 对齐，用于诊断 + pop 顺序防御。
/// [builder]：跨断点迁移时在目标 Navigator 上重放的构造闭包；由 caller 侧
/// （[NavigatorUtils]）传入，天然捕获业务参数（userName / reposName /
/// centerPosition / ...），因此重放后业务上下文保住。
///
/// 类型公开是刻意：[NavigatorUtils] 在 push 之前需要构造 entry，虚构一个
/// 私有类型 + factory 函数并没有隔离价值，还额外一层拆包。字段全 final，
/// 消费方持有引用也没有让 GSYAdaptiveNavigation 状态被外部改的风险。
@immutable
class GSYShellDetailEntry {
  final String routeName;
  final WidgetBuilder builder;

  const new({required this.routeName, required this.builder});
}

/// 观察 shellDetail 记账栈的 [NavigatorObserver]。
///
/// 仅关心带 [GSYShellDetailEntry.routeName] 前缀的 route（其余 route 让走）。
/// 迁移期间通过 [GSYAdaptiveNavigation._migrating] 门控，避免把"迁移用的
/// pop / push"错误计入。
class _ShellDetailRouteObserver extends NavigatorObserver {
  final GSYAdaptiveNavigation _owner;

  _ShellDetailRouteObserver(this._owner);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _owner._popShellDetailEntry(route.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _owner._popShellDetailEntry(route.settings.name);
  }
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
