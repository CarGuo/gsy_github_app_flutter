import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * 仓库提交信息表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class RepositoryCommitsDbProvider extends BaseDbProvider {
  final String name = 'RepositoryCommits';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryCommitsDbProvider.fromMap(Map map) {
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