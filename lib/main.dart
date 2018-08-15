import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gsy_github_app_flutter/common/localization/GSYLocalizationsDelegate.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/HomePage.dart';
import 'package:gsy_github_app_flutter/page/LoginPage.dart';
import 'package:gsy_github_app_flutter/page/WelcomePage.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

void main() {
  runApp(new FlutterReduxApp());
}

class FlutterReduxApp extends StatelessWidget {
  /// 创建Store，引用 GSYState 中的 appReducer 创建 Reducer
  /// initialState 初始化 State
  final store = new Store<GSYState>(
    appReducer,
    initialState: new GSYState(
        userInfo: User.empty(),
        eventList: new List(),
        trendList: new List(),
        themeData: new ThemeData(
          primarySwatch: GSYColors.primarySwatch,
        ),
        locale: Locale('zh', 'CH')),
  );

  FlutterReduxApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// 通过 StoreProvider 应用 store
    return new StoreProvider(
      store: store,
      child: new StoreBuilder<GSYState>(builder: (context, store) {
        return new MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GSYLocalizationsDelegate.delegate,
            ],
            locale: store.state.locale,
            supportedLocales: [
              store.state.locale
            ],
            theme: store.state.themeData,
            routes: {
              WelcomePage.sName: (context) {
                return WelcomePage();
              },
              HomePage.sName: (context) {
                return new FreeLocalizations(
                  child: new HomePage(),
                );
              },
              LoginPage.sName: (context) {
                return LoginPage();
              },
            });
      }),
    );
  }
}

class FreeLocalizations extends StatefulWidget {
  final Widget child;

  FreeLocalizations({Key key, this.child}) : super(key: key);

  @override
  State<FreeLocalizations> createState() {
    return new _FreeLocalizations();
  }
}

class _FreeLocalizations extends State<FreeLocalizations> {
  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(builder: (context, store) {
      return new Localizations.override(
        context: context,
        locale: store.state.locale,
        child: widget.child,
      );
    });
  }
}
