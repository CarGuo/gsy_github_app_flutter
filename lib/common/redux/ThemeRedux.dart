import 'package:flutter/material.dart';
import 'package:redux/redux.dart';

/**
 * 事件Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */

final ThemeDataReducer = combineReducers<ThemeData>([
  TypedReducer<ThemeData, RefreshThemeDataAction>(_refresh),
]);

ThemeData _refresh(ThemeData themeData, action) {
  themeData = action.themeData;
  return themeData;
}

class RefreshThemeDataAction {
  final ThemeData themeData;

  RefreshThemeDataAction(this.themeData);
}
