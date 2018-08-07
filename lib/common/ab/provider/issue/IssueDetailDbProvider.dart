
import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * issue详情表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class IssueDetailDbProvider extends BaseDbProvider {
  final String name = 'IssueDetail';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnNumber = "number";
  final String columnData = "data";

  int id;
  String fullName;
  String number;
  String data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnData: data, columnNumber: number};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  IssueDetailDbProvider.fromMap(Map map) {
    id = map[columnId];
    number = map[columnNumber];
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