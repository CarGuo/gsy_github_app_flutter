import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/common/ab/sql_provider.dart';
import 'package:gsy_github_app_flutter/common/model/Repository.dart';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 用户仓库表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class UserReposDbProvider extends BaseDbProvider {
  final String name = 'UserRepos';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  UserReposDbProvider();

  Map<String, dynamic> toMap(String fullName, String data) {
    Map<String, dynamic> map = {columnUserName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserReposDbProvider.fromMap(Map map) {
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

  Future _getProvider(Database db, String userName) async {
    List<Map<String, dynamic>> maps =
    await db.query(name, columns: [columnId, columnUserName, columnData], where: "$columnUserName = ?", whereArgs: [userName]);
    if (maps.length > 0) {
      UserReposDbProvider provider = UserReposDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String userName, String dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, userName);
    if (provider != null) {
      await db.delete(name, where: "$columnUserName = ?", whereArgs: [userName]);
    }
    return await db.insert(name, toMap(userName, dataMapString));
  }

  ///获取事件数据
  Future<List<Repository>> geData(String userName) async {
    Database db = await getDataBase();

    var provider = await _getProvider(db, userName);
    if (provider != null) {
      List<Repository> list = new List();


      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap = await compute(CodeUtils.decodeListResult, provider.data as String);

      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(Repository.fromJson(item));
        }
      }
      return list;
    }
    return null;
  }
}
