import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabs.dart' as GSYTab;

///支持顶部和顶部的TabBar控件
///配合AutomaticKeepAliveClientMixin可以keep住
class GSYTabBarWidget extends StatefulWidget {
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

  GSYTabBarWidget({
    Key? super.key,
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
  });

  @override
  _GSYTabBarState createState() => new _GSYTabBarState();
}

class _GSYTabBarState extends State<GSYTabBarWidget>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  TabController? _tabController;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        new TabController(vsync: this, length: widget.tabItems!.length);
  }

  ///整个页面dispose时，记得把控制器也dispose掉，释放内存
  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  _navigationPageChanged(index) {
    if (_index == index) {
      return;
    }
    _index = index;
    _tabController!.animateTo(index);
    widget.onPageChanged?.call(index);
  }

  _navigationTapClick(index) {
    if (_index == index) {
      return;
    }
    _index = index;
    widget.onPageChanged?.call(index);

    ///不想要动画
    _pageController.jumpTo(MediaQuery.sizeOf(context).width * index);
    widget.onSinglePress?.call(index);
  }

  _navigationDoubleTapClick(index) {
    _navigationTapClick(index);
    widget.onDoublePress?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == TabType.top) {
      ///顶部tab bar
      return new Scaffold(
        backgroundColor: GSYColors.mainBackgroundColor,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomPadding,
        floatingActionButton:
            SafeArea(child: widget.floatingActionButton ?? Container()),
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        persistentFooterButtons: widget.footerButtons,
        appBar: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: widget.title,
          bottom: new TabBar(
              controller: _tabController,
              tabs: widget.tabItems!,
              indicatorColor: widget.indicatorColor,
              onTap: _navigationTapClick),
        ),
        body: new PageView(
          controller: _pageController,
          children: widget.tabViews!,
          onPageChanged: _navigationPageChanged,
        ),
        bottomNavigationBar: widget.bottomBar,
      );
    }

    ///底部tab bar
    return new Scaffold(
        drawer: widget.drawer,
        appBar: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: widget.title,
        ),
        body: new PageView(
          controller: _pageController,
          children: widget.tabViews!,
          onPageChanged: _navigationPageChanged,
        ),
        bottomNavigationBar: new Material(
          //为了适配主题风格，包一层Material实现风格套用
          color: Theme.of(context).primaryColor, //底部导航栏主题颜色
          child: new SafeArea(
            child: new GSYTab.TabBar(
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
