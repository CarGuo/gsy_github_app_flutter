import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/redux/login_redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with LoginBLoC {
  @override
  Widget build(BuildContext context) {
    ///共享 store
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        /// 触摸收起键盘
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        ///使用主题颜色做背景
        body: Container(
          color: Theme.of(context).primaryColor,
          child: Center(
            ///同时弹出键盘不遮挡
            child: SingleChildScrollView(
              ///显示卡片
              child: Card(
                elevation: 5.0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                color: Colors.white,
                margin: const EdgeInsets.only(left: 30.0, right: 30.0),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 30.0, top: 40.0, right: 30.0, bottom: 0.0),

                  ///内容
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Padding(padding: EdgeInsets.all(10.0)),

                      ///用户名输入框
                      TextField(
                        controller: userController,
                        decoration: const InputDecoration(
                          hintText: "请输入用户名",
                          icon: Icon(Icons.person),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(30.0)),

                      ///密码输入框
                      TextField(
                        controller: pwController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            hintText: "请输入密码", icon: Icon(Icons.person)),
                      ),

                      const Padding(padding: EdgeInsets.all(15.0)),

                      ///登陆按键
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            height: 40,
                            width: constraints.maxWidth,
                            child: TextButton(
                                style: TextButton.styleFrom(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    backgroundColor:
                                        Theme.of(context).primaryColor),
                                child: const Text("登陆",
                                    style: TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                onPressed: loginIn),
                          );
                        },
                      ),
                      const Padding(padding: EdgeInsets.all(15.0)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

mixin LoginBLoC on State<LoginPage> {
  final TextEditingController userController = TextEditingController();

  final TextEditingController pwController = TextEditingController();

  String? _userName = "";

  String? _password = "";

  @override
  void initState() {
    super.initState();
    _initState();
    userController.addListener(_usernameChange);
    pwController.addListener(_passwordChange);
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

  _initState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userName = await (prefs.get("username") as Future<String?>);
    _password = await (prefs.get("password") as Future<String?>);
    userController.value = TextEditingValue(text: _userName ?? "");
    pwController.value = TextEditingValue(text: _password ?? "");
  }

  loginIn() async {
    if (_userName == null || _userName!.isEmpty) {
      return;
    }
    if (_password == null || _password!.isEmpty) {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", _userName!);
    await prefs.setString("password", _password!);

    ///通过 redux 去执行登陆流程
    StoreProvider.of<GSYState>(context)
        .dispatch(LoginAction(context, _userName, _password));
  }
}
