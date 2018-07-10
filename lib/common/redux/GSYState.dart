import 'package:gsy_github_app_flutter/common/model/User.dart';

class GSYState {
  User userInfo;
  GSYState({this.userInfo});
}

// One simple action: Increment
class UserActions {
  final User userInfo;
  UserActions(this.userInfo);
}

GSYState counterReducer(GSYState state, dynamic action) {
  if (action is UserActions) {
    state.userInfo = action.userInfo;
  }
  return state;
}

