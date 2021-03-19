import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/local/local_storage.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/redux/login_redux.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/widget/animated_background.dart';
import 'package:gsy_github_app_flutter/widget/gsy_flex_button.dart';
import 'package:gsy_github_app_flutter/widget/gsy_input_widget.dart';
import 'package:gsy_github_app_flutter/widget/particle/particle_widget.dart';

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

class _LoginPageState extends State<LoginPage> with LoginBLoC {
  @override
  Widget build(BuildContext context) {
    /// 触摸收起键盘
    return new GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        body: new Container(
          color: Theme.of(context).primaryColor,
          child: Stack(children: <Widget>[
            Positioned.fill(child: AnimatedBackground()),
            Positioned.fill(child: ParticlesWidget(30)),
            new Center(
              ///防止overFlow的现象
              child: SafeArea(
                ///同时弹出键盘不遮挡
                child: SingleChildScrollView(
                  child: new Card(
                    elevation: 5.0,
                    shape: new RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    color: GSYColors.cardWhite,
                    margin: const EdgeInsets.only(left: 30.0, right: 30.0),
                    child: new Padding(
                      padding: new EdgeInsets.only(
                          left: 30.0, top: 40.0, right: 30.0, bottom: 0.0),
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Image(
                              image: new AssetImage(GSYICons.DEFAULT_USER_ICON),
                              width: 90.0,
                              height: 90.0),
                          new Padding(padding: new EdgeInsets.all(10.0)),
                          new GSYInputWidget(
                            hintText: GSYLocalizations.i18n(context)!
                                .login_username_hint_text,
                            iconData: GSYICons.LOGIN_USER,
                            onChanged: (String value) {
                              _userName = value;
                            },
                            controller: userController,
                          ),
                          new Padding(padding: new EdgeInsets.all(10.0)),
                          new GSYInputWidget(
                            hintText: GSYLocalizations.i18n(context)!
                                .login_password_hint_text,
                            iconData: GSYICons.LOGIN_PW,
                            obscureText: true,
                            onChanged: (String value) {
                              _password = value;
                            },
                            controller: pwController,
                          ),
                          new Padding(padding: new EdgeInsets.all(10.0)),
                          Container(
                            height: 50,
                            child: Row(
                              children: <Widget>[
                                new Expanded(
                                  child: new GSYFlexButton(
                                    text: GSYLocalizations.i18n(context)!
                                        .login_text,
                                    color: Theme.of(context).primaryColor,
                                    textColor: GSYColors.textWhite,
                                    fontSize: 16,
                                    onPress: loginIn,
                                  ),
                                ),
                                new SizedBox(
                                  width: 10,
                                ),
                                new Expanded(
                                  child: new GSYFlexButton(
                                    text: GSYLocalizations.i18n(context)!
                                        .oauth_text,
                                    color: Theme.of(context).primaryColor,
                                    textColor: GSYColors.textWhite,
                                    fontSize: 16,
                                    onPress: oauthLogin,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          new Padding(padding: new EdgeInsets.all(15.0)),
                          InkWell(
                            onTap: () {
                              CommonUtils.showLanguageDialog(context);
                            },
                            child: Text(
                              GSYLocalizations.i18n(context)!.switch_language,
                              style: TextStyle(color: GSYColors.subTextColor),
                            ),
                          ),
                          new Padding(padding: new EdgeInsets.all(15.0)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}

mixin LoginBLoC on State<LoginPage> {
  final TextEditingController userController = new TextEditingController();

  final TextEditingController pwController = new TextEditingController();

  String? _userName = "";

  String? _password = "";

  @override
  void initState() {
    super.initState();
    initParams();
  }

  @override
  void dispose() {
    super.dispose();
    userController.removeListener(_usernameChange);
    pwController.removeListener(_passwordChange);
  }

  _usernameChange() {
    _userName = userController.text;
  }

  _passwordChange() {
    _password = pwController.text;
  }

  initParams() async {
    _userName = await LocalStorage.get(Config.USER_NAME_KEY);
    _password = await LocalStorage.get(Config.PW_KEY);
    userController.value = new TextEditingValue(text: _userName ?? "");
    pwController.value = new TextEditingValue(text: _password ?? "");
  }

  loginIn() async {
    Fluttertoast.showToast(
        msg: GSYLocalizations.i18n(context)!.Login_deprecated,
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_LONG);
    return;
    // if (_userName == null || _userName.isEmpty) {
    //   return;
    // }
    // if (_password == null || _password.isEmpty) {
    //   return;
    // }
    //
    // ///通过 redux 去执行登陆流程
    // StoreProvider.of<GSYState>(context)
    //     .dispatch(LoginAction(context, _userName, _password));
  }

  oauthLogin() async {
    String? code = await NavigatorUtils.goLoginWebView(context,
        Address.getOAuthUrl(), "${GSYLocalizations.i18n(context)!.oauth_text}");

    if (code != null && code.length > 0) {
      ///通过 redux 去执行登陆流程
      StoreProvider.of<GSYState>(context).dispatch(OAuthAction(context, code));
    }
  }
}
