// ignore_for_file: implicit_call_tearoffs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/net/code.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/db/sql_manager.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'middleware/epic_store.dart';

/// 登录相关Redux
/// Created by guoshuyu
/// Date: 2018-07-16

/// redux 的 combineReducers, 通过 TypedReducer 将 LoginSuccessAction、 LogoutAction 与 reducers 关联起来
final LoginReducer = combineReducers<bool?>([
  TypedReducer<bool?, LoginSuccessAction>(_loginResult) ,
  TypedReducer<bool?, LogoutAction>(_logoutResult),
]);

/// 如果有 LoginSuccessAction 发起一个请求时
/// 就会调用到 _loginResult
/// _loginResult 这里接返回结果的同时进行跳转
///
/// 2026-09 修：登录失败必须给 UI 反馈，且要按 statusCode 分类。
/// 之前版本要么静默不弹、要么统一弹 "登录失败，请检查网络或 Token"，
/// 401（Token 不对）也说成 "网络问题"，用户被误导去查网络。
/// 现在按 [LoginSuccessAction.errorCode] 分三档：
///   - 401/403 → 认证失败（Token 无效）
///   - -1/-2/-4 或超时 → 真的网络问题
///   - 其它 → 未知错误兜底
bool? _loginResult(bool? result, LoginSuccessAction action) {
  if (action.success == true) {
    NavigatorUtils.goHome(action.context);
  } else if (action.context.mounted) {
    showToast(_loginFailureMessage(action.context, action.errorCode));
  }
  return action.success;
}

/// 根据网络层带上来的 code 决定具体的错误文案。
///
/// code 语义映射（详见 [Code]）：
/// - 401 / 403：token 无效或权限不够 —— GitHub 判定 Bad credentials
/// - 404：路径/资源不存在（登录场景基本不会遇到，但兜底）
/// - -1 / -2 / -3 / -4：dio 抛出的网络类错误（DNS 挂了、超时、连接被拒、JSON 解析失败）
/// - 其它 / null：说不清就走 unknown
String _loginFailureMessage(BuildContext context, int? code) {
  final l10n = context.l10n;
  if (code == 401 || code == 403) {
    return l10n.login_failed_auth;
  }
  if (code == Code.NETWORK_ERROR ||
      code == Code.NETWORK_TIMEOUT ||
      code == Code.NETWORK_JSON_EXCEPTION ||
      code == Code.GITHUB_API_REFUSED) {
    return l10n.login_failed_network;
  }
  return l10n.login_failed_unknown;
}

bool? _logoutResult(bool? result, LogoutAction action) {
  return true;
}

///定一个 LoginSuccessAction ，用于发起 登陆成功后 的改变
///类名随你喜欢定义，只要通过上面TypedReducer 绑定就好
///
/// 2026-09 新增 [errorCode]：登录失败时把网络层拿到的 statusCode 带上来，
/// 让 reducer 区分"认证失败"和"网络错误"，避免 401 也弹成网络问题误导用户。
class LoginSuccessAction {
  final BuildContext context;
  final bool success;
  final int? errorCode;

  LoginSuccessAction(this.context, this.success, {this.errorCode});
}

class LogoutAction {
  final BuildContext context;

  LogoutAction(this.context);
}

class LoginAction {
  final BuildContext context;
  final String? username;
  final String? password;

  LoginAction(this.context, this.username, this.password);
}

class OAuthAction {
  final BuildContext context;
  final String code;

  OAuthAction(this.context, this.code);
}

/// PAT/token 直接登录 action。
///
/// 与 [OAuthAction] 语义同族：拿到一个"可以直接当 Authorization 头用"的 token，
/// 差别只是 token 来源不同（OAuth webview 拿 code 交换 vs. 用户手输 PAT）。
/// 走独立 epic 只是为了区分 [UserRepository.loginWithToken] 的调用点与失败语义，
/// 让 UI 侧的 loading dialog / toast 都能沿用同一套 [LoginSuccessAction] 分支。
class TokenLoginAction {
  final BuildContext context;
  final String token;

  TokenLoginAction(this.context, this.token);
}

///中间过程处理
class LoginMiddleware implements MiddlewareClass<GSYState> {
  @override
  void call(Store<GSYState> store, dynamic action, NextDispatcher next) {
    if (action is LogoutAction) {
      UserRepository.clearAll(store);
      WebViewCookieManager().clearCookies();
      SqlManager.close();
      NavigatorUtils.goLogin(action.context);
    }
    // Make sure to forward actions to the next middleware in the chain!
    next(action);
  }
}

///中间过程处理
///
/// 2026-09 修：三个登录 epic（[loginEpic] / [oauthEpic] / [tokenLoginEpic]）
/// 之前都是 `showLoading → await repo → Navigator.pop → yield` 的裸流程。
/// 一旦 repository 或 dio 底层抛非 [DioException] 异常（例如 connectivity
/// 插件抛错、Fluttertoast 平台通道异常、SocketException 未捕获等），await
/// 会直接抛，`Navigator.pop` 永不执行，用户就看到 Loading 死转。
///
/// 收敛为通用 helper：`_runLogin(context, work)`
///   - 弹 loading
///   - try/catch：任何异常都吞掉并打 log，不让它穿透
///   - finally：**无条件**关闭 loading，保证 UI 一定不会卡住
///   - 无论成功/失败/异常，都 yield 一个 [LoginSuccessAction]，由 reducer
///     决定后续 UI（跳首页 / 弹失败 toast）
Stream<dynamic> _runLogin(
  BuildContext context,
  Future<dynamic> Function() work,
) async* {
  CommonUtils.showLoadingDialog(context);
  final nv = Navigator.of(context);
  bool success = false;
  int? errorCode;
  try {
    final res = await work();
    success = (res != null && res.result == true);
    // 失败时把网络层带上来的 statusCode 提出来，让 reducer 分类弹 toast：
    // - 401/403 → 认证失败
    // - -1/-2/-4 → 网络错误
    // - 其它 → 未知
    if (!success) {
      errorCode = res?.code as int?;
    }
  } catch (e, s) {
    printLog('login epic caught error: $e\n$s');
    success = false;
    errorCode = null;
  } finally {
    if (nv.canPop()) {
      nv.pop();
    }
  }
  yield LoginSuccessAction(context, success, errorCode: errorCode);
}

Stream<dynamic> loginEpic(Stream<dynamic> actions, EpicStore<GSYState> store) {
  return actions.whereType<LoginAction>().switchMap((action) => _runLogin(
        action.context,
        () => UserRepository.login(
            action.username!.trim(), action.password!.trim(), store),
      ));
}

///中间过程处理
Stream<dynamic> oauthEpic(Stream<dynamic> actions, EpicStore<GSYState> store) {
  return actions.whereType<OAuthAction>().switchMap((action) => _runLogin(
        action.context,
        () => UserRepository.oauth(action.code, store),
      ));
}

/// PAT/token 登录 epic。
///
/// 与 [oauthEpic] 结构一致：显示 loading → 走 repository → 关 loading →
/// 派发 [LoginSuccessAction]。区别只是数据源是用户手输的 token，
/// 而失败时 [UserRepository.loginWithToken] 会自动把不合法的 token 回滚清掉。
Stream<dynamic> tokenLoginEpic(
    Stream<dynamic> actions, EpicStore<GSYState> store) {
  return actions
      .whereType<TokenLoginAction>()
      .switchMap((action) => _runLogin(
            action.context,
            () => UserRepository.loginWithToken(action.token, store),
          ));
}
