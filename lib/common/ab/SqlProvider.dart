import 'dart:async';
import 'dart:convert';

/**
 * 数据库表
 * Created by guoshuyu
 * Date: 2018-08-03
 */
import 'package:gsy_github_app_flutter/common/ab/SqlManager.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

abstract class BaseDbProvider {
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
  prepare(name, String createSql) async {
    isTableExits = await SqlManager.isTableExits(name);
    if (!isTableExits) {
      Database db = await SqlManager.getCurrentDatabase();
      return await db.execute(createSql);
    }
  }

  @mustCallSuper
  open() async {
    if (!isTableExits) {
      await prepare(tableName(), tableSqlString());
    }
    return await SqlManager.getCurrentDatabase();
  }
}

/**
 * 仓库pulse表
 */
class RepositoryPulseDbProvider extends BaseDbProvider {
  final String name = 'RepositoryPulse';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryPulseDbProvider.fromMap(Map map) {
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

/**
 * 本地已读历史表
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

  Map toMap() {
    Map map = {columnFullName: fullName, columnReadDate: readDate, columnData: data};
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

/**
 * 仓库分支表
 */
class RepositoryBranchDbProvider extends BaseDbProvider {
  final String name = 'RepositoryPulse';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
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

/**
 * 仓库提交信息表
 */
class RepositoryCommitsDbProvider extends BaseDbProvider {
  final String name = 'RepositoryCommits';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
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

/**
 * 仓库订阅用户表
 */
class RepositoryWatcherDbProvider extends BaseDbProvider {
  final String name = 'RepositoryWatcher';
  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryWatcherDbProvider.fromMap(Map map) {
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

/**
 * 仓库收藏用户表
 */
class RepositoryStarDbProvider extends BaseDbProvider {
  final String name = 'RepositoryStar';

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryStarDbProvider.fromMap(Map map) {
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

/**
 * 仓库分支表
 */
class RepositoryForkDbProvider extends BaseDbProvider {
  final String name = 'RepositoryFork';

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryForkDbProvider.fromMap(Map map) {
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

/**
 * 仓库详情数据表
 */
class RepositoryDetailDbProvider extends BaseDbProvider {
  final String name = 'RepositoryDetail';
  int id;
  String fullName;
  String data;
  String branch;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnBranch = "branch";
  final String columnData = "data";

  Map toMap() {
    Map map = {columnFullName: fullName, columnBranch: branch, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryDetailDbProvider.fromMap(Map map) {
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

/**
 * 仓库readme文件表
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

  Map toMap() {
    Map map = {columnFullName: fullName, columnBranch: branch, columnData: data};
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

/**
 * 仓库活跃事件表
 */
class RepositoryEventDbProvider extends BaseDbProvider {
  final String name = 'RepositoryEvent';

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int id;
  String fullName;
  String data;

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryEventDbProvider.fromMap(Map map) {
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

/**
 * 仓库issue表
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

  Map toMap() {
    Map map = {columnFullName: fullName, columnState: state, columnData: data};
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

/**
 * 仓库提交信息详情表
 */
class RepositoryCommitInfoDetailDbProvider extends BaseDbProvider {
  final String name = 'RepositoryCommitInfoDetail';
  int id;
  String fullName;
  String data;
  String sha;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnSha = "sha";
  final String columnData = "data";

  Map toMap() {
    Map map = {columnFullName: fullName, columnSha: sha, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryCommitInfoDetailDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    sha = map[columnSha];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}

/**
 * 趋势表
 */
class TrendRepositoryDbProvider extends BaseDbProvider {
  final String name = 'TrendRepository';
  int id;
  String fullName;
  String data;
  String languageType;

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnLanguageType = "languageType";
  final String columnData = "data";

  Map toMap() {
    Map map = {columnFullName: fullName, columnLanguageType: languageType, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  TrendRepositoryDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    languageType = map[columnLanguageType];
    data = map[columnData];
  }

  @override
  tableSqlString() {}

  @override
  tableName() {
    return name;
  }
}

/**
 * 用户表
 */
class UserInfoDbProvider extends BaseDbProvider {
  final String name = 'UserInfo';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map toMap() {
    Map map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserInfoDbProvider.fromMap(Map map) {
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

/**
 * 用户粉丝表
 */
class UserFollowerDbProvider extends BaseDbProvider {
  final String name = 'UserFollower';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map toMap() {
    Map map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserFollowerDbProvider.fromMap(Map map) {
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

/**
 * 用户关注表
 */
class UserFollowedDbProvider extends BaseDbProvider {
  final String name = 'UserFollowed';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map toMap() {
    Map map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserFollowedDbProvider.fromMap(Map map) {
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

/**
 * 用户关注表
 */
class OrgMemberDbProvider extends BaseDbProvider {
  final String name = 'OrgMember';

  final String columnId = "_id";
  final String columnOrg = "org";
  final String columnData = "data";

  int id;
  String org;
  String data;

  Map toMap() {
    Map map = {columnOrg: org, columnData: data};
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

/**
 * 用户组织表
 */
class UserOrgsDbProvider extends BaseDbProvider {
  final String name = 'UserOrgs';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map toMap() {
    Map map = {columnUserName: userName, columnData: data};
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

/**
 * 用户收藏表
 */
class UserStaredDbProvider extends BaseDbProvider {
  final String name = 'UserStared';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map toMap() {
    Map map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserStaredDbProvider.fromMap(Map map) {
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

/**
 * 用户仓库表
 */
class UserReposDbProvider extends BaseDbProvider {
  final String name = 'UserRepos';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  Map toMap() {
    Map map = {columnUserName: userName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserReposDbProvider.fromMap(Map map) {
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

/**
 * 用户接受事件表
 */
class ReceivedEventDbProvider extends BaseDbProvider {
  final String name = 'ReceivedEvent';

  final String columnId = "_id";
  final String columnData = "data";

  int id;
  String data;

  ReceivedEventDbProvider();

  Map<String, dynamic> toMap(String eventMapString) {
    Map<String, dynamic> map = {columnData: eventMapString};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  ReceivedEventDbProvider.fromMap(Map map) {
    id = map[columnId];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  ///插入到数据库
  Future insert(String eventMapString) async {
    Database db = await getDataBase();
    ///清空后再插入，因为只保存第一页面
    db.execute("delete from $name");
    return await db.insert(name, toMap(eventMapString));
  }

  ///获取事件数据
  Future<List<Event>> getEvents() async {
    Database db = await getDataBase();
    List<Map> maps = await db.query(name, columns: [columnId, columnData]);
    List<Event> list = new List();
    if (maps.length > 0) {
      ReceivedEventDbProvider provider = ReceivedEventDbProvider.fromMap(maps.first);
      List<dynamic> eventMap = json.decode(provider.data);
      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(Event.fromJson(item));
        }
      }
    }
    return list;
  }
}

/**
 * 用户动态表
 */
class UserEventDbProvider extends BaseDbProvider {
  final String name = 'UserEvent';

  final String columnId = "_id";
  final String columnUserName = "userName";
  final String columnData = "data";

  int id;
  String userName;
  String data;

  UserEventDbProvider();

  Map toMap(String userName, String eventMapString) {
    Map map = {columnUserName: userName, columnData: eventMapString};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UserEventDbProvider.fromMap(Map map) {
    id = map[columnId];
    userName = map[columnUserName];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    tableBaseString(name, columnId) +
        '''
        $columnUserName text not null)=
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  ///插入到数据库
  Future insert(String userName, String eventMapString) async {
    Database db = await getDataBase();
    ///清空后再插入，因为只保存第一页面
    db.execute("delete from $name");
    return await db.insert(name, toMap(userName, eventMapString));
  }

  ///获取事件数据
  Future<List<Event>> getEvents() async {
    Database db = await getDataBase();
    List<Map> maps = await db.query(name, columns: [columnId, columnData]);
    List<Event> list = new List();
    if (maps.length > 0) {
      ReceivedEventDbProvider provider = ReceivedEventDbProvider.fromMap(maps.first);
      List<dynamic> eventMap = json.decode(provider.data);
      if (eventMap.length > 0) {
        for (var item in eventMap) {
          list.add(Event.fromJson(item));
        }
      }
    }
    return list;
  }


}

/**
 * issue详情表
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

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data, columnNumber: number};
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

/**
 * issue评论表
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

  Map toMap() {
    Map map = {columnFullName: fullName, columnData: data, columnNumber: number, columnCommentId: commentId};
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
