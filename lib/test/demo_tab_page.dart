import 'package:flutter/material.dart';

class DemoTabPage extends StatefulWidget {
  @override
  _DemoTabPageState createState() => _DemoTabPageState();
}

class _DemoTabPageState extends State<DemoTabPage> {
  @override
  Widget build(BuildContext context) {
    return TabWidget(
      type: TabType.bottom,
      title: new Text("标题"),
      tabItems: getTab(),
      tabViews: getPages(),
    );
  }

  getTab() {
    return [
      Tab(
        text: "tab1",
        icon: Icon(Icons.access_alarm),
      ),
      Tab(
        text: "tab2",
        icon: Icon(Icons.android),
      ),
      Tab(
        text: "tab3",
        icon: Icon(Icons.ac_unit),
      ),
    ];
  }

  getPages() {
    return [
      Container(
        color: Colors.blue,
      ),
      Container(
        color: Colors.red,
      ),
      Container(
        color: Colors.amber,
      ),
    ];
  }
}

enum TabType { bottom, top }

class TabWidget extends StatefulWidget {
  final TabType type;

  final List<Widget> tabItems;

  final List<Widget> tabViews;

  final Color indicatorColor;

  final Widget title;

  final PageController pageController;

  final ValueChanged<int> onPageChanged;

  final ValueChanged<int> onTap;

  final int initTabIndex;

  TabWidget({
    Key key,
    this.type = TabType.top,
    this.tabItems,
    this.tabViews,
    this.indicatorColor = Colors.green,
    this.title,
    this.initTabIndex = 0,
    this.pageController,
    this.onPageChanged,
    this.onTap,
  }) : super(key: key);

  @override
  _GSYTabBarState createState() => new _GSYTabBarState();
}

class _GSYTabBarState extends State<TabWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _tabController = new TabController(
        vsync: this,
        length: widget.tabViews.length,
        initialIndex: widget.initTabIndex);

    _pageController = widget.pageController;
    _pageController ??= PageController();
  }

  TabController _tabController;
  PageController _pageController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ///返回底部类型的 Tab
  Widget _getBottomNavByType() {
    /// 为了主题风格，包一层 Material 实现风格套用
    return new Material(
      /// 底部导航栏主题颜色
      color: Colors.black,
      child: new Container(
        decoration: BoxDecoration(
          ///设置一个底部分割线
          border: Border(
            top: Divider.createBorderSide(context, color: Colors.grey),
          ),
        ),

        ///使用 SafeArea 判断底部安全区域
        child: new SafeArea(
          ///使用 Theme 嵌套去除 splashColor 的点击颜色
          child: Theme(
              data: Theme.of(context).copyWith(splashColor: Colors.transparent),
              child: new TabBar(
                controller: _tabController,
                labelPadding: EdgeInsets.zero,
                tabs: widget.tabItems,

                /// tab标签的下划线颜色
                indicatorColor: widget.indicatorColor,

                onTap: (index) {
                  ///点击时 500 毫秒的滑动
                  _pageController.animateToPage(index,
                      curve: Curves.linear,
                      duration: Duration(milliseconds: 200));
                  if (widget.onTap != null) {
                    widget.onTap(index);
                  }
                },
              )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == TabType.top) {
      ///顶部 tab bar
      return new Scaffold(
        appBar: new AppBar(
          title: widget.title,
          bottom: new TabBar(
              controller: _tabController,
              tabs: widget.tabItems,
              indicatorColor: widget.indicatorColor),
        ),
        body: new TabBarView(
          controller: _tabController,
          children: widget.tabViews,
        ),
      );
    }

    ///底部tab bar
    return new Scaffold(
        appBar: new AppBar(
          title: widget.title,
        ),
        body: new PageView(
          controller: _pageController,
          children: widget.tabViews,
          onPageChanged: (index) {
            if (!_tabController.indexIsChanging) {
              _tabController.animateTo(index,
                  curve: Curves.linear, duration: Duration(milliseconds: 20));
            }
            widget.onPageChanged?.call(index);
          },
        ),
        bottomNavigationBar: _getBottomNavByType());
  }
}
