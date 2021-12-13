import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:gsy_github_app_flutter/redux/grey_redux.dart';
import 'package:gsy_github_app_flutter/redux/login_redux.dart';
import 'package:gsy_github_app_flutter/redux/user_redux.dart';
import 'package:gsy_github_app_flutter/redux/theme_redux.dart';
import 'package:gsy_github_app_flutter/redux/locale_redux.dart';
import 'package:redux/redux.dart';

import 'middleware/epic_middleware.dart';

/**
 * Redux全局State
 * Created by guoshuyu
 * Date: 2018-07-16
 */

///全局Redux store 的对象，保存State数据
class GSYState {
  ///用户信息
  User? userInfo;

  ///主题数据
  ThemeData? themeData;

  ///语言
  Locale? locale;

  ///当前手机平台默认语言
  Locale? platformLocale;

  ///是否登录
  bool? login;

  ///是否变灰色
  bool grey;

  ///构造方法
  GSYState(
      {this.userInfo,
      this.themeData,
      this.locale,
      this.login,
      this.grey = false});
}

///创建 Reducer
///源码中 Reducer 是一个方法 typedef State Reducer<State>(State state, dynamic action);
///我们自定义了 appReducer 用于创建 store
GSYState appReducer(GSYState state, action) {
  return GSYState(
    ///通过 UserReducer 将 GSYState 内的 userInfo 和 action 关联在一起
    userInfo: UserReducer(state.userInfo, action),

    ///通过 ThemeDataReducer 将 GSYState 内的 themeData 和 action 关联在一起
    themeData: ThemeDataReducer(state.themeData, action),

    ///通过 LocaleReducer 将 GSYState 内的 locale 和 action 关联在一起
    locale: LocaleReducer(state.locale, action),
    login: LoginReducer(state.login, action),
    ///通过 GreyReducer 将 GSYState 内的 grey 和 action 关联在一起
    grey: GreyReducer(state.grey, action),
  );
}

final List<Middleware<GSYState>> middleware = [
  EpicMiddleware<GSYState>(loginEpic),
  EpicMiddleware<GSYState>(userInfoEpic),
  EpicMiddleware<GSYState>(oauthEpic),
  UserInfoMiddleware(),
  LoginMiddleware(),
];
