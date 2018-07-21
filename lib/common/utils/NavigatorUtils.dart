import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/page/HomePage.dart';
import 'package:gsy_github_app_flutter/page/IssueDetailPage.dart';
import 'package:gsy_github_app_flutter/page/LoginPage.dart';
import 'package:gsy_github_app_flutter/page/PersonPage.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailPage.dart';

/**
 * 导航栏
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class NavigatorUtils {
  ///替换
  static pushReplacementNamed(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  ///切换无参数页面
  static pushNamed(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  ///主页
  static goHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, HomePage.sName);
  }

  ///登录页
  static goLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, LoginPage.sName);
  }

  ///个人中心
  static goPerson(BuildContext context, String userName) {
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new PersonPage(userName)));
  }

  ///仓库详情
  static goReposDetail(BuildContext context, String userName, String reposName) {
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new RepositoryDetailPage(userName, reposName)));
  }

  ///issue详情
  static goIssueDetail(BuildContext context, String userName, String reposName, String num) {
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new IssueDetailPage(userName, reposName, num)));
  }
}
