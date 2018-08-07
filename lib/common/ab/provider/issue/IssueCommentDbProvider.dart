import 'package:gsy_github_app_flutter/common/ab/SqlProvider.dart';

/**
 * issue评论表
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class IssueCommentDbProvider extends BaseDbProvider {
  final String name = 'IssueComment';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnNumber = "number";
  final String columnCommentId = "commentId";
  final String columnData = "data";

  int id;
  String fullName;
  String commentId;
  String number;
  String data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnFullName: fullName, columnData: data, columnNumber: number, columnCommentId: commentId};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  IssueCommentDbProvider.fromMap(Map map) {
    id = map[columnId];
    number = map[columnNumber];
    commentId = map[columnCommentId];
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