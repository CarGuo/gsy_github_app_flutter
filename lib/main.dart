import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/event/HttpErrorEvent.dart';
import 'package:gsy_github_app_flutter/common/localization/GSYLocalizationsDelegate.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/page/HomePage.dart';
import 'package:gsy_github_app_flutter/page/LoginPage.dart';
import 'package:gsy_github_app_flutter/page/WelcomePage.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:gsy_github_app_flutter/common/net/Code.dart';

void main() {
  runApp(new FlutterReduxApp());
}

class FlutterReduxApp extends StatelessWidget {
  /// 创建Store，引用 GSYState 中的 appReducer 实现 Reducer 方法
  /// initialState 初始化 State
  final store = new Store<GSYState>(
    appReducer,
    ///初始化数据
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
            supportedLocales: [store.state.locale],
            theme: store.state.themeData,
            routes: {
              WelcomePage.sName: (context) {
                store.state.platformLocale = Localizations.localeOf(context);
                return WelcomePage();
              },
              HomePage.sName: (context) {
                return new GSYLocalizations(
                  child: new HomePage(),
                );
              },
              LoginPage.sName: (context) {
                return new GSYLocalizations(
                  child: new LoginPage(),
                );
              },
            });
      }),
    );
  }
}

class GSYLocalizations extends StatefulWidget {
  final Widget child;

  GSYLocalizations({Key key, this.child}) : super(key: key);

  @override
  State<GSYLocalizations> createState() {
    return new _GSYLocalizations();
  }
}

class _GSYLocalizations extends State<GSYLocalizations> {


  StreamSubscription stream;

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

  @override
  void initState() {
    super.initState();
    stream =  Code.eventBus.on<HttpErrorEvent>().listen((event) {
      errorHandleFunction(event.code, event.message);
    });
  }

  @override
  void dispose() {
    super.dispose();
    if(stream != null) {
      stream.cancel();
      stream = null;
    }
  }

  errorHandleFunction(int code, message) {
    switch (code) {
      case Code.NETWORK_ERROR:
        Fluttertoast.showToast(msg: CommonUtils.getLocale(context).network_error);
        break;
      case 401:
        Fluttertoast.showToast(msg: CommonUtils.getLocale(context).network_error_401);
        break;
      case 403:
        Fluttertoast.showToast(msg: CommonUtils.getLocale(context).network_error_403);
        break;
      case 404:
        Fluttertoast.showToast(msg: CommonUtils.getLocale(context).network_error_404);
        break;
      case Code.NETWORK_TIMEOUT:
        //超时
        Fluttertoast.showToast(msg: CommonUtils.getLocale(context).network_error_timeout);
        break;
      default:
        Fluttertoast.showToast(msg: CommonUtils.getLocale(context).network_error_unknown + " " + message);
        break;
    }
  }
}
