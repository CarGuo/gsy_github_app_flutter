import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/event/http_error_event.dart';
import 'package:gsy_github_app_flutter/common/event/index.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_localizations_delegate.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/page/home/home_page.dart';
import 'package:gsy_github_app_flutter/page/login/login_page.dart';
import 'package:gsy_github_app_flutter/page/welcome_page.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';

import 'common/event/index.dart';
import 'common/utils/navigator_utils.dart';

class FlutterReduxApp extends StatefulWidget {
  @override
  _FlutterReduxAppState createState() => _FlutterReduxAppState();
}

class _FlutterReduxAppState extends State<FlutterReduxApp>
    with HttpErrorListener {
  /// 创建Store，引用 GSYState 中的 appReducer 实现 Reducer 方法
  /// initialState 初始化 State
  final store = new Store<GSYState>(
    appReducer,

    ///拦截器
    middleware: middleware,

    ///初始化数据
    initialState: new GSYState(
        userInfo: User.empty(),
        login: false,
        themeData: CommonUtils.getThemeData(GSYColors.primarySwatch),
        locale: Locale('zh', 'CH')),
  );

  @override
  Widget build(BuildContext context) {
    /// 使用 flutter_redux 做全局状态共享
    /// 通过 StoreProvider 应用 store
    return new StoreProvider(
      store: store,
      child: new StoreBuilder<GSYState>(builder: (context, store) {
        ///使用 StoreBuilder 获取 store 中的 theme 、locale
        store.state.platformLocale =
            WidgetsBinding.instance.window.locale;
        return new MaterialApp(

            ///多语言实现代理
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GSYLocalizationsDelegate.delegate,
            ],
            supportedLocales: [store.state.locale],
            locale: store.state.locale,
            theme: store.state.themeData,

            ///命名式路由
            /// "/" 和 MaterialApp 的 home 参数一个效果
            routes: {
              WelcomePage.sName: (context) {
                return WelcomePage();
              },
              HomePage.sName: (context) {
                return NavigatorUtils.pageContainer(new HomePage());
              },
              LoginPage.sName: (context) {
                return NavigatorUtils.pageContainer(new LoginPage());
              },
            });
      }),
    );
  }
}

abstract class HttpErrorListener extends State<FlutterReduxApp> {
  StreamSubscription stream;

  @override
  void initState() {
    super.initState();

    ///Stream演示event bus
    stream = eventBus.on<HttpErrorEvent>().listen((event) {
      errorHandleFunction(event.code, event.message);
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (stream != null) {
      stream.cancel();
      stream = null;
    }
  }

  ///网络错误提醒
  errorHandleFunction(int code, message) {
    switch (code) {
      case Code.NETWORK_ERROR:
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context).network_error);
        break;
      case 401:
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context).network_error_401);
        break;
      case 403:
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context).network_error_403);
        break;
      case 404:
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context).network_error_404);
        break;
      case Code.NETWORK_TIMEOUT:
        //超时
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context).network_error_timeout);
        break;
      default:
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context).network_error_unknown +
                " " +
                message);
        break;
    }
  }
}
