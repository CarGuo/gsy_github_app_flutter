
import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * 本地已读历史表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class ReadHistoryDbProvider extends BaseDbProvider {
  final String name = 'ReadHistory';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnReadDate = "readDate";
  final String columnData = "data";

  int id;
  String fullName;
  DateTime readDate;
  String data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnReadDate: readDate, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  ReadHistoryDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    readDate = map[columnReadDate];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}


