import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/UserRedux.dart';
import 'package:gsy_github_app_flutter/common/redux/EventRedux.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';

/**
 * Redux全局State
 * Created by guoshuyu
 * Date: 2018-07-16
 */

class GSYState {

  User userInfo;

  List<EventViewModel> eventList = new List();

  GSYState({this.userInfo, this.eventList});

}


GSYState appReducer(GSYState state, action) {
  return GSYState(
    userInfo: UserReducer(state.userInfo, action),
    eventList: EventReducer(state.eventList, action),
  );
}

