import 'package:gsy_github_app_flutter/common/model/TrendingRepoModel.dart';
import 'package:redux/redux.dart';

/**
 * 事件Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */

final TrendReducer = combineReducers<List<TrendingRepoModel>>([
  TypedReducer<List<TrendingRepoModel>, RefreshTrendAction>(_refresh),
]);

List<TrendingRepoModel> _refresh(List<TrendingRepoModel> list, action) {
  list.clear();
  if (action.list == null) {
    return list;
  } else {
    list.addAll(action.list);
    return list;
  }
}

class RefreshTrendAction {
  final List<TrendingRepoModel> list;

  RefreshTrendAction(this.list);
}
