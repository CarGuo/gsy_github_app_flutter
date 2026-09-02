import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/event/http_error_event.dart';
import 'package:gsy_github_app_flutter/common/event/index.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/page/debug/debug_label.dart';
import 'package:gsy_github_app_flutter/page/home/home_page.dart';
import 'package:gsy_github_app_flutter/page/login/login_page.dart';
import 'package:gsy_github_app_flutter/page/photoview_page.dart';
import 'package:gsy_github_app_flutter/page/welcome_page.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:redux/redux.dart';

import 'common/utils/navigator_utils.dart';

/// 顶层 root Navigator key。挂在 [MaterialApp.navigatorKey] 上，
/// 也是 [HttpErrorListener.errorHandleFunction] 拿 context 的入口。
///
/// 之所以放在顶层：`mcp_dart` `vm_service` `evaluate` 是把
/// `expression` 塞进 `targetId` 指向的那条 library 的作用域里求值的，
/// 顶层名字才拿得到；否则必须先抓 Element/State 的 objectId 再绕
/// `_element!.buildContext`。冒烟场景里 `targetId` 传的是
/// `package:gsy_github_app_flutter/app.dart` 这条 library 的 `id`
/// （注意：**不是** `Isolate.rootLibrary`——那个字段指向 isolate 入口
/// `main.dart`，是 Dart VM 里"root library"术语的专用含义，与本文件无关）。
/// 见 [tool/ai/smoke/README.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/README.md)
/// 「触发路由 / 交互（一等公民 = mcp_dart vm_service evaluate）」章节。
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

class FlutterReduxApp extends StatefulWidget {
  const new({super.key});

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

  // Helper method to check if the locale is supported
  Locale _checkSupportedLocale(Locale locale) {
    // Define the supported locales
    const supportedLocales = AppLocalizations.supportedLocales;

    // Check if the requested locale is supported
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return locale;
      }
    }

    // Fall back to English if the locale is not supported
    return const Locale('en', 'US');
  }

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

          // Make sure the locale is supported or fall back to a default one
          final effectiveLocale = _checkSupportedLocale(appLocale);

          /// 使用 flutter_redux 做部分状态共享
          /// 通过 StoreProvider 应用 store
          /// 这里是为了展示使用 flutter_redux 的能力所以使用了多种状态管理
          return StoreProvider(
            store: store,
            child: StoreBuilder<GSYState>(builder: (context, store) {
              Widget app = MaterialApp(
                  navigatorKey: navKey,

                  ///多语言实现代理
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: [effectiveLocale],
                  locale: effectiveLocale,
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
        showToast(context.l10n.network_error);
        break;
      case 401:
        showToast(context.l10n.network_error_401);
        break;
      case 403:
        showToast(context.l10n.network_error_403);
        break;
      case 404:
        showToast(context.l10n.network_error_404);
        break;
      case 422:
        showToast(context.l10n.network_error_422);
        break;
      case Code.NETWORK_TIMEOUT:
        //超时
        showToast(context.l10n.network_error_timeout);
        break;
      case Code.GITHUB_API_REFUSED:
        //Github API 异常
        showToast(context.l10n.github_refused);
        break;
      default:
        showToast(message == null
            ? context.l10n.network_error_unknown
            : "${context.l10n.network_error_unknown} $message");
        break;
    }
  }

}

/// ------------------------------------------------------------------
/// Debug-only smoke 入口
/// ------------------------------------------------------------------
///
/// 这批顶层函数**只在 `kDebugMode` 下工作**，release 构建里立刻早退（打个 log
/// 就走），因此不承担业务逻辑、不改 UI、不入 tree-shake 白名单——它们**只是给
/// `mcp_dart` `vm_service evaluate` 用的操控入口**。
///
/// 姿势：
/// ```
/// mcp_dart vm_service evaluate
///   targetId: <library id of package:gsy_github_app_flutter/app.dart>
///   expression: 'gsySmokeGoIssueDetail("CarGuo", "gsy_github_app_flutter", "938")'
/// ```
///
/// 相比"抓 Element objectId + 绕 `_element!.buildContext` + 拼 NavigatorUtils
/// 完整包名"的老姿势，这里一行搞定，reviewer 复核也直观。
///
/// 详见 [tool/ai/smoke/README.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/README.md)
/// 「触发路由 / 交互（一等公民 = mcp_dart vm_service evaluate）」章节。

/// smoke 入口共用的 push 时机保底：
///
/// `mcp_dart vm_service evaluate` 官方语义（见 Dart VM Service Protocol
/// service.md 与 api.flutter.dev VmService.evaluate 文档）只是把表达式作为
/// 一次 message 排进目标 isolate 的事件循环执行，不承诺执行时
/// `SchedulerBinding.schedulerPhase` 一定是 `idle`：evaluate 可能刚好排在
/// 一次帧的 build/layout/paint/postFrame 尾段之后立即执行，此时同步
/// `Navigator.push` 触发的 `setState` 会命中
/// `WidgetsBinding._handleBuildScheduled` 抛 "Build scheduled during frame"。
///
/// 保底思路只取两条硬事实：
/// 1. 只要当前 `schedulerPhase == idle`，直接同步 `Navigator.push` 完全安全：
///    push 触发的 `setState` 会正常 `scheduleFrame`，下一帧构建 → 正常渲染。
/// 2. 只要当前 `schedulerPhase != idle`，说明**当前一定有一帧在跑**，Flutter
///    保证会 `flushPostFrameCallbacks`，所以 `addPostFrameCallback` 里的
///    动作一定会在**当前帧末尾**跑到，不会 idle 挂死（reviewer 指出的
///    `addPostFrameCallback` 不自动 `scheduleFrame` 的坑在这里被规避掉，
///    因为我们只有在"已经在帧里"才走 postFrame 分支）。
///
/// push 侧异常处理：
/// - 用 `Completer.completeError` 让异常真正沿 `Future` 冒到 evaluate 侧，
///   VM Service 那头会看到 `ErrorRef` 而不是"正常完成的 Future"，避免出现
///   "evaluate 无异常但页面没跳"的假阳性；
/// - 同时用 `FlutterError.reportError` 把异常汇报给全局错误通道，`mcp_dart
///   get_runtime_errors` 能直接捞到，reviewer 冒烟流水不用额外抓栈。
Future<T?> _smokePostFrame<T>(
  String tag,
  Future<T?> Function(BuildContext context) action,
) {
  final context = navKey.currentContext;
  if (context == null) {
    debugPrint('[smoke] $tag: navKey.currentContext is null, app not mounted yet?');
    return Future<T?>.value(null);
  }
  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.idle) {
    try {
      return action(context);
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: s,
        library: 'gsy smoke',
        context: ErrorDescription('while running $tag (idle path)'),
      ));
      return Future<T?>.error(e, s);
    }
  }
  final completer = Completer<T?>();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final ctx = navKey.currentContext;
    if (ctx == null) {
      debugPrint('[smoke] $tag: navKey.currentContext became null in post-frame');
      completer.complete(null);
      return;
    }
    action(ctx).then(completer.complete).catchError((Object e, StackTrace s) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: s,
        library: 'gsy smoke',
        context: ErrorDescription('while running $tag (post-frame path)'),
      ));
      completer.completeError(e, s);
    });
  });
  return completer.future;
}

/// smoke 入口：跳 Issue / PR 详情页（GSY 里 issue 和 pull 复用同一个 detail page）。
///
/// - [owner] / [repo]：GitHub 仓库定位。
/// - [issueNumber]：issue / PR 编号。
/// - 返回值统一 `Future<Object?>`，release 下直接给 `null`。
///
/// 只在 debug 构建生效，release 早退并打日志。
Future<Object?> gsySmokeGoIssueDetail(
  String owner,
  String repo,
  String issueNumber,
) {
  if (!kDebugMode) {
    debugPrint(
      '[smoke] gsySmokeGoIssueDetail ignored in release build ($owner/$repo#$issueNumber)',
    );
    return Future.value(null);
  }
  return _smokePostFrame<Object?>(
    'gsySmokeGoIssueDetail',
    (ctx) => NavigatorUtils.goIssueDetail(ctx, owner, repo, issueNumber),
  );
}

/// smoke 入口：跳仓库详情页。
///
/// 只在 debug 构建生效，release 早退并打日志。
Future<Object?> gsySmokeGoReposDetail(String owner, String repo) {
  if (!kDebugMode) {
    debugPrint(
      '[smoke] gsySmokeGoReposDetail ignored in release build ($owner/$repo)',
    );
    return Future.value(null);
  }
  return _smokePostFrame<Object?>(
    'gsySmokeGoReposDetail',
    (ctx) => NavigatorUtils.goReposDetail(ctx, owner, repo),
  );
}

/// smoke 入口：跳 Discussion 详情页。
///
/// 与 [gsySmokeGoIssueDetail] 并列，走的是 GraphQL 通道。
/// 只在 debug 构建生效，release 早退并打日志。
Future<Object?> gsySmokeGoDiscussionDetail(
  String owner,
  String repo,
  int number,
) {
  if (!kDebugMode) {
    debugPrint(
      '[smoke] gsySmokeGoDiscussionDetail ignored in release build ($owner/$repo#$number)',
    );
    return Future.value(null);
  }
  return _smokePostFrame<Object?>(
    'gsySmokeGoDiscussionDetail',
    (ctx) => NavigatorUtils.goDiscussionDetail(ctx, owner, repo, number),
  );
}

/// smoke 入口：跳个人页。
///
/// 只在 debug 构建生效，release 早退并打日志。
void gsySmokeGoPerson(String userName) {
  if (!kDebugMode) {
    debugPrint(
      '[smoke] gsySmokeGoPerson ignored in release build ($userName)',
    );
    return;
  }
  _smokePostFrame<void>('gsySmokeGoPerson', (ctx) async {
    NavigatorUtils.goPerson(ctx, userName);
  });
}
