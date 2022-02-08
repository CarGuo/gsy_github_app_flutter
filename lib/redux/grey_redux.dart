import 'package:redux/redux.dart';

/**
 * 变灰Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */

final GreyReducer = combineReducers<bool>([
  TypedReducer<bool, RefreshGreyAction>(_refresh),
]);

bool _refresh(bool grey, RefreshGreyAction action) {
  return action.grey;
}

class RefreshGreyAction {
  final bool grey;

  RefreshGreyAction(this.grey);
}


