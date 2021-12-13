import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/Event.dart';
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

  int? id;
  String? userName;
  String? data;

  UserEventDbProvider();

  Map<String, dynamic> toMap(String? userName, String eventMapString) {
    Map<String, dynamic> map = {
      columnUserName: userName,
      columnData: eventMapString
    };
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

  Future _getProvider(Database db, String? userName) async {
    List<Map> maps = await db.query(name,
        columns: [columnId, columnData, columnUserName],
        where: "$columnUserName = ?",
        whereArgs: [userName]);
    if (maps.length > 0) {
      UserEventDbProvider provider = UserEventDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? userName, String eventMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, userName);
    if (provider != null) {
      await db
          .delete(name, where: "$columnUserName = ?", whereArgs: [userName]);
    }
    return await db.insert(name, toMap(userName, eventMapString));
  }

  ///获取事件数据
  Future<List<Event>?> getEvents(userName) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, userName);
    if (provider != null) {
      List<Event> list = [];

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data as String?);

      list = await compute(decodeMapToObject, eventMap);

      return list;
    }
    return null;
  }

  static List<Event> decodeMapToObject(List<dynamic> mapList) {
    List<Event> list = [];
    for (var item in mapList) {
      list.add(Event.fromJson(item));
    }
    return list;
  }
}
