import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final store = new Store<GSYState>(appReducer, initialState: new GSYState(userInfo: User.empty(), eventList: new List()));

  FlutterReduxApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new StoreProvider(
      store: store,
      child: new MaterialApp(
          localizationsDelegates: [
            _MaterialLocalizationsDelegate(),
          ],
          supportedLocales: [
            const Locale('zh', 'US'), // English
            // ... other locales the app supports
          ],
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

class GSYMaterialLocalizations extends DefaultMaterialLocalizations {
  const GSYMaterialLocalizations();

  @override
  String get viewLicensesButtonLabel => GSYStrings.app_licenses;

  String get closeButtonLabel => GSYStrings.app_close;
}

class _MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'zh';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return new SynchronousFuture<MaterialLocalizations>(const GSYMaterialLocalizations());
  }

  @override
  bool shouldReload(_MaterialLocalizationsDelegate old) => false;
}
