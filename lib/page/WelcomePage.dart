import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';

class WelcomePage extends StatelessWidget {
  static final String sName = "/";

  @override
  Widget build(BuildContext context) {
    toNext(res) {
      if (res != null && res.result) {
        NavigatorUtils.goHome(context);
      } else {
        NavigatorUtils.goLogin(context);
      }
    }

    return StoreBuilder<GSYState>(
      builder: (context, store) {
        new Future.delayed(const Duration(seconds: 2), () {
          UserDao.initUserInfo(store).then((res) {
            toNext(res);
          });
        });
        return new Container(
          color: Colors.white,
          child: new Center(
            child: new Text("Welcome",
                style: new TextStyle(color: Colors.black, fontSize: 22.0)),
          ),
        );
      },
    );
  }
}
