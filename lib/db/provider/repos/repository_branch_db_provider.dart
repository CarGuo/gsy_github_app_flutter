import 'package:gsy_github_app_flutter/db/sql_provider.dart';

/**
 * 仓库分支表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class RepositoryBranchDbProvider extends BaseDbProvider {
  final String name = 'RepositoryPulse';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int? id;
  String? fullName;
  String? data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryBranchDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}
