import 'dart:convert';

import 'package:gsy_github_app_flutter/db/provider/event/received_event_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/event/user_event_db_provider.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/model/Event.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/net/api.dart';

class EventRepository {
  static getEventReceived(String? userName,
      {page = 1, bool needDb = false}) async {
    if (userName == null) {
      return null;
    }
    ReceivedEventDbProvider provider = ReceivedEventDbProvider();

    next() async {
      String url =
          Address.getEventReceived(userName) + Address.getPageParams("?", page);

      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<Event> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return null;
        }
        if (needDb) {
          await provider.insert(json.encode(data));
        }
        for (int i = 0; i < data.length; i++) {
          list.add(Event.fromJson(data[i]));
        }
        return DataResult(list, true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      List<Event>? dbList = await provider.getEvents();
      if (dbList == null || dbList.isEmpty) {
        return await next();
      }
      DataResult dataResult = DataResult(dbList, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// 用户行为事件
  static getEventRequest(userName, {page = 0, bool needDb = false}) async {
    UserEventDbProvider provider = UserEventDbProvider();
    next() async {
      String url =
          Address.getEvent(userName) + Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<Event> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return DataResult(list, true);
        }
        if (needDb) {
          provider.insert(userName, json.encode(data));
        }
        for (int i = 0; i < data.length; i++) {
          list.add(Event.fromJson(data[i]));
        }
        return DataResult(list, true);
      } else {
        return null;
      }
    }

    if (needDb) {
      List<Event>? dbList = await provider.getEvents(userName);
      if (dbList == null || dbList.isEmpty) {
        return await next();
      }
      DataResult dataResult = DataResult(dbList, true, next: next);
      return dataResult;
    }
    return await next();
  }
}
