import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/page/HomePage.dart';
import 'package:gsy_github_app_flutter/page/LoginPage.dart';
import 'package:gsy_github_app_flutter/page/PersonPage.dart';

class NavigatorUtils {
  static pushReplacementNamed(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static pushNamed(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  static goHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, HomePage.sName);
  }

  static goLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, LoginPage.sName);
  }

  static goPerson(BuildContext context, String userName) {
    Navigator.push(context, new MaterialPageRoute(builder: (context) => new PersonPage(userName)));
  }
}
