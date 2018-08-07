import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * 用户组织表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class UserOrgsDbProvider extends BaseDbProvider {
  final String name = 'UserOrgs';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserOrgsDbProvider.fromMap(Map map) {
    id = map[columnId];
    userName = map[columnUserName];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}