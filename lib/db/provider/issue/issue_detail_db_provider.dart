import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_detail_db_provider.dart';
import 'package:gsy_github_app_flutter/model/Issue.dart';
import 'package:sqflite/sqflite.dart';

/**
 * issue详情表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class IssueDetailDbProvider extends BaseDbProvider {
  final String name = 'IssueDetail';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnNumber = "number";
  final String columnData = "data";

  int? id;
  String? fullName;
  String? number;
  String? data;

  IssueDetailDbProvider();

  Map<String, dynamic> toMap(String? fullName, String number, String data) {
    Map<String, dynamic> map = {
      columnFullName: fullName,
      columnData: data,
      columnNumber: number
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  IssueDetailDbProvider.fromMap(Map map) {
    id = map[columnId];
    number = map[columnNumber];
    fullName = map[columnFullName];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnFullName text not null,
        $columnNumber text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  Future _getProvider(Database db, String? fullName, String number) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: [columnId, columnFullName, columnNumber, columnData],
        where: "$columnFullName = ? and $columnNumber = ?",
        whereArgs: [fullName, number]);
    if (maps.length > 0) {
      RepositoryDetailDbProvider provider =
          RepositoryDetailDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? fullName, String number, String dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, fullName, number);
    if (provider != null) {
      await db.delete(name,
          where: "$columnFullName = ? and $columnNumber = ?",
          whereArgs: [fullName, number]);
    }
    return await db.insert(name, toMap(fullName, number, dataMapString));
  }

  ///获取详情
  Future<Issue?> getRepository(String? fullName, String number) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, fullName, number);
    if (provider != null) {
      ///使用 compute 的 Isolate 优化 json decode
      var mapData =
          await compute(CodeUtils.decodeMapResult, provider.data as String?);
      return Issue.fromJson(mapData);
    }
    return null;
  }
}
