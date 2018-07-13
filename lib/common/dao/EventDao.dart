import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:redux/redux.dart';

class EventDao {
  static getEventReceived(Store<GSYState> store, {page = 0, callback}) async {
    User user = store.state.userInfo;
    if (user == null || user.login == null) {
      if (callback != null) {
        callback(null);
      }
      return;
    }
    String userName = user.login;
    String url = Address.getEventReceived(userName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      print("yyyyyyyyyyyyyyyyyyyy");
      print(res.data.toString());
    } else {
      if (callback != null) {
        callback(null);
      }
    }
  }
}
