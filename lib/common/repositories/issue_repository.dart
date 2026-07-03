import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/db/provider/issue/issue_comment_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/issue/issue_detail_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_issue_db_provider.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/net/api.dart';

/// Issue相关
/// Created by guoshuyu
/// Date: 2018-07-19

class IssueRepository {
  /// 获取仓库issue
  /// @param page
  /// @param userName
  /// @param repository
  /// @param state issue状态
  /// @param sort 排序类型 created updated等
  /// @param direction 正序或者倒序
  /// @param labels 逗号拼接的 label 名（AND 匹配），传空串等价于不过滤
  static getRepositoryIssueRequest(String userName, String repository, state,
      {sort, direction, labels, page = 0, needDb = false}) async {
    String? fullName = "$userName/$repository";
    String dbState = state ?? "*";
    String dbSort = (sort ?? '') as String;
    String dbDirection = (direction ?? '') as String;
    String dbLabels = (labels ?? '') as String;
    RepositoryIssueDbProvider provider = RepositoryIssueDbProvider();

    next() async {
      String url =
          Address.getReposIssue(userName, repository, state, sort, direction,
                  dbLabels.isEmpty ? null : dbLabels) +
              Address.getPageParams("&", page);
      var res = await httpManager.netFetch(
          url,
          null,
          {
            "Accept":
                'application/vnd.github.html,application/vnd.github.VERSION.raw'
          },
          null);
      if (res != null && res.result) {
        List<Issue> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(Issue.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(fullName, dbState, json.encode(data),
              sort: dbSort, direction: dbDirection, labels: dbLabels);
        }
        return DataResult(list, true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      List<Issue>? list = await provider.getData(fullName, dbState,
          sort: dbSort, direction: dbDirection, labels: dbLabels);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// 拉取仓库定义的 labels 列表
  ///
  /// 仅返回 name/color/description 简要信息，供 issue 列表筛选 UI 展示 chip。
  /// GitHub REST 端点 /repos/:o/:r/labels 默认每页 30 个，我们支持翻页
  static getRepositoryLabelsRequest(userName, repository, {page = 1}) async {
    String url = Address.getReposLabels(userName, repository) +
        Address.getPageParams("?", page);
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      final data = res.data;
      if (data is! List || data.isEmpty) {
        return DataResult(<String>[], false);
      }
      final names = <String>[];
      for (final item in data) {
        if (item is Map && item['name'] is String) {
          names.add(item['name'] as String);
        }
      }
      return DataResult(names, true);
    }
    return DataResult(<String>[], false);
  }

  /// 搜索仓库issue
  /// @param q 搜索关键字
  /// @param name 用户名
  /// @param reposName 仓库名
  /// @param page
  /// @param state 问题状态，all open closed
  static searchRepositoryRequest(q, name, reposName, state, {page = 1}) async {
    String? qu;
    if (state == null || state == 'all') {
      qu = q + "+repo%3A$name%2F$reposName";
    } else {
      qu = q + "+repo%3A$name%2F$reposName+state%3A$state";
    }
    String url =
        Address.repositoryIssueSearch(qu) + Address.getPageParams("&", page);
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<Issue> list = [];
      var data = res.data["items"];
      if (data == null || data.length == 0) {
        return DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Issue.fromJson(data[i]));
      }
      return DataResult(list, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// issue的详请
  static getIssueInfoRequest(userName, repository, number, {needDb = true}) async {
    String? fullName =  "$userName/$repository";

    IssueDetailDbProvider provider = IssueDetailDbProvider();

    next() async {
      String url = Address.getIssueInfo(userName, repository, number);
      //full+json 会带上 reactions/author_association/body_html/labels 等
      var res = await httpManager.netFetch(
          url, null, {"Accept": 'application/vnd.github.VERSION.full+json'}, null);
      if (res != null && res.result) {
        if (needDb) {
          provider.insert(fullName, number, json.encode(res.data));
        }
        return DataResult(Issue.fromJson(res.data), true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      Issue? issue = await provider.getRepository(fullName, number);
      if (issue == null) {
        return await next();
      }
      DataResult dataResult = DataResult(issue, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// issue的详请列表
  static getIssueCommentRequest(userName, repository, number,
      {page = 0, needDb = false}) async {
    String? fullName =  "$userName/$repository";
    IssueCommentDbProvider provider = IssueCommentDbProvider();

    next() async {
      String url = Address.getIssueComment(userName, repository, number) +
          Address.getPageParams("?", page);
      //full+json 会带上 reactions/author_association/body_html
      var res = await httpManager.netFetch(
          url,
          null,
          {"Accept": 'application/vnd.github.VERSION.full+json'},
          null);
      if (res != null && res.result) {
        List<Issue> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return DataResult(null, false);
        }
        if (needDb) {
          provider.insert(fullName, number, json.encode(res.data));
        }
        for (int i = 0; i < data.length; i++) {
          list.add(Issue.fromJson(data[i]));
        }
        return DataResult(list, true);
      } else {
        return DataResult(null, false);
      }
    }

    if (needDb) {
      List<Issue>? list = await provider.getData(fullName, number);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /// 增加issue的回复
  static addIssueCommentRequest(userName, repository, number, comment) async {
    String url = Address.addIssueComment(userName, repository, number);
    var res = await httpManager.netFetch(
        url,
        {"body": comment},
        {"Accept": 'application/vnd.github.VERSION.full+json'},
        Options(method: 'POST'));
    if (res != null && res.result) {
      return DataResult(res.data, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 编辑issue
  static editIssueRequest(userName, repository, number, issue) async {
    String url = Address.editIssue(userName, repository, number);
    var res = await httpManager.netFetch(
        url,
        issue,
        {"Accept": 'application/vnd.github.VERSION.full+json'},
        Options(method: 'PATCH'));
    if (res != null && res.result) {
      return DataResult(res.data, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 锁定issue
  static lockIssueRequest(userName, repository, number, locked) async {
    String url = Address.lockIssue(userName, repository, number);
    var res = await httpManager.netFetch(
        url,
        null,
        {"Accept": 'application/vnd.github.VERSION.full+json'},
        Options(method: locked ? "DELETE" : 'PUT'),
        noTip: true);
    if (res != null && res.result) {
      return DataResult(res.data, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 创建issue
  static createIssueRequest(userName, repository, issue) async {
    String url = Address.createIssue(userName, repository);
    var res = await httpManager.netFetch(
        url,
        issue,
        {"Accept": 'application/vnd.github.VERSION.full+json'},
        Options(method: 'POST'));
    if (res != null && res.result) {
      return DataResult(res.data, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 编辑issue回复
  static editCommentRequest(
      userName, repository, number, commentId, comment) async {
    String url = Address.editComment(userName, repository, commentId);
    var res = await httpManager.netFetch(
        url,
        comment,
        {"Accept": 'application/vnd.github.VERSION.full+json'},
        Options(method: 'PATCH'));
    if (res != null && res.result) {
      return DataResult(res.data, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 删除issue回复
  static deleteCommentRequest(userName, repository, number, commentId) async {
    String url = Address.editComment(userName, repository, commentId);
    var res = await httpManager
        .netFetch(url, null, null, Options(method: 'DELETE'), noTip: true);
    if (res != null && res.result) {
      return DataResult(res.data, true);
    } else {
      return DataResult(null, false);
    }
  }

  /// 拉取 issue timeline，含 labeled/assigned/milestoned/renamed/closed/reopened/
  /// locked/unlocked/referenced/cross-referenced/commented 等事件
  /// 注意：timeline 端点在 GitHub 早期需要 `mockingbird-preview` Accept，目前已 GA。
  /// 我们在请求头里附加旧的 preview 值以兼容自建 GHE。
  static getIssueTimelineRequest(userName, repository, number,
      {page = 1}) async {
    String url = Address.getIssueTimeline(userName, repository, number) +
        Address.getPageParams("?", page);
    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.mockingbird-preview+json,application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        null,
        noTip: true);
    if (res != null && res.result) {
      final data = res.data;
      if (data is! List || data.isEmpty) {
        return DataResult(<IssueTimelineEvent>[], true);
      }
      final list = <IssueTimelineEvent>[];
      for (final item in data) {
        if (item is Map) {
          list.add(IssueTimelineEvent.fromJson(
              Map<String, dynamic>.from(item)));
        }
      }
      return DataResult(list, true);
    }
    return DataResult(<IssueTimelineEvent>[], false);
  }

  /// 添加 issue reaction
  static addIssueReactionRequest(
      userName, repository, number, String content) async {
    String url = Address.getIssueReactions(userName, repository, number);
    var res = await httpManager.netFetch(
        url,
        {"content": content},
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'POST'),
        noTip: true);
    if (res != null && res.result) {
      return DataResult(res.data, true);
    }
    return DataResult(null, false);
  }

  /// 删除 issue reaction
  static deleteIssueReactionRequest(
      userName, repository, number, reactionId) async {
    String url = Address.deleteIssueReaction(
        userName, repository, number, reactionId);
    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'DELETE'),
        noTip: true);
    if (res != null && res.result) {
      return DataResult(res.data, true);
    }
    return DataResult(null, false);
  }

  /// 添加 issue comment reaction
  static addCommentReactionRequest(
      userName, repository, commentId, String content) async {
    String url =
        Address.getIssueCommentReactions(userName, repository, commentId);
    var res = await httpManager.netFetch(
        url,
        {"content": content},
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'POST'),
        noTip: true);
    if (res != null && res.result) {
      return DataResult(res.data, true);
    }
    return DataResult(null, false);
  }

  /// 删除 issue comment reaction
  static deleteCommentReactionRequest(
      userName, repository, commentId, reactionId) async {
    String url = Address.deleteIssueCommentReaction(
        userName, repository, commentId, reactionId);
    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'DELETE'),
        noTip: true);
    if (res != null && res.result) {
      return DataResult(res.data, true);
    }
    return DataResult(null, false);
  }
}
