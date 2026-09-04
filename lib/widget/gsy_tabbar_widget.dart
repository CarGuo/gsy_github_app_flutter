import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabs.dart' as GSYTab;

///支持顶部和顶部的TabBar控件
///配合AutomaticKeepAliveClientMixin可以keep住
class GSYTabBarWidget extends ConsumerStatefulWidget {
  final TabType type;

  final bool resizeToAvoidBottomPadding;

  final List<Widget>? tabItems;

  final List<Widget>? tabViews;

  final Color? backgroundColor;

  final Color? indicatorColor;

  final Widget? title;

  final Widget? drawer;

  final Widget? floatingActionButton;

  final FloatingActionButtonLocation? floatingActionButtonLocation;

  final Widget? bottomBar;

  final List<Widget>? footerButtons;

  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onDoublePress;
  final ValueChanged<int>? onSinglePress;

  /// medium / expanded 尺寸下 side rail 使用的入口。
  /// 为 null 时不启用 rail，仍走原有 BottomNavigationBar 逻辑。
  /// 长度必须与 [tabItems] 一致；索引与 tab / PageView 一一对应。
  ///
  /// 类型是**框架无关**的 [GSYAdaptiveDestination]，具体如何渲染成 rail 交由
  /// [GSYAdaptiveNavigation] 注入的 delegate 决定。这样上层调用点不感知
  /// Material NavigationRail / Cupertino / 第三方 adaptive 库的差异。
  final List<GSYAdaptiveDestination>? railDestinations;

  /// 只在**shell 顶层 host**（HomePage 那个 tabbar）传 true。
  ///
  /// 语义：这个 tabbar **切 tab 时**（`_navigationTapClick` /
  /// `_navigationPageChanged`）以及 **dispose 时**（[dispose]），把 detail
  /// 内嵌 Navigator 栈清空，用于：
  /// - **切 tab 语义收敛**：Trend 打开仓库 A → 切 Dynamic tab 时右列不应残留
  ///   A 仓库详情（跨 master tab 语义错位）。
  /// - **logout / relogin 防御**：dispose 时清一次，防 `GlobalKey<NavigatorState>`
  ///   reparent 到新树时残留 detail 页栈。
  ///
  /// **默认 false** — 因为 [GSYTabBarWidget] 也被用在 detail 页内部（例如
  /// [RepositoryDetailPage] 的 Info/README/Issue/Files tab）。这类内嵌 tabbar：
  /// - dispose 事故：State 会因 `ValueKey(hasDiscussionsEnabled)` 变化被销毁重建；
  ///   如果 dispose 里无条件 popDetailToRoot，就会把宿主 detail 页自己从右列栈
  ///   里弹掉（真实事故：详情页首次到货 provider 更新触发 tab 数 4→5 → key 变 →
  ///   State dispose → detail 页闪现即消失）。
  /// - **tap / pageChange 事故（2026-09-04）**：expanded 双栏下打开仓库详情后，
  ///   用户 tap 内嵌 tab bar 上任一 tab 会走到 `_navigationTapClick` →
  ///   `popDetailToRoot()` → 把宿主 `RepositoryDetailPage` 自己从
  ///   `detailNavigatorKey` 栈里弹掉，右列回到 empty state。dispose 路径当初
  ///   已收敛，但 tap / pageChange 两条路径漏了对称门控。修法：三个路径统一
  ///   用同一个 flag 门控，flag=false 的内嵌 tabbar 完全不触碰 detail 栈。
  ///
  /// 详见 [debug-repos-detail-self-pop.md](file:///d:/workspace/project/gsy_github_app_flutter/debug-repos-detail-self-pop.md)
  /// 记录的两轮事故复盘与 root cause。
  final bool clearDetailStackOnDispose;

  const new({
    super.key,
    this.type = TabType.top,
    this.tabItems,
    this.tabViews,
    this.backgroundColor,
    this.indicatorColor,
    this.title,
    this.drawer,
    this.bottomBar,
    this.onDoublePress,
    this.onSinglePress,
    this.floatingActionButtonLocation,
    this.floatingActionButton,
    this.resizeToAvoidBottomPadding = true,
    this.footerButtons,
    this.onPageChanged,
    this.railDestinations,
    this.clearDetailStackOnDispose = false,
  });

  @override
  ConsumerState<GSYTabBarWidget> createState() => _GSYTabBarState();
}

class _GSYTabBarState extends ConsumerState<GSYTabBarWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();

  TabController? _tabController;

  int _index = 0;

  /// 上一次 [didChangeMetrics] 时的 canShowTwoPane 结论。
  ///
  /// 用来给"断点跨越"下定义：只有当次 metrics 变化让 canShowTwoPane 翻转
  /// （compact↔expanded）时才触发 [GSYAdaptiveNavigation.migrateShellDetailStack]；
  /// 其他细粒度 metrics 变化（键盘弹出 / statusBar 高度变化 / textScale）
  /// 不会误触发迁移，避免用户在同分档下反复 metrics 事件里被"迁一次栈"
  /// 抹掉 detail 页内部状态。
  ///
  /// 首帧未初始化时为 null；[didChangeDependencies] 里赋初值。
  bool? _lastTwoPane;

  /// route-topology v0.2.2：detail Navigator 侧的 shellDetail 观察者。
  ///
  /// **每个 tabbar State 持独立实例**：Flutter [NavigatorState.initState]
  /// 通过 assert 约束"一个 NavigatorObserver 一次只能绑一个 Navigator"，
  /// 因此不能与 [MaterialApp.navigatorObservers] 里的 root observer 共用；
  /// 也不能每次 build 里 `new`（observers list identity 变化会触发 Navigator
  /// 走 detach/attach 分支）。放 State 字段里，生命周期与 detail Navigator
  /// GlobalKey 对齐。
  final NavigatorObserver _detailShellDetailObserver =
      GSYAdaptiveNavigation.instance.createShellDetailObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController =
        TabController(vsync: this, length: widget.tabItems!.length);
  }

  ///整个页面dispose时，记得把控制器也dispose掉，释放内存
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 说明（reviewer N4，2026-09-02 → 修订 2026-09-03）：
    // 这里的初衷是防御 logout/relogin 快速切换场景下 GlobalKey reparent
    // 到新树时可能残留的 detail 栈；但 [GSYTabBarWidget] **不仅**被用作
    // shell 顶层 host（HomePage），也被 [RepositoryDetailPage] 用作 detail
    // 内嵌 tabbar，且后者会因 `ValueKey<bool>(hasDiscussionsEnabled)` 在
    // provider 首次到货时被销毁重建。如果这里无条件 popDetailToRoot，
    // 就会把宿主 detail 页自己弹出栈 —— 表现为"tap 动态里的仓库 → 详情闪现
    // 后立即被自己弹回"。事故复盘见
    // [debug-repos-detail-self-pop.md](file:///d:/workspace/project/gsy_github_app_flutter/debug-repos-detail-self-pop.md)。
    //
    // 修复：只有显式声明 [GSYTabBarWidget.clearDetailStackOnDispose]==true
    // 的顶层 host 才在 dispose 时清 detail 栈。detail 内嵌的 tabbar 默认
    // false，dispose 只做本地资源释放。
    if (widget.clearDetailStackOnDispose) {
      GSYAdaptiveNavigation.instance.popDetailToRoot();
    }
    _tabController!.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 旋转 / 折叠屏 posture 切换后 PageView viewport 宽度变了，
    // 旧的 pixel offset 不再对应当前 _index，会出现"tab 选中第 1 页但内容停在第 0 页 90%"这种错位。
    // 在下一帧按 page 索引重新对齐，让 PageController 用最新 viewport 自行换算 offset。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_index);
      // route-topology v0.2.2：断点跨越（canShowTwoPane 翻转）时，把 shellDetail
      // 记账栈里的所有 entry 迁移到目标 Navigator，而不是直接 popDetailToRoot()
      // 把用户当前的 detail 抹掉。
      // 事故复盘（2026-09-04）：
      //  - bug a：用户在 compact 打开搜索（push 到 root Navigator）→ 拉宽到
      //    expanded → 旧实现里 detail Navigator 挂载但为空，root 栈顶 Search
      //    盖在整块 shell 之上 → 视觉是"Search 铺满整个屏幕"。
      //  - bug b：用户在 expanded 打开搜索（push 到 detail Navigator）→ 折窄到
      //    compact → 旧实现里 canShowTwoPane==false 触发 popDetailToRoot()，把
      //    detail 栈上的 Search pop 掉 → 视觉是"折一下屏搜索没了"。
      // 修复：只有顶层 shell（[clearDetailStackOnDispose]==true 的 HomePage
      // 那个 tabbar）负责触发跨断点迁移；detail 内嵌 tabbar 不感知全局路由拓扑。
      if (!widget.clearDetailStackOnDispose) return;
      final bool toTwoPane =
          GSYAdaptiveNavigation.instance.canShowTwoPane(context);
      // 仅在真正翻转时触发迁移。didChangeMetrics 在很多细粒度事件里都会
      // 被触发（键盘弹出 / statusBar 高度变化 / textScale），如果每次都
      // migrate，会把用户当前 detail 页的 State 反复重建，肉眼看着像"点
      // 一次键盘就跳一下"。此处仅比对 canShowTwoPane 结论：翻转 → 迁移，
      // 不翻转 → no-op。
      if (_lastTwoPane == toTwoPane) return;
      _lastTwoPane = toTwoPane;
      // migrateShellDetailStack 是 async；这里不等 result（unawaited）。
      // 若 rootNavigatorKey 未 attach 或目标 Navigator 未挂载，内部会
      // talker.warning 后 no-op（见其内部实现），不会抛异常。
      // ignore: unawaited_futures
      GSYAdaptiveNavigation.instance
          .migrateShellDetailStack(toTwoPane: toTwoPane);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 顶层 shell 首次拿到 MediaQuery 时种下初始 canShowTwoPane 值，避免
    // 首帧 didChangeMetrics 误判为"从 null 翻转到 <当前值>"触发不必要
    // 的迁移。只在 clearDetailStackOnDispose==true 的顶层 tabbar 生效。
    if (widget.clearDetailStackOnDispose) {
      _lastTwoPane ??=
          GSYAdaptiveNavigation.instance.canShowTwoPane(context);
    }
  }

  _navigationPageChanged(index) {
    if (_index == index) {
      return;
    }
    setState(() {
      _index = index;
    });
    _tabController!.animateTo(index);
    // M2 修复（reviewer 2026-09-02）：切 master tab 时把 detail 内嵌栈弹到根，
    // 避免"Trend 打开仓库 A → 切 Dynamic tab，右列仍显示 A 仓库详情"这种
    // 跨 tab 语义错位。popDetailToRoot 在单栏下（detailNavigatorKey 未挂载）
    // 是 no-op，因此 compact / medium 路径不受影响。
    //
    // 门控订正（reviewer 2026-09-04，配合本次自 pop 事故）：dispose 路径已经
    // 在 08d73be 收敛到 [clearDetailStackOnDispose]，但 tap/pageChange 两条
    // 路径当时漏了对称门控。事故复盘：expanded 双栏下打开仓库详情后，用户
    // tap 内嵌 tab bar 会走到这里 → 无条件 popDetailToRoot() → 把宿主
    // RepositoryDetailPage 自己从 detailNavigatorKey 栈里弹掉，右列回到
    // empty state。修法与 dispose 路径完全对称：只有显式声明为 shell 顶层
    // host（[clearDetailStackOnDispose]==true）的 tabbar 才在切 tab 时清栈；
    // detail 内嵌 tabbar 默认 false，只做 PageView 页面切换，不触碰 detail 栈。
    if (widget.clearDetailStackOnDispose) {
      GSYAdaptiveNavigation.instance.popDetailToRoot();
    }
    widget.onPageChanged?.call(index);
  }

  _navigationTapClick(index) {
    if (_index == index) {
      return;
    }
    setState(() {
      _index = index;
    });
    _tabController!.animateTo(index);
    // M2 修复（reviewer 2026-09-02）：与 _navigationPageChanged 对称，
    // 覆盖"用户 tap rail / 底部 tab"这条路径的 detail 清栈。
    // 顺序订正（reviewer 2026-09-03）：把 popDetailToRoot 放到
    // `widget.onPageChanged?.call` 之前，与 _navigationPageChanged 的
    // 「先清栈 → 再通知 host」顺序保持一致。若 host 在 onPageChanged
    // 里调 openDetail 派新的详情页，两条路径都应看到"栈已被清空"的
    // 快照，避免"tap 路径 push 立即被清、PageView 路径 push 保留"的
    // 行为漂移。
    // 更正（reviewer N1，2026-09-02）：`jumpToPage` **会**经 ScrollUpdateNotification
    // 触发 PageView.onPageChanged → _navigationPageChanged，但那一次调用会被
    // `if (_index == index) return;` 前置守卫拦下（tap 分支已先行更新 _index），
    // 因此本 tap 路径的 popDetailToRoot 只在这里生效一次，无二次触发。
    // 同样在单栏下是 no-op。
    //
    // 门控订正（reviewer 2026-09-04）：见 [_navigationPageChanged] 同名说明。
    // detail 内嵌 tabbar（默认 [clearDetailStackOnDispose]==false）tap 切
    // Info/README/Issue/Files 不再触发 popDetailToRoot，避免把宿主自己弹掉。
    if (widget.clearDetailStackOnDispose) {
      GSYAdaptiveNavigation.instance.popDetailToRoot();
    }
    widget.onPageChanged?.call(index);

    ///不想要动画
    // 用 jumpToPage 让 PageController 按当前 viewport 宽度自行换算 offset，
    // 避免手算 MediaQuery.width * index 在横屏 / 分屏 / 折叠屏下算错。
    // 再包一层 addPostFrameCallback，保证在当前帧 layout 稳定后再跳，
    // 否则连续点 tab 时可能撞上旧的 viewportDimension。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(index);
    });
    widget.onSinglePress?.call(index);
  }

  _navigationDoubleTapClick(index) {
    // 备注（reviewer N3，2026-09-02）：同 tab 双击（回顶手势）走 _navigationTapClick
    // 的 `if (_index == index) return;` 分支，**不会** popDetailToRoot——
    // 这是刻意选择：回顶是"master 内部滚动"语义，不该顺手关掉右列 detail。
    // 若未来"双击回顶"复合为"回顶 + 关 detail"，需在此处显式补一次
    // popDetailToRoot 或独立分派，不要指望 tap 分支兜住。
    _navigationTapClick(index);
    widget.onDoublePress?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == TabType.top) {
      ///顶部tab bar
      return Scaffold(
        backgroundColor: GSYColors.mainBackgroundColor,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomPadding,
        floatingActionButton:
            SafeArea(child: widget.floatingActionButton ?? Container()),
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        persistentFooterButtons: widget.footerButtons,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: widget.title,
          bottom: TabBar(
              controller: _tabController,
              tabs: widget.tabItems!,
              indicatorColor: widget.indicatorColor,
              onTap: _navigationTapClick),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _navigationPageChanged,
          children: widget.tabViews!,
        ),
        bottomNavigationBar: widget.bottomBar,
      );
    }

    ///底部tab bar
    // 是否走 rail 由全局注入的 GSYAdaptiveNavigationDelegate 说了算。
    // 默认实现在 [MaterialAdaptiveNavigationDelegate.shouldUseRail]，
    // 用 Material 3 window size class：非 compact 就切 rail。
    // 想换 5 档断点 / 平台策略只需要 setDelegate 一行代码，本文件不必再改。
    final adaptiveNav = GSYAdaptiveNavigation.instance;
    final bool useRail = widget.railDestinations != null &&
        widget.railDestinations!.length == widget.tabItems!.length &&
        adaptiveNav.shouldUseRail(context);

    // P1 阶段只切换导航容器（Rail vs BottomTabBar），
    // 卡片限宽推迟到 P2 逐页处理：直接对整 tabView 限宽会
    // 让 MyPage 顶部 5 列 stats 在 720dp 下右侧溢出。
    final Widget pageBody = PageView(
      controller: _pageController,
      onPageChanged: _navigationPageChanged,
      children: widget.tabViews!,
    );

    if (useRail) {
      // medium / expanded 尺寸走 rail：
      // 具体 rail 长什么样、要不要 scroll 兜底、图标高亮色如何配都在 delegate 里，
      // 本 widget 只负责外层 Scaffold + Row 拼装 + tab/pageview 联动，
      // 不感知 Material NavigationRail / 第三方 adaptive shell 的实现差异。
      //
      // P2 §2 引入 Master-Detail：只有 delegate 判定 canShowTwoPane 时才把
      // pageBody 装进"master + detail"两列，用 flex 42:58 对齐
      // [GSYBreakpoints.masterMaxRatio]。判定失败（compact / medium / 用户
      // 打开 forceFullScreenDetail）时保持单栏，避免把 medium 的 5 列 stats
      // 挤到 350dp 以内。
      //
      // M1 修复（reviewer 2026-09-02）：显式 `ref.watch` 强制全屏偏好，
      // 让 HomeDrawer SwitchListTile 翻转后**立刻**驱动 shell rebuild、
      // Row 双栏分支消失回退单栏。此前 delegate 单例镜像不通知 shell，
      // 会出现 "翻开关但双栏 UI 保留" 的错位。canShowTwoPane 内部已经
      // 读同一个 delegate 状态，这里再 `&&` 一次 forceFull 只是**订阅**
      // provider 变更 —— 值本身与 canShowTwoPane 结论等价。
      final bool forceFull =
          ref.watch(appForceFullScreenDetailStateProvider);
      final bool showTwoPane =
          !forceFull && adaptiveNav.canShowTwoPane(context);
      final Widget content = showTwoPane
          ? Row(
              children: [
                Expanded(
                  flex: 42,
                  child: pageBody,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 58,
                  child: ClipRect(
                    child: Navigator(
                      key: adaptiveNav.detailNavigatorKey,
                      // route-topology v0.2.2：detail Navigator 挂**独立**的
                      // shellDetail observer 实例，让"detail 侧 pop"能同步
                      // shell 记账栈；不能复用 root 侧那份，Flutter framework
                      // 在 NavigatorState.initState 里 assert 一个 observer
                      // 只能绑一个 Navigator（详见 [GSYAdaptiveNavigation
                      // .createShellDetailObserver] 注释）。
                      observers: [_detailShellDetailObserver],
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        settings: settings,
                        builder: (_) => const GSYTwoPaneDetailPlaceholder(),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : pageBody;

      return Scaffold(
          drawer: widget.drawer,
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: widget.title,
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Row(
              children: [
                adaptiveNav.buildRail(
                  context: context,
                  destinations: widget.railDestinations!,
                  selectedIndex: _index,
                  onSelected: _navigationTapClick,
                  indicatorColor: widget.indicatorColor,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: content),
              ],
            ),
          ));
    }

    return Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: widget.title,
        ),
        body: pageBody,
        bottomNavigationBar: Material(
          //为了适配主题风格，包一层Material实现风格套用
          color: Theme.of(context).primaryColor, //底部导航栏主题颜色
          child: SafeArea(
            child: GSYTab.TabBar(
              //TabBar导航标签，底部导航放到Scaffold的bottomNavigationBar中
              controller: _tabController,
              //配置控制器
              tabs: widget.tabItems!,
              indicatorColor: widget.indicatorColor,
              onDoubleTap: _navigationDoubleTapClick,
              onTap: _navigationTapClick, //tab标签的下划线颜色
            ),
          ),
        ));
  }
}

enum TabType { top, bottom }
