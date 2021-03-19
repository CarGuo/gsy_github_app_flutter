import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/Issue.dart';
import 'package:sqflite/sqflite.dart';

/**
 * issue评论表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class IssueCommentDbProvider extends BaseDbProvider {
  final String name = 'IssueComment';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnNumber = "number";
  final String columnCommentId = "commentId";
  final String columnData = "data";

  int? id;
  String? fullName;
  String? commentId;
  String? number;
  String? data;

  IssueCommentDbProvider();

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

  IssueCommentDbProvider.fromMap(Map map) {
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
        $columnCommentId text,
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
      IssueCommentDbProvider provider =
          IssueCommentDbProvider.fromMap(maps.first);
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

  ///获取事件数据
  Future<List<Issue>?> getData(String? fullName, String number) async {
    Database db = await getDataBase();

    var provider = await _getProvider(db, fullName, number);
    if (provider != null) {
      List<Issue> list = [];

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data as String?);

      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(Issue.fromJson(item));
        }
      }
      return list;
    }
    return null;
  }
}
