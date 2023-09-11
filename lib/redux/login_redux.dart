import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/db/sql_manager.dart';
import 'package:gsy_github_app_flutter/common/dao/user_dao.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'middleware/epic_store.dart';

/**
 * 登录相关Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */
final LoginReducer = combineReducers<bool?>([
  TypedReducer<bool?, LoginSuccessAction>(_loginResult) ,
  TypedReducer<bool?, LogoutAction>(_logoutResult),
]);

bool? _loginResult(bool? result, LoginSuccessAction action) {
  if (action.success == true) {
    NavigatorUtils.goHome(action.context);
  }
  return action.success;
}

bool? _logoutResult(bool? result, LogoutAction action) {
  return true;
}

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

class LoginMiddleware implements MiddlewareClass<GSYState> {
  @override
  void call(Store<GSYState> store, dynamic action, NextDispatcher next) {
    if (action is LogoutAction) {
      UserDao.clearAll(store);
      WebViewCookieManager().clearCookies();
      SqlManager.close();
      NavigatorUtils.goLogin(action.context);
    }
    // Make sure to forward actions to the next middleware in the chain!
    next(action);
  }
}

Stream<dynamic> loginEpic(Stream<dynamic> actions, EpicStore<GSYState> store) {
  Stream<dynamic> _loginIn(
      LoginAction action, EpicStore<GSYState> store) async* {
    CommonUtils.showLoadingDialog(action.context);
    var res = await UserDao.login(
        action.username!.trim(), action.password!.trim(), store);
    Navigator.pop(action.context);
    yield LoginSuccessAction(action.context, (res != null && res.result));
  }
  return actions
      .whereType<LoginAction>()
      .switchMap((action) => _loginIn(action, store));
}

Stream<dynamic> oauthEpic(Stream<dynamic> actions, EpicStore<GSYState> store) {
  Stream<dynamic> _loginIn(
      OAuthAction action, EpicStore<GSYState> store) async* {
    CommonUtils.showLoadingDialog(action.context);
    var res = await UserDao.oauth(action.code, store);
    Navigator.pop(action.context);
    yield LoginSuccessAction(action.context, (res != null && res.result));
  }
  return actions
      .whereType<OAuthAction>()
      .switchMap((action) => _loginIn(action, store));
}
