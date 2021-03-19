import 'package:gsy_github_app_flutter/db/sql_provider.dart';

/**
 * 用户关注表
 *
 * Created by guoshuyu
 * Date: 2018-08-07
 */

class OrgMemberDbProvider extends BaseDbProvider {
  final String name = 'OrgMember';

  final String columnId = "_id";
  final String columnOrg = "org";
  final String columnData = "data";

  int? id;
  String? org;
  String? data;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {columnOrg: org, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  OrgMemberDbProvider.fromMap(Map map) {
    id = map[columnId];
    org = map[columnOrg];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}
