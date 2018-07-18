import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:redux/redux.dart';

/**
 * 事件Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */

final EventReducer = combineReducers<List<EventViewModel>>([
  TypedReducer<List<EventViewModel>, RefreshEventAction>(_refresh),
  TypedReducer<List<EventViewModel>, LoadMoreEventAction>(_loadMore),
]);

List<EventViewModel> _refresh(List<EventViewModel> list, action) {
  list.clear();
  if (action.list == null) {
    return list;
  } else {
    list.addAll(action.list);
    return list;
  }
}

List<EventViewModel> _loadMore(List<EventViewModel> list, action) {
  if (action.list != null) {
    list.addAll(action.list);
  }
  return list;
}

class RefreshEventAction {
  final List<EventViewModel> list;

  RefreshEventAction(this.list);
}

class LoadMoreEventAction {
  final List<EventViewModel> list;

  LoadMoreEventAction(this.list);
}
