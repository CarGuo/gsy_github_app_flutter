import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:redux/redux.dart';

/**
 * 欢迎页
 * Created by guoshuyu
 * Date: 2018-07-16
 */

class WelcomePage extends StatefulWidget {
  static final String sName = "/";

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>  {

  bool hadInit = false;
  
  Future<Null> _navigator() async {
    ///防止多次进入
    Store<GSYState> store = StoreProvider.of(context);
    CommonUtils.initStatusBarHeight(context);
    final res = await UserDao.initUserInfo(store);
    if (res != null && res.result) {
      NavigatorUtils.goHome(context);
    } else {
      NavigatorUtils.goLogin(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!hadInit) {
      hadInit = true;

      ///防止多次进入
      _navigator();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<GSYState>(
      builder: (context, store) {
        return new Container(
          color: Color(GSYColors.white),
          child: new Center(
            child: new Image(image: new AssetImage('static/images/welcome.png')),
          ),
        );
      },
    );
  }

}
