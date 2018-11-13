import 'package:flutter/material.dart';

///支持顶部和顶部的TabBar控件
///配合AutomaticKeepAliveClientMixin可以keep住
class GSYTabBarWidget extends StatefulWidget {
  ///底部模式type
  static const int BOTTOM_TAB = 1;

  ///顶部模式type
  static const int TOP_TAB = 2;

  final int type;

  final List<Widget> tabItems;

  final List<Widget> tabViews;

  final Color backgroundColor;

  final Color indicatorColor;

  final Widget title;

  final Widget drawer;

  final Widget floatingActionButton;

  final TarWidgetControl tarWidgetControl;

  final PageController topPageControl;

  final ValueChanged<int> onPageChanged;

  GSYTabBarWidget({
    Key key,
    this.type,
    this.tabItems,
    this.tabViews,
    this.backgroundColor,
    this.indicatorColor,
    this.title,
    this.drawer,
    this.floatingActionButton,
    this.tarWidgetControl,
    this.topPageControl,
    this.onPageChanged,
  }) : super(key: key);

  @override
  _GSYTabBarState createState() => new _GSYTabBarState(
    type,
    tabViews,
    indicatorColor,
    title,
    drawer,
    floatingActionButton,
    tarWidgetControl,
    topPageControl,
    onPageChanged,
  );
}

class _GSYTabBarState extends State<GSYTabBarWidget> with SingleTickerProviderStateMixin {
  final int _type;

  final List<Widget> _tabViews;

  final Color _indicatorColor;

  final Widget _title;

  final Widget _drawer;

  final Widget _floatingActionButton;

  final TarWidgetControl _tarWidgetControl;

  final PageController _pageController;

  final ValueChanged<int> _onPageChanged;

  _GSYTabBarState(
      this._type,
      this._tabViews,
      this._indicatorColor,
      this._title,
      this._drawer,
      this._floatingActionButton,
      this._tarWidgetControl,
      this._pageController,
      this._onPageChanged,
      ) : super();

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: widget.tabItems.length);
  }

  ///整个页面dispose时，记得把控制器也dispose掉，释放内存
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (this._type == GSYTabBarWidget.TOP_TAB) {
      ///顶部tab bar
      return new Scaffold(
        floatingActionButton: _floatingActionButton,
        persistentFooterButtons: _tarWidgetControl == null ? [] : _tarWidgetControl.footerButton,
        appBar: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: _title,
          bottom: new TabBar(
            controller: _tabController,
            tabs: widget.tabItems,
            indicatorColor: _indicatorColor,
          ),
        ),
        body: new PageView(
          controller: _pageController,
          children: _tabViews,
          onPageChanged: (index) {
            _tabController.animateTo(index);
            _onPageChanged?.call(index);
          },
        ),
      );
    }

    ///底部tab bar
    return new Scaffold(
        drawer: _drawer,
        appBar: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: _title,
        ),
        body: new TabBarView(
          //TabBarView呈现内容，因此放到Scaffold的body中
            controller: _tabController, //配置控制器
            children: _tabViews),
        bottomNavigationBar: new Material(
          //为了适配主题风格，包一层Material实现风格套用
          color: Theme.of(context).primaryColor, //底部导航栏主题颜色
          child: new TabBar(
            //TabBar导航标签，底部导航放到Scaffold的bottomNavigationBar中
            controller: _tabController, //配置控制器
            tabs: widget.tabItems,
            indicatorColor: _indicatorColor, //tab标签的下划线颜色
          ),
        ));
  }
}

class TarWidgetControl {
  List<Widget> footerButton = [];
}
