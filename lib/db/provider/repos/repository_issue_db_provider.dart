import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:sqflite/sqflite.dart';

/// 仓库issue表
/// Created by guoshuyu
/// Date: 2018-08-07
///
/// 表结构演进：
///   v1: (id, fullName, state, data)  —— 只按 state 缓存，切换 sort/direction 会命中错误缓存
///   v2: 追加 (sort, direction, labels) 三列作为缓存 fingerprint 的一部分。
///       由于本仓库 [SqlManager] 没有走 sqflite 官方 onUpgrade，采用运行时 PRAGMA
///       检测 + ALTER TABLE ADD COLUMN 兼容旧库；旧行的新列默认 ''，与新代码
///       在 sort/direction 均为默认时的写入行为一致，可无缝共存。

class RepositoryIssueDbProvider extends BaseDbProvider {
  final String name = 'RepositoryIssue';
  int? id;
  String? fullName;
  String? data;
  String? state;
  String? sort;
  String? direction;
  String? labels;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnState = "state";
  final String columnData = "data";
  final String columnSort = "sort";
  final String columnDirection = "direction";
  final String columnLabels = "labels";

  RepositoryIssueDbProvider();

  Map<String, dynamic> toMap(String? fullName, String state, String sort,
      String direction, String labels, String data) {
    Map<String, dynamic> map = {
      columnFullName: fullName,
      columnState: state,
      columnSort: sort,
      columnDirection: direction,
      columnLabels: labels,
      columnData: data,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryIssueDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    state = map[columnState];
    sort = map[columnSort];
    direction = map[columnDirection];
    labels = map[columnLabels];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnFullName text not null,
        $columnState text not null,
        $columnSort text not null default '',
        $columnDirection text not null default '',
        $columnLabels text not null default '',
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  /// 兼容旧库：如果 v1 表存在但缺少 v2 新列，运行时 ALTER TABLE 补齐。
  Future _ensureColumns(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info($name)');
    final existing = info.map((row) => row['name']?.toString()).toSet();
    Future<void> addIfMissing(String columnName) async {
      if (!existing.contains(columnName)) {
        await db.execute(
            "ALTER TABLE $name ADD COLUMN $columnName text not null default ''");
      }
    }

    await addIfMissing(columnSort);
    await addIfMissing(columnDirection);
    await addIfMissing(columnLabels);
  }

  @override
  open() async {
    final db = await super.open();
    if (db != null) {
      await _ensureColumns(db);
    }
    return db;
  }

  Future _getProvider(Database db, String? fullName, String state, String sort,
      String direction, String labels) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: [
          columnId,
          columnFullName,
          columnState,
          columnSort,
          columnDirection,
          columnLabels,
          columnData,
        ],
        where:
            "$columnFullName = ? and $columnState = ? and $columnSort = ? and $columnDirection = ? and $columnLabels = ?",
        whereArgs: [fullName, state, sort, direction, labels]);
    if (maps.isNotEmpty) {
      RepositoryIssueDbProvider provider =
          RepositoryIssueDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? fullName, String state, String dataMapString,
      {String sort = '', String direction = '', String labels = ''}) async {
    Database db = await getDataBase();
    var provider =
        await _getProvider(db, fullName, state, sort, direction, labels);
    if (provider != null) {
      await db.delete(name,
          where:
              "$columnFullName = ? and $columnState = ? and $columnSort = ? and $columnDirection = ? and $columnLabels = ?",
          whereArgs: [fullName, state, sort, direction, labels]);
    }
    return await db.insert(
        name, toMap(fullName, state, sort, direction, labels, dataMapString));
  }

  ///获取事件数据
  Future<List<Issue>?> getData(String? fullName, String state,
      {String sort = '', String direction = '', String labels = ''}) async {
    Database db = await getDataBase();

    var provider =
        await _getProvider(db, fullName, state, sort, direction, labels);
    if (provider != null) {
      List<Issue> list = [];

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data as String?);

      if (eventMap.isNotEmpty) {
        for (var item in eventMap) {
          list.add(Issue.fromJson(item));
        }
      }
      return list;
    }
    return null;
  }
}
