import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/page/DynamicPage.dart';
import 'package:gsy_github_app_flutter/page/MyPage.dart';
import 'package:gsy_github_app_flutter/page/TrendPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/widget/HomeDrawer.dart';

/**
 * 主页
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class HomePage extends StatelessWidget {
  static final String sName = "home";

  /// 单击提示退出
  Future<bool> _dialogExitApp(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
              content: new Text(GSYStrings.app_back_tip),
              actions: <Widget>[
                new FlatButton(onPressed: () => Navigator.of(context).pop(false), child: new Text(GSYStrings.app_cancel)),
                new FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: new Text(GSYStrings.app_ok))
              ],
            ));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return _dialogExitApp(context);
      },
      child: new GSYTabBarWidget(
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
        title: GSYTitleBar(
          GSYStrings.app_name,
          iconData: GSYICons.MAIN_SEARCH,
          needRightLocalIcon: true,
          onPressed: () {
            NavigatorUtils.goSearchPage(context);
          },
        ),
      ),
    );
  }
}
