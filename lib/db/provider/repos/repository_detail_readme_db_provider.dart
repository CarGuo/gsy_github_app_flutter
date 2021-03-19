import 'dart:async';

import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 仓库readme文件表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class RepositoryDetailReadmeDbProvider extends BaseDbProvider {
  final String name = 'RepositoryDetailReadme';
  int? id;
  String? fullName;
  String? data;
  String? branch;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnBranch = "branch";
  final String columnData = "data";

  RepositoryDetailReadmeDbProvider();

  Map<String, dynamic> toMap(
      String? fullName, String? branch, String? dataMapString) {
    Map<String, dynamic> map = {
      columnFullName: fullName,
      columnBranch: branch,
      columnData: dataMapString
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryDetailReadmeDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    branch = map[columnBranch];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnFullName text not null,
        $columnBranch text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  Future _getProvider(Database db, String? fullName, String? branch) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: [columnId, columnFullName, columnData],
        where: "$columnFullName = ? and $columnBranch = ?",
        whereArgs: [fullName, branch]);
    if (maps.length > 0) {
      RepositoryDetailReadmeDbProvider provider =
          RepositoryDetailReadmeDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? fullName, String? branch, String? dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, fullName, branch);
    if (provider != null) {
      await db.delete(name,
          where: "$columnFullName = ? and $columnBranch = ?",
          whereArgs: [fullName, branch]);
    }
    return await db.insert(name, toMap(fullName, branch, dataMapString));
  }

  ///获取readme详情
  Future<String?> getRepositoryReadme(String? fullName, String? branch) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, fullName, branch);
    if (provider != null) {
      return provider.data;
    }
    return null;
  }
}
