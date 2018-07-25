import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/HomePage.dart';
import 'package:gsy_github_app_flutter/page/LoginPage.dart';
import 'package:gsy_github_app_flutter/page/PersonPage.dart';
import 'package:gsy_github_app_flutter/page/WelcomePage.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

void main() {
  runApp(new FlutterReduxApp());
}

class FlutterReduxApp extends StatelessWidget {
  final store = new Store<GSYState>(appReducer,
      initialState: new GSYState(userInfo: User.empty(), eventList: new List()));

  FlutterReduxApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new StoreProvider(
      store: store,
      child: new MaterialApp(
          theme: new ThemeData(
            primarySwatch: GSYColors.primarySwatch,
          ),
          routes: {
            WelcomePage.sName: (context) {
              return WelcomePage();
            },
            HomePage.sName: (context) {
              return HomePage();
            },
            LoginPage.sName: (context) {
              return LoginPage();
            },
          }),
    );
  }
}
