import 'dart:async';
import 'dart:convert';

import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';
import 'package:gsy_github_app_flutter/common/model/Repository.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 仓库详情数据表
 * Created by guoshuyu
 * Date: 2018-08-07
 */
class RepositoryDetailDbProvider extends BaseDbProvider {
  final String name = 'RepositoryDetail';
  int id;
  String fullName;
  String data;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  RepositoryDetailDbProvider();

  Map<String, dynamic> toMap(String fullName, String dataMapString) {
    Map<String, dynamic> map = {columnFullName: fullName, columnData: dataMapString};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryDetailDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnFullName text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }


  Future _getUserProvider(Database db, String fullName) async {
    List<Map<String, dynamic>> maps =
    await db.query(name, columns: [columnId, columnFullName, columnData], where: "$columnFullName = ?", whereArgs: [fullName]);
    if (maps.length > 0) {
      RepositoryDetailDbProvider provider = RepositoryDetailDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String fullName, String dataMapString) async {
    Database db = await getDataBase();
    var userProvider = await _getUserProvider(db, fullName);
    if (userProvider != null) {
      await db.delete(name, where: "$columnFullName = ?", whereArgs: [fullName]);
    }
    return await db.insert(name, toMap(fullName, dataMapString));
  }

  ///获取详情
  Future<Repository> getRepository(String fullName) async {
    Database db = await getDataBase();
    var userProvider = await _getUserProvider(db, fullName);
    if (userProvider != null) {
      return Repository.fromJson(json.decode(userProvider.data));
    }
    return null;
  }


}
