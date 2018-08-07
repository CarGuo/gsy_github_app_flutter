import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * 仓库issue表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class RepositoryIssueDbProvider extends BaseDbProvider {
  final String name = 'RepositoryIssue';
  int id;
  String fullName;
  String data;
  String state;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnState = "state";
  final String columnData = "data";

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnState: state, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryIssueDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    state = map[columnState];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}