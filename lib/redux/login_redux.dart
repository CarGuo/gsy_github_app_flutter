// ignore_for_file: implicit_call_tearoffs, use_build_context_synchronously

import 'package:flutter/material.dart';
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
bool? _loginResult(bool? result, LoginSuccessAction action) {
  if (action.success == true) {
    NavigatorUtils.goHome(action.context);
  }
  return action.success;
}

bool? _logoutResult(bool? result, LogoutAction action) {
  return true;
}

///定一个 LoginSuccessAction ，用于发起 登陆成功后 的改变
///类名随你喜欢定义，只要通过上面TypedReducer 绑定就好
class LoginSuccessAction {
  final BuildContext context;
  final bool success;

  LoginSuccessAction(this.context, this.success);
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
Stream<dynamic> loginEpic(Stream<dynamic> actions, EpicStore<GSYState> store) {
  Stream<dynamic> loginIn(
      LoginAction action, EpicStore<GSYState> store) async* {
    CommonUtils.showLoadingDialog(action.context);
    var nv = Navigator.of(action.context);
    var res = await UserRepository.login(
        action.username!.trim(), action.password!.trim(), store);
    nv.pop(action);
    yield LoginSuccessAction(action.context, (res != null && res.result));
  }
  return actions
      .whereType<LoginAction>()
      .switchMap((action) => loginIn(action, store));
}

///中间过程处理
Stream<dynamic> oauthEpic(Stream<dynamic> actions, EpicStore<GSYState> store) {
  Stream<dynamic> loginIn(
      OAuthAction action, EpicStore<GSYState> store) async* {
    CommonUtils.showLoadingDialog(action.context);
    var res = await UserRepository.oauth(action.code, store);
    Navigator.pop(action.context);
    yield LoginSuccessAction(action.context, (res != null && res.result));
  }
  return actions
      .whereType<OAuthAction>()
      .switchMap((action) => loginIn(action, store));
}
