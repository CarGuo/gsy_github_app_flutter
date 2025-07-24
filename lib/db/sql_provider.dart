import 'dart:async';
import 'package:gsy_github_app_flutter/db/sql_manager.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

/// 数据库表基类
/// Created by guoshuyu
/// Date: 2018-08-03
abstract class BaseDbProvider {
  bool isTableExits = false;

  /// 子类需要实现的表结构SQL
  String tableSqlString();

  /// 子类需要实现的表名
  String tableName();

  /// 生成基础表结构字符串
  @protected
  String tableBaseString(String name, String columnId) {
    return '''
        create table $name (
        $columnId integer primary key autoincrement,
      ''';
  }

  /// 获取数据库连接
  Future<Database?> getDataBase() async {
    return await open();
  }

  /// 准备表结构 - 如果表不存在则创建
  @mustCallSuper
  Future<void> prepare(String name, String? createSql) async {
    if (createSql == null) return;
    
    isTableExits = await SqlManager.isTableExits(name);
    if (!isTableExits) {
      final db = await SqlManager.getCurrentDatabase();
      await db?.execute(createSql);
      isTableExits = true;
    }
  }

  /// 打开数据库连接并确保表存在
  @mustCallSuper
  Future<Database?> open() async {
    if (!isTableExits) {
      await prepare(tableName(), tableSqlString());
    }
    return await SqlManager.getCurrentDatabase();
  }
}
