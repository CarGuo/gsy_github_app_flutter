import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/db/provider/issue/issue_comment_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/issue/issue_detail_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_issue_db_provider.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';
import 'package:gsy_github_app_flutter/model/pull_request.dart';
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

  /// 拉取 PR 详情。当 issue payload 的 `pull_request` 字段命中时使用。
  ///
  /// 只做一次 REST 请求；调用方拿 [PullRequest] 后自行合并到 header 展示。
  /// 不做 DB 缓存 —— PR 详情里的 mergeable/mergeable_state 是服务端后台
  /// 计算的动态值，缓存意义不大。
  static getPullRequestDetailRequest(
      String userName, String repository, int number) async {
    String url = Address.getRepoPull(userName, repository, number);
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data is Map<String, dynamic>) {
      final pr = PullRequest.fromJson(res.data as Map<String, dynamic>);
      return DataResult(pr, true);
    }
    return DataResult(null, false);
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

  /// 单条 issue comment 详情 GET
  ///
  /// 用途：reaction toggle 成功后，把单条 comment 与服务端对齐（拿回权威的
  /// `reactions` summary），避免"本地乐观值"和"服务端真实值"之间偏移。
  /// 走 `application/vnd.github.squirrel-girl-preview+json` 才能确保 reactions
  /// 字段被返回；同时带 `.full+json` 拿 body_html 保持与列表项一致。
  ///
  /// `noTip=true`：这是**成功后的对齐请求**，即使失败也不该弹错，UI 只是
  /// 暂时保留本地乐观值（下次下拉刷新会再对齐），不能给用户看到"成功了但报错"。
  static Future<DataResult> getIssueCommentDetailRequest(
      userName, repository, commentId) async {
    String url = Address.editComment(userName, repository, commentId);
    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'GET'),
        noTip: true);
    if (res == null || res.result != true) {
      return DataResult(null, false);
    }
    if (res.data is Map) {
      return DataResult(Issue.fromJson(Map<String, dynamic>.from(res.data)), true);
    }
    return DataResult(null, false);
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

  /// 单页上限：GitHub reactions API `per_page` 最大 100
  static const int _kReactionsPageSize = 100;

  /// 从返回列表里匹配当前用户的 reactionId
  /// - GitHub `login` 大小写不敏感，这里统一 lower 后比较，避免账号大小写漂移漏匹配
  static int? _pickMyReactionId(List<dynamic> data, String content, String login) {
    final target = login.toLowerCase();
    for (var item in data) {
      if (item is Map &&
          item['user'] is Map &&
          (item['user']['login'] is String) &&
          (item['user']['login'] as String).toLowerCase() == target &&
          item['content'] == content) {
        final id = item['id'];
        if (id is int) return id;
      }
    }
    return null;
  }

  /// 查询当前用户在指定 issue 上、指定 content 的 reaction id
  ///
  /// 返回三态：
  /// - `result=true, data=<int>`：拿到了 reactionId
  /// - `result=true, data=null`：服务端确认当前用户没 react 过这个 content
  ///   （**必须**同时满足：单页没找到 + 返回条数 < per_page，即没有下一页）
  /// - `result=false, data=null`：请求失败或分页可能遗漏，语义未知
  ///
  /// 上层需要区分后两者：确认没有才能降级为 add；请求失败必须回滚+报错，
  /// 不能把网络失败或"分页没翻到"当成"用户没 react 过"，否则 remove 会静默变 add。
  ///
  /// 注意：`content` 里的 `+1` 直接拼进 query 会被服务端解释为空格 → 必须做 URL 编码
  static Future<DataResult> findMyIssueReactionIdRequest(
      userName, repository, number, String content, String login) async {
    final encoded = Uri.encodeQueryComponent(content);
    String url =
        "${Address.getIssueReactions(userName, repository, number)}?content=$encoded&per_page=$_kReactionsPageSize";
    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'GET'),
        noTip: true);
    if (res == null || res.result != true) {
      return DataResult(null, false);
    }
    if (res.data is List) {
      final list = res.data as List;
      final id = _pickMyReactionId(list, content, login);
      if (id != null) return DataResult(id, true);
      // 单页没找到，只有在"这一页没满"时才能断言服务端确实没有；
      // 页已满意味着可能还有下一页藏着当前用户的记录，此时不能降级 add
      if (list.length < _kReactionsPageSize) {
        return DataResult(null, true);
      }
      return DataResult(null, false);
    }
    return DataResult(null, false);
  }

  /// 查询当前用户在指定 issue comment 上、指定 content 的 reaction id
  /// 三态语义同 [findMyIssueReactionIdRequest]
  static Future<DataResult> findMyCommentReactionIdRequest(
      userName, repository, commentId, String content, String login) async {
    final encoded = Uri.encodeQueryComponent(content);
    String url =
        "${Address.getIssueCommentReactions(userName, repository, commentId)}?content=$encoded&per_page=$_kReactionsPageSize";
    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.squirrel-girl-preview+json,application/vnd.github.VERSION.full+json'
        },
        Options(method: 'GET'),
        noTip: true);
    if (res == null || res.result != true) {
      return DataResult(null, false);
    }
    if (res.data is List) {
      final list = res.data as List;
      final id = _pickMyReactionId(list, content, login);
      if (id != null) return DataResult(id, true);
      if (list.length < _kReactionsPageSize) {
        return DataResult(null, true);
      }
      return DataResult(null, false);
    }
    return DataResult(null, false);
  }
}
