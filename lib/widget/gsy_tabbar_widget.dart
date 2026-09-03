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
  });

  @override
  ConsumerState<GSYTabBarWidget> createState() => _GSYTabBarState();
}

class _GSYTabBarState extends ConsumerState<GSYTabBarWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();

  TabController? _tabController;

  int _index = 0;

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
    // 备注（reviewer N4，2026-09-02）：dispose 时 detailNavigatorKey 通常已
    // 随 shell 一起 unmount，`currentState == null`，popDetailToRoot 会走
    // 空栈 no-op 分支——本行**不是**为了就地清栈，而是防御 logout/relogin
    // 快速切换场景下 GlobalKey reparent 到新树时可能残留的栈。detail 强制
    // 全屏偏好属于用户级别持久化，与 shell 生命周期无关，此处不动。
    GSYAdaptiveNavigation.instance.popDetailToRoot();
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
      // 分档从 expanded 掉回 medium/compact 时，用户在双栏 detail 栈里
      // push 的一堆页面会被 shell 卸掉右列 —— 此时那些 route 挂在游离
      // 的 GlobalKey<NavigatorState> 上不会自动销毁，等下次再切回 expanded
      // 时会诡异地"复活"上一次的 detail。做法：只要当前 context 已经
      // 不满足 canShowTwoPane，就把 detail 栈弹到根。
      // 用 canShowTwoPane 而不是 shouldUseRail 是刻意：force 全屏开关
      // 打开的 expanded 也应该视为"没在展示双栏"，避免用户切换开关
      // 时 detail 栈残留。
      if (!GSYAdaptiveNavigation.instance.canShowTwoPane(context)) {
        GSYAdaptiveNavigation.instance.popDetailToRoot();
      }
    });
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
    GSYAdaptiveNavigation.instance.popDetailToRoot();
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
    GSYAdaptiveNavigation.instance.popDetailToRoot();
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
