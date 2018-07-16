import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/DynamicPage.dart';
import 'package:gsy_github_app_flutter/page/MyPage.dart';
import 'package:gsy_github_app_flutter/page/TrendPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';

class HomePage extends StatelessWidget {
  static final String sName = "home";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.BOTTOM_TAB,
        tabItems: [
          new Tab(icon: new Icon(GSYICons.MAIN_DT)),
          new Tab(icon: new Icon(GSYICons.MAIN_QS)),
          new Tab(icon: new Icon(GSYICons.MAIN_MY)),
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
