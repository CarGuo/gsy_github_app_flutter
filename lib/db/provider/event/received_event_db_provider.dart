import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/Event.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 用户接受事件表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class ReceivedEventDbProvider extends BaseDbProvider {
  final String name = 'ReceivedEvent';

  final String columnId = "_id";
  final String columnData = "data";

  int? id;
  String? data;

  ReceivedEventDbProvider();

  Map<String, dynamic> toMap(String eventMapString) {
    Map<String, dynamic> map = {columnData: eventMapString};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  ReceivedEventDbProvider.fromMap(Map map) {
    id = map[columnId];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  ///插入到数据库
  Future insert(String eventMapString) async {
    Database db = await getDataBase();

    ///清空后再插入，因为只保存第一页面
    db.execute("delete from $name");
    return await db.insert(name, toMap(eventMapString));
  }

  ///获取事件数据
  Future<List<Event>>? getEvents() async {
    Database db = await getDataBase();
    List<Map> maps = await db.query(name, columns: [columnId, columnData]);
    List<Event> list = [];
    if (maps.length > 0) {
      ReceivedEventDbProvider provider =
          ReceivedEventDbProvider.fromMap(maps.first);

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data);

      list = await compute(decodeMapToObject, eventMap);
    }
    return list;
  }

  static List<Event> decodeMapToObject(List<dynamic> mapList) {
    List<Event> list = [];
    for (var item in mapList) {
      list.add(Event.fromJson(item));
    }
    return list;
  }
}
