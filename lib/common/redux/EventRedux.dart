import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:redux/redux.dart';

/**
 * 事件Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */

final EventReducer = combineReducers<List<Event>>([
  TypedReducer<List<Event>, RefreshEventAction>(_refresh),
  TypedReducer<List<Event>, LoadMoreEventAction>(_loadMore),
]);

List<Event> _refresh(List<Event> list, action) {
  list.clear();
  if (action.list == null) {
    return list;
  } else {
    list.addAll(action.list);
    return list;
  }
}

List<Event> _loadMore(List<Event> list, action) {
  if (action.list != null) {
    list.addAll(action.list);
  }
  return list;
}

class RefreshEventAction {
  final List<Event> list;

  RefreshEventAction(this.list);
}

class LoadMoreEventAction {
  final List<Event> list;

  LoadMoreEventAction(this.list);
}
