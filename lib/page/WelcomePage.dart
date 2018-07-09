import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/page/HomePage.dart';
import 'package:gsy_github_app_flutter/page/LoginPage.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    toNext(res) {
      Widget widget;
      if (res != null && res.result) {
        widget = new HomePage();
      } else {
        widget = new LoginPage();
      }
      Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) {
        //判断是去登录还是主页
        return widget;
      }));
    }
    // 一秒以后将任务添加至event队列
    new Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) {
        //判断是去登录还是主页
        return new LoginPage();
      }));
    });

    return new Container(
      color: Colors.white,
      child: new Center(
        child: new Text("Welcome", style: new TextStyle(color: Colors.black, fontSize: 22.0)),
      ),
    );
  }
}
