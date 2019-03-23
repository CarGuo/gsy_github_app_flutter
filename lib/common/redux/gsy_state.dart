import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/model/TrendingRepoModel.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/user_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/event_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/trend_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/theme_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/locale_redux.dart';

/**
 * Redux全局State
 * Created by guoshuyu
 * Date: 2018-07-16
 */

///全局Redux store 的对象，保存State数据
class GSYState {
  ///用户信息
  User userInfo;

  ///用户接受到的事件列表
  List<Event> eventList = new List();

  ///用户接受到的事件列表
  List<TrendingRepoModel> trendList = new List();

  ///主题数据
  ThemeData themeData;

  ///语言
  Locale locale;

  ///当前手机平台默认语言
  Locale platformLocale;

  ///构造方法
  GSYState({this.userInfo, this.eventList, this.trendList, this.themeData, this.locale});
}

///创建 Reducer
///源码中 Reducer 是一个方法 typedef State Reducer<State>(State state, dynamic action);
///我们自定义了 appReducer 用于创建 store
GSYState appReducer(GSYState state, action) {
  return GSYState(
    ///通过 UserReducer 将 GSYState 内的 userInfo 和 action 关联在一起
    userInfo: UserReducer(state.userInfo, action),

    ///通过 EventReducer 将 GSYState 内的 eventList 和 action 关联在一起
    eventList: EventReducer(state.eventList, action),

    ///通过 TrendReducer 将 GSYState 内的 trendList 和 action 关联在一起
    trendList: TrendReducer(state.trendList, action),

    ///通过 ThemeDataReducer 将 GSYState 内的 themeData 和 action 关联在一起
    themeData: ThemeDataReducer(state.themeData, action),

    ///通过 LocaleReducer 将 GSYState 内的 locale 和 action 关联在一起
    locale: LocaleReducer(state.locale, action),
  );
}
