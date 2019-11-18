import 'package:flutter/material.dart';

///支持顶部和顶部的TabBar控件
///配合AutomaticKeepAliveClientMixin可以keep住
class GSYTabBarWidget extends StatefulWidget {
  final TabType type;

  final bool resizeToAvoidBottomPadding;

  final List<Widget> tabItems;

  final List<Widget> tabViews;

  final Color backgroundColor;

  final Color indicatorColor;

  final Widget title;

  final Widget drawer;

  final Widget floatingActionButton;

  final FloatingActionButtonLocation floatingActionButtonLocation;

  final Widget bottomBar;

  final List<Widget> footerButtons;

  final ValueChanged<int> onPageChanged;

  GSYTabBarWidget({
    Key key,
    this.type = TabType.top,
    this.tabItems,
    this.tabViews,
    this.backgroundColor,
    this.indicatorColor,
    this.title,
    this.drawer,
    this.bottomBar,
    this.floatingActionButtonLocation,
    this.floatingActionButton,
    this.resizeToAvoidBottomPadding = true,
    this.footerButtons,
    this.onPageChanged,
  }) : super(key: key);

  @override
  _GSYTabBarState createState() => new _GSYTabBarState();
}

class _GSYTabBarState extends State<GSYTabBarWidget>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        new TabController(vsync: this, length: widget.tabItems.length);
  }

  ///整个页面dispose时，记得把控制器也dispose掉，释放内存
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == TabType.top) {
      ///顶部tab bar
      return new Scaffold(
        resizeToAvoidBottomPadding: widget.resizeToAvoidBottomPadding,
        floatingActionButton:
            SafeArea(child: widget.floatingActionButton ?? Container()),
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        persistentFooterButtons: widget.footerButtons,
        appBar: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: widget.title,
          bottom: new TabBar(
              controller: _tabController,
              tabs: widget.tabItems,
              indicatorColor: widget.indicatorColor,
              onTap: (index) {
                widget.onPageChanged?.call(index);
                _pageController
                    .jumpTo(MediaQuery.of(context).size.width * index);
              }),
        ),
        body: new PageView(
          controller: _pageController,
          children: widget.tabViews,
          onPageChanged: (index) {
            _tabController.animateTo(index);
            widget.onPageChanged?.call(index);
          },
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
          children: widget.tabViews,
          onPageChanged: (index) {
            _tabController.animateTo(index);
            widget.onPageChanged?.call(index);
          },
        ),
        bottomNavigationBar: new Material(
          //为了适配主题风格，包一层Material实现风格套用
          color: Theme.of(context).primaryColor, //底部导航栏主题颜色
          child: new SafeArea(
            child: new TabBar(
              //TabBar导航标签，底部导航放到Scaffold的bottomNavigationBar中
              controller: _tabController, //配置控制器
              tabs: widget.tabItems,
              indicatorColor: widget.indicatorColor,
              onTap: (index) {
                widget.onPageChanged?.call(index);
                _pageController
                    .jumpTo(MediaQuery.of(context).size.width * index);
              }, //tab标签的下划线颜色
            ),
          ),
        ));
  }
}

enum TabType { top, bottom }
