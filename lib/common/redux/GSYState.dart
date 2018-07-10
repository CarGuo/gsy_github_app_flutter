import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/UserRedux.dart';

class GSYState {

  User userInfo;

  GSYState({this.userInfo});

}


GSYState appReducer(GSYState state, action) {
  return GSYState(
    userInfo: UserReducer(state.userInfo, action),
  );
}

