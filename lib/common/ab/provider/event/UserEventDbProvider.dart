import 'dart:async';
import 'dart:convert';

import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 用户动态表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class UserEventDbProvider extends BaseDbProvider {
  final String name = 'UserEvent';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  UserEventDbProvider();

  Map<String, dynamic> toMap(String userName, String eventMapString) {
    Map<String, dynamic> map = {columnUserName: userName, columnData: eventMapString};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserEventDbProvider.fromMap(Map map) {
    id = map[columnId];
    userName = map[columnUserName];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnUserName text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  ///插入到数据库
  Future insert(String userName, String eventMapString) async {
    Database db = await getDataBase();

    ///清空后再插入，因为只保存第一页面
    db.execute("delete from $name");
    return await db.insert(name, toMap(userName, eventMapString));
  }

  ///获取事件数据
  Future<List<Event>> getEvents() async {
    Database db = await getDataBase();
    List<Map> maps = await db.query(name, columns: [columnId, columnData]);
    List<Event> list = new List();
    if (maps.length > 0) {
      UserEventDbProvider provider = UserEventDbProvider.fromMap(maps.first);
      List<dynamic> eventMap = json.decode(provider.data);
      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(Event.fromJson(item));
        }
      }
    }
    return list;
  }
}
