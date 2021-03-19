import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/model/RepositoryQL.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

/**
 * 本地已读历史表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class ReadHistoryDbProvider extends BaseDbProvider {
  final String name = 'ReadHistoryV2';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnReadDate = "readDate";
  final String columnData = "data";

  int? id;
  String? fullName;
  int? readDate;
  String? data;

  ReadHistoryDbProvider();

  Map<String, dynamic> toMap(String? fullName, DateTime readDate, String data) {
    Map<String, dynamic> map = {
      columnFullName: fullName,
      columnReadDate: readDate.millisecondsSinceEpoch,
      columnData: data
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  ReadHistoryDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    readDate = map[columnReadDate];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnFullName text not null,
        $columnReadDate int not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  Future _getProvider(Database db, int page) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: [columnId, columnFullName, columnReadDate, columnData],
        limit: Config.PAGE_SIZE,
        offset: (page - 1) * Config.PAGE_SIZE,
        orderBy: "$columnReadDate DESC");
    if (maps.length > 0) {
      return maps;
    }
    return null;
  }

  Future _getProviderInsert(Database db, String? fullName) async {
    List<Map<String, dynamic>> maps = await db.query(
      name,
      columns: [columnId, columnFullName, columnReadDate, columnData],
      where: "$columnFullName = ?",
      whereArgs: [fullName],
    );
    if (maps.length > 0) {
      ReadHistoryDbProvider provider =
          ReadHistoryDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(
      String? fullName, DateTime dateTime, String dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProviderInsert(db, fullName);
    if (provider != null) {
      await db
          .delete(name, where: "$columnFullName = ?", whereArgs: [fullName]);
    }
    return await db.insert(name, toMap(fullName, dateTime, dataMapString));
  }

  ///获取事件数据
  Future<List<RepositoryQL?>?> geData(int page) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, page);
    if (provider != null) {
      List<RepositoryQL?> list = [];
      for (var providerMap in provider) {
        ReadHistoryDbProvider provider =
            ReadHistoryDbProvider.fromMap(providerMap);

        ///使用 compute 的 Isolate 优化 json decode
        var mapData = await compute(CodeUtils.decodeMapResult, provider.data);

        list.add(RepositoryQL.fromMap(mapData));
      }
      return list;
    }
    return null;
  }
}
