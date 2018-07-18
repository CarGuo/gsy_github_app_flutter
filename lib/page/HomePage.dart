import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/DynamicPage.dart';
import 'package:gsy_github_app_flutter/page/MyPage.dart';
import 'package:gsy_github_app_flutter/page/TrendPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';
import 'package:gsy_github_app_flutter/widget/HomeDrawer.dart';

class HomePage extends StatelessWidget {
  static final String sName = "home";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new GSYTabBarWidget(
        drawer: new HomeDrawer(),
        type: GSYTabBarWidget.BOTTOM_TAB,
        tabItems: [
          new Tab(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[new Icon(GSYICons.MAIN_DT, size: 16.0), new Text(GSYStrings.home_dynamic)],
            ),
          ),
          new Tab(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[new Icon(GSYICons.MAIN_QS, size: 16.0), new Text(GSYStrings.home_trend)],
            ),
          ),
          new Tab(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[new Icon(GSYICons.MAIN_MY, size: 16.0), new Text(GSYStrings.home_my)],
            ),
          ),
        ],
        tabViews: [
          new DynamicPage(),
          new TrendPage(),
          new MyPage(),
        ],
        backgroundColor: GSYColors.primarySwatch,
        indicatorColor: Colors.white,
        title: GSYStrings.app_name);
  }
}
