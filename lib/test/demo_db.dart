import 'dart:async';
import 'dart:convert';

import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

/**
 * Created by guoshuyu
 * Date: 2018-08-06
 */


///数据库管理
class DemoSqlManager {
  static final _VERSION = 1;

  static final _NAME = "demo_github_app_flutter.db";

  static Database? _database;

  ///初始化
  static init() async {
    // open the database
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + _NAME;
    _database = await openDatabase(path, version: _VERSION, onCreate: (Database db, int version) async {
      // When creating the db, create the table
      //await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)");
    });
  }

  /**
   * 表是否存在
   */
  static isTableExits(String tableName) async {
    await getCurrentDatabase();
    var res = await _database?.rawQuery("select * from Sqlite_master where type = 'table' and name = '$tableName'");
    return res != null && res.length > 0;
  }

  ///获取当前数据库对象
  static Future<Database?> getCurrentDatabase() async {
    if (_database == null) {
      await init();
    }
    return _database;
  }

  ///关闭
  static close() {
    if (_database != null) {
      _database!.close();
      _database = null;
    }
  }
}

///数据库数据提供的抽象基类
abstract class DemoBaseDbProvider {
  bool isTableExits = false;

  tableSqlString();

  tableName();

  tableBaseString(String name, String columnId) {
    return '''
        create table $name (
        $columnId integer primary key autoincrement,
      ''';
  }

  Future<Database> getDataBase() async {
    return await open();
  }

  @mustCallSuper
  prepare(name, String? createSql) async {
    isTableExits = await DemoSqlManager.isTableExits(name);
    if (!isTableExits) {
      Database?db = await DemoSqlManager.getCurrentDatabase();
      return await db?.execute(createSql!);
    }
  }

  @mustCallSuper
  open() async {
    if (!isTableExits) {
      await prepare(tableName(), tableSqlString());
    }
    return await DemoSqlManager.getCurrentDatabase();
  }
}


/**
 * 用户表
 */
class DemoUserInfoDbProvider extends DemoBaseDbProvider {
  final String name = 'UserInfo';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int? id;
  String? userName;
  String? data;

  DemoUserInfoDbProvider();

  Map<String, dynamic> toMap(String userName, String data) {
    Map<String, dynamic> map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  DemoUserInfoDbProvider.fromMap(Map map) {
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

  Future _getUserProvider(Database db, String userName) async {
    List<Map<String, dynamic>> maps =
    await db.query(name, columns: [columnId, columnUserName, columnData], where: "$columnUserName = ?", whereArgs: [userName]);
    if (maps.length > 0) {
      DemoUserInfoDbProvider provider = DemoUserInfoDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String userName, String eventMapString) async {
    Database db = await getDataBase();
    var userProvider = await _getUserProvider(db, userName);
    if (userProvider != null) {
      var result = await db.delete(name, where: "$columnUserName = ?", whereArgs: [userName]);
      print(result);
    }
    return await db.insert(name, toMap(userName, eventMapString));
  }

  ///获取事件数据
  Future<User?> getUserInfo(String userName) async {
    Database db = await getDataBase();
    var userProvider = await _getUserProvider(db, userName);
    if (userProvider != null) {
      return User.fromJson(json.decode(userProvider.data));
    }
    return null;
  }
}