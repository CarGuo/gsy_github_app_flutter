import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * 仓库readme文件表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class RepositoryDetailReadmeDbProvider extends BaseDbProvider {
  final String name = 'RepositoryDetailReadme';
  int id;
  String fullName;
  String data;
  String branch;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnBranch = "branch";
  final String columnData = "data";

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnBranch: branch, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryDetailReadmeDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    branch = map[columnBranch];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}