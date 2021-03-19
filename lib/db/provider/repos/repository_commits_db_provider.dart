import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/RepoCommit.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 仓库提交信息表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class RepositoryCommitsDbProvider extends BaseDbProvider {
  final String name = 'RepositoryCommits';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnBranch = "branch";
  final String columnData = "data";

  int? id;
  String? fullName;
  String? data;
  String? branch;

  RepositoryCommitsDbProvider();

  Map<String, dynamic> toMap(String? fullName, String? branch, String data) {
    Map<String, dynamic> map = {
      columnFullName: fullName,
      columnBranch: branch,
      columnData: data
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryCommitsDbProvider.fromMap(Map map) {
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
        columns: [columnId, columnFullName, columnBranch, columnData],
        where: "$columnFullName = ? and $columnBranch = ?",
        whereArgs: [fullName, branch]);
    if (maps.length > 0) {
      RepositoryCommitsDbProvider provider =
          RepositoryCommitsDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? fullName, String? branch, String dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, fullName, branch);
    if (provider != null) {
      await db.delete(name,
          where: "$columnFullName = ? and $columnBranch = ?",
          whereArgs: [fullName, branch]);
    }
    return await db.insert(name, toMap(fullName, branch, dataMapString));
  }

  ///获取事件数据
  Future<List<RepoCommit>?> getData(String? fullName, String? branch) async {
    Database db = await getDataBase();

    var provider = await _getProvider(db, fullName, branch);
    if (provider != null) {
      List<RepoCommit> list = [];

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data as String?);

      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(RepoCommit.fromJson(item));
        }
      }
      return list;
    }
    return null;
  }
}
