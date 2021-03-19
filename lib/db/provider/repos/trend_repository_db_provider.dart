import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/TrendingRepoModel.dart';
import 'package:sqflite/sqflite.dart';

/**
 * 趋势表
 * Created by guoshuyu
 * Date: 2018-08-07
 */
class TrendRepositoryDbProvider extends BaseDbProvider {
  final String name = 'TrendRepository';
  int? id;
  String? fullName;
  String? data;
  String? since;
  String? languageType;

  final String columnId = "_id";
  final String columnLanguageType = "languageType";
  final String columnSince = "since";
  final String columnData = "data";

  TrendRepositoryDbProvider();

  Map<String, dynamic> toMap(
      String language, String? since, String dataMapString) {
    Map<String, dynamic> map = {
      columnLanguageType: language,
      columnSince: since,
      columnData: dataMapString
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  TrendRepositoryDbProvider.fromMap(Map map) {
    id = map[columnId];
    languageType = map[columnLanguageType];
    since = map[columnSince];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnLanguageType text not null,
        $columnSince text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  ///插入到数据库
  Future insert(String language, String? since, String dataMapString) async {
    Database db = await getDataBase();

    ///清空后再插入，因为只保存第一页面
    db.execute("delete from $name");
    return await db.insert(name, toMap(language, since, dataMapString));
  }

  ///获取事件数据
  Future<List<TrendingRepoModel>>? getData(String language, String? since) async {
    Database db = await getDataBase();
    List<Map> maps = await db.query(name,
        columns: [columnId, columnLanguageType, columnSince, columnData],
        where: "$columnLanguageType = ? and $columnSince = ?",
        whereArgs: [language, since]);
    List<TrendingRepoModel> list = [];
    if (maps.length > 0) {
      TrendRepositoryDbProvider provider =
          TrendRepositoryDbProvider.fromMap(maps.first);

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data);

      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(TrendingRepoModel.fromJson(item));
        }
      }
    }
    return list;
  }
}
