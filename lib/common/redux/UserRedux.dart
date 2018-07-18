
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:redux/redux.dart';

/**
 * 用户相关Redux
 * Created by guoshuyu
 * Date: 2018-07-16
 */

final UserReducer = combineReducers<User>([
  TypedReducer<User, UpdateUserAction>(_updateLoaded),
]);

User _updateLoaded(User user, action) {
  user = action.userInfo;
  return user;
}

class UpdateUserAction {
  final User userInfo;
  UpdateUserAction(this.userInfo);
}
