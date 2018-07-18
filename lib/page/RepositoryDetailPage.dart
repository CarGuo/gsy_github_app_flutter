import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';

/**
 * 仓库详情
 * Created by guoshuyu
 * Date: 2018-07-18
 */

class RepositoryDetailPage extends StatelessWidget {
  final String reposName;
  final String userName;

  RepositoryDetailPage(this.reposName, this.userName);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.TOP_TAB,
        tabItems: [
          new Tab(text: "222"),
          new Tab(text: "222"),
          new Tab(text: "222"),
          new Tab(text: "222"),
        ],
        tabViews: [
          new Icon(GSYICons.MAIN_DT),
          new Icon(GSYICons.MAIN_DT),
          new Icon(GSYICons.MAIN_DT),
          new Icon(GSYICons.MAIN_DT),
        ],
        backgroundColor: GSYColors.primarySwatch,
        indicatorColor: Colors.white,
        title: GSYStrings.app_name);
  }
}
