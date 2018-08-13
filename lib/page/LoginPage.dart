import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/local/LocalStorage.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYFlexButton.dart';
import 'package:gsy_github_app_flutter/widget/GSYInputWidget.dart';

/**
 * 登录页
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class LoginPage extends StatefulWidget {
  static final String sName = "login";

  @override
  State createState() {
    return new _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  var _userName = "";

  var _password = "";

  final TextEditingController userController = new TextEditingController();
  final TextEditingController pwController = new TextEditingController();

  _LoginPageState() : super();

  @override
  void initState() {
    super.initState();
    initParams();
  }

  initParams() async {
    _userName = await LocalStorage.get(Config.USER_NAME_KEY);
    _password = await LocalStorage.get(Config.PW_KEY);
    userController.value = new TextEditingValue(text: _userName ?? "");
    pwController.value = new TextEditingValue(text: _password ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(builder: (context, store) {
      return new GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: new Container(
          color: Theme.of(context).primaryColor,
          child: new Center(
            child: new Card(
              elevation: 5.0,
              shape: new RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
              color: Color(GSYColors.cardWhite),
              margin: const EdgeInsets.all(30.0),
              child: new Padding(
                padding: new EdgeInsets.only(left: 30.0, top: 40.0, right: 30.0, bottom: 80.0),
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Image(image: new AssetImage(GSYICons.DEFAULT_USER_ICON), width: 90.0, height: 90.0),
                    new Padding(padding: new EdgeInsets.all(10.0)),
                    new GSYInputWidget(
                      hintText: GSYStrings.login_username_hint_text,
                      iconData: GSYICons.LOGIN_USER,
                      onChanged: (String value) {
                        _userName = value;
                      },
                      controller: userController,
                    ),
                    new Padding(padding: new EdgeInsets.all(10.0)),
                    new GSYInputWidget(
                      hintText: GSYStrings.login_password_hint_text,
                      iconData: GSYICons.LOGIN_PW,
                      obscureText: true,
                      onChanged: (String value) {
                        _password = value;
                      },
                      controller: pwController,
                    ),
                    new Padding(padding: new EdgeInsets.all(30.0)),
                    new GSYFlexButton(
                      text: GSYStrings.login_text,
                      color: Theme.of(context).primaryColor,
                      textColor: Color(GSYColors.textWhite),
                      onPress: () {
                        if (_userName == null || _userName.length == 0) {
                          return;
                        }
                        if (_password == null || _password.length == 0) {
                          return;
                        }
                        CommonUtils.showLoadingDialog(context);
                        UserDao.login(_userName.trim(), _password.trim(), store).then((res) {
                          Navigator.pop(context);
                          if (res != null && res.result) {
                            new Future.delayed(const Duration(seconds: 1), () {
                              NavigatorUtils.goHome(context);
                              return true;
                            });
                          }
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
