import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/event/http_error_event.dart';
import 'package:gsy_github_app_flutter/common/event/index.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/localization/gsy_localizations_delegate.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:gsy_github_app_flutter/page/debug/debug_label.dart';
import 'package:gsy_github_app_flutter/page/home/home_page.dart';
import 'package:gsy_github_app_flutter/page/login/login_page.dart';
import 'package:gsy_github_app_flutter/page/photoview_page.dart';
import 'package:gsy_github_app_flutter/page/welcome_page.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:redux/redux.dart';

import 'common/utils/navigator_utils.dart';

class FlutterReduxApp extends StatefulWidget {
  const FlutterReduxApp({super.key});

  @override
  _FlutterReduxAppState createState() => _FlutterReduxAppState();
}

class _FlutterReduxAppState extends State<FlutterReduxApp>
    with HttpErrorListener {
  /// 创建Store，引用 GSYState 中的 appReducer 实现 Reducer 方法
  /// initialState 初始化 State
  final store = Store<GSYState>(
    appReducer,

    ///拦截器
    middleware: middleware,

    ///初始化数据
    initialState: GSYState(
      userInfo: User.empty(),
      login: false,
    ),
  );

  NavigatorObserver navigatorObserver = NavigatorObserver();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 0), () {
      /// 通过 with NavigatorObserver ，在这里可以获取可以往上获取到
      /// MaterialApp 和 StoreProvider 的 context
      /// 还可以获取到 navigator;
      /// 比如在这里增加一个监听，如果 token 失效就退回登陆页。
      navigatorObserver.navigator!.context;
      navigatorObserver.navigator;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 使用 riverpod 做部分状态共享
    /// 这里是为了展示使用 riverpod 的能力所以使用了多种状态管理
    return UncontrolledProviderScope(
      container: globalContainer,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final (greyApp, appLocale, themeData) = ref.watch(appStateProvider);

          /// 使用 flutter_redux 做部分状态共享
          /// 通过 StoreProvider 应用 store
          /// 这里是为了展示使用 flutter_redux 的能力所以使用了多种状态管理
          return StoreProvider(
            store: store,
            child: StoreBuilder<GSYState>(builder: (context, store) {
              Widget app = MaterialApp(
                  navigatorKey: navKey,

                  ///多语言实现代理
                  localizationsDelegates: [
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GSYLocalizationsDelegate.delegate,
                  ],
                  supportedLocales: [appLocale],
                  locale: appLocale,
                  theme: themeData,
                  navigatorObservers: [navigatorObserver],

                  ///命名式路由
                  /// "/" 和 MaterialApp 的 home 参数一个效果
                  ///⚠️ 这里的 name调用，里面 pageContainer 方法有一个 MediaQuery.of(context).copyWith(textScaleFactor: 1),
                  ///⚠️ 而这里的 context 用的是 WidgetBuilder 的 context  ～
                  ///⚠️ 所以 MediaQuery.of(context) 这个 InheritedWidget 就把这个 context “登记”到了 Element 的内部静态 _map 里。
                  ///⚠️ 所以键盘弹出来的时候，触发了顶层的 MediaQueryData 发生变化，自然就触发了“登记”过的 context 的变化
                  ///⚠️ 比如 LoginPage 、HomePage ····
                  ///⚠️ 所以比如你在 搜索页面 键盘弹出时，下面的 HomePage.sName 对应的 WidgetBuilder 会被触发
                  ///⚠️ 这个是我故意的，如果不需要，可以去掉 pageContainer 或者不要用这里的 context
                  routes: {
                    WelcomePage.sName: (context) {
                      DebugLabel.showDebugLabel(context);
                      return const WelcomePage();
                    },
                    HomePage.sName: (context) {
                      return NavigatorUtils.pageContainer(
                          const HomePage(), context);
                    },
                    LoginPage.sName: (context) {
                      return NavigatorUtils.pageContainer(
                          const LoginPage(), context);
                    },

                    ///使用 ModalRoute.of(context).settings.arguments; 获取参数
                    PhotoViewPage.sName: (context) {
                      return const PhotoViewPage();
                    },
                  });

              if (greyApp) {
                ///mode one
                app = ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                    child: app);

                ///mode two
                // app = ColorFiltered(
                //     colorFilter: greyscale,
                //     child: app);
              }

              return app;
            }),
          );
        },
      ),
    );
  }
}

mixin HttpErrorListener on State<FlutterReduxApp> {
  StreamSubscription? stream;

  GlobalKey<NavigatorState> navKey = GlobalKey();

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
      stream!.cancel();
      stream = null;
    }
  }

  ///网络错误提醒
  errorHandleFunction(int? code, message) {
    var context = navKey.currentContext!;
    switch (code) {
      case Code.NETWORK_ERROR:
        showToast(GSYLocalizations.i18n(context)!.network_error);
        break;
      case 401:
        showToast(GSYLocalizations.i18n(context)!.network_error_401);
        break;
      case 403:
        showToast(GSYLocalizations.i18n(context)!.network_error_403);
        break;
      case 404:
        showToast(GSYLocalizations.i18n(context)!.network_error_404);
        break;
      case 422:
        showToast(GSYLocalizations.i18n(context)!.network_error_422);
        break;
      case Code.NETWORK_TIMEOUT:
        //超时
        showToast(GSYLocalizations.i18n(context)!.network_error_timeout);
        break;
      case Code.GITHUB_API_REFUSED:
        //Github API 异常
        showToast(GSYLocalizations.i18n(context)!.github_refused);
        break;
      default:
        showToast(
            "${GSYLocalizations.i18n(context)!.network_error_unknown} $message");
        break;
    }
  }

  showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_LONG);
  }
}
