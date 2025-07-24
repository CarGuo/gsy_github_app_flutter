import 'dart:async';
import 'dart:io';

import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:sqflite/sqflite.dart';

/// 数据库管理
/// Created by guoshuyu
/// Date: 2018-08-03
class SqlManager {
  static const int _VERSION = 1;
  static const String _NAME = "gsy_github_app_flutter.db";

  static Database? _database;
  static String? _currentDbPath;
  static final Completer<Database> _dbCompleter = Completer<Database>();
  static bool _isInitializing = false;

  /// 初始化数据库 - 使用单例模式避免重复初始化
  static Future<void> init() async {
    if (_database != null) return;
    if (_isInitializing) {
      await _dbCompleter.future;
      return;
    }

    _isInitializing = true;

    try {
      final databasesPath = await getDatabasesPath();
      final userRes = await UserRepository.getUserInfoLocal();
      
      String dbName = _NAME;
      if (userRes?.result == true) {
        final user = userRes!.data as User?;
        if (user?.login != null) {
          dbName = "${user!.login!}_$_NAME";
        }
      }

      final path = Platform.isIOS 
          ? "$databasesPath/$dbName" 
          : databasesPath + dbName;
      
      _currentDbPath = path;
      
      _database = await openDatabase(
        path, 
        version: _VERSION,
        onCreate: (Database db, int version) async {
          // Database creation logic can be added here
        },
      );

      if (!_dbCompleter.isCompleted) {
        _dbCompleter.complete(_database!);
      }
    } catch (e) {
      if (!_dbCompleter.isCompleted) {
        _dbCompleter.completeError(e);
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 检查表是否存在 - 优化查询性能
  static Future<bool> isTableExits(String tableName) async {
    final database = await getCurrentDatabase();
    if (database == null) return false;

    final res = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return res.isNotEmpty;
  }

  /// 获取当前数据库对象
  static Future<Database?> getCurrentDatabase() async {
    if (_database == null) {
      await init();
    }
    return _database;
  }

  /// 关闭数据库连接
  static Future<void> close() async {
    await _database?.close();
    _database = null;
    _currentDbPath = null;
  }

  /// 获取当前数据库路径（用于调试）
  static String? get currentDbPath => _currentDbPath;
}
}
