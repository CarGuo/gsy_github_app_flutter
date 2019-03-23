import 'dart:convert';

import 'package:gsy_github_app_flutter/common/ab/provider/event/received_event_db_provider.dart';
import 'package:gsy_github_app_flutter/common/ab/provider/event/user_event_db_provider.dart';
import 'package:gsy_github_app_flutter/common/dao/dao_result.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/net/api.dart';
import 'package:gsy_github_app_flutter/common/redux/event_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/gsy_state.dart';
import 'package:redux/redux.dart';

class EventDao {
  static getEventReceived(Store<GSYState> store, {page = 1, bool needDb = false}) async {
    User user = store.state.userInfo;
    if (user == null || user.login == null) {
      return null;
    }
    ReceivedEventDbProvider provider = new ReceivedEventDbProvider();
    if(needDb) {
      List<Event> dbList = await provider.getEvents();
      if (dbList.length > 0) {
        store.dispatch(new RefreshEventAction(dbList));
      }
    }
    String userName = user.login;
    String url = Address.getEventReceived(userName) + Address.getPageParams("?", page);

    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<Event> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return null;
      }
      if(needDb) {
        await provider.insert(json.encode(data));
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Event.fromJson(data[i]));
      }
      if (page == 1) {
        store.dispatch(new RefreshEventAction(list));
      } else {
        store.dispatch(new LoadMoreEventAction(list));
      }
      return list;
    } else {
      return null;
    }
  }

  /**
   * 用户行为事件
   */
  static getEventDao(userName, {page = 0, bool needDb = false}) async {
    UserEventDbProvider provider = new UserEventDbProvider();
    next() async {
      String url = Address.getEvent(userName) + Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<Event> list = new List();
        var data = res.data;
        if (data == null || data.length == 0) {
          return new DataResult(list, true);
        }
        if(needDb) {
          provider.insert(userName, json.encode(data));
        }
        for (int i = 0; i < data.length; i++) {
          list.add(Event.fromJson(data[i]));
        }
        return new DataResult(list, true);
      } else {
        return null;
      }
    }
    if(needDb) {
      List<Event> dbList = await provider.getEvents(userName);
      if(dbList == null || dbList.length == 0) {
        return await next();
      }
      DataResult dataResult = new DataResult(dbList, true, next: next());
      return dataResult;
    }
    return await next();
  }

  static clearEvent(Store store) {
    store.state.eventList.clear();
    store.dispatch(new RefreshEventAction([]));
  }
}
