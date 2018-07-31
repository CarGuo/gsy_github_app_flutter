import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/dao/DaoResult.dart';
import 'package:gsy_github_app_flutter/common/model/Issue.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';

/**
 * Issue相关
 * Created by guoshuyu
 * Date: 2018-07-19
 */

class IssueDao {
  /**
   * 获取仓库issue
   * @param page
   * @param userName
   * @param repository
   * @param state issue状态
   * @param sort 排序类型 created updated等
   * @param direction 正序或者倒序
   */
  static getRepositoryIssueDao(userName, repository, state, {sort, direction, page = 0}) async {
    String url = Address.getReposIssue(userName, repository, state, sort, direction) + Address.getPageParams("&", page);
    var res = await HttpManager.netFetch(url, null, {"Accept": 'application/vnd.github.html,application/vnd.github.VERSION.raw'}, null);
    if (res != null && res.result) {
      List<Issue> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Issue.fromJson(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 搜索仓库issue
   * @param q 搜索关键字
   * @param name 用户名
   * @param reposName 仓库名
   * @param page
   * @param state 问题状态，all open closed
   */
  static searchRepositoryIssue(q, name, reposName, state, {page = 1}) async {
    String qu;
    if (state == null || state == 'all') {
      qu = q + "+repo%3A${name}%2F${reposName}";
    } else {
      qu = q + "+repo%3A${name}%2F${reposName}+state%3A${state}";
    }
    String url = Address.repositoryIssueSearch(qu) + Address.getPageParams("&", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<Issue> list = new List();
      var data = res.data["items"];
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Issue.fromJson(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * issue的详请
   */
  static getIssueInfoDao(userName, repository, number) async {
    String url = Address.getIssueInfo(userName, repository, number);
    //{"Accept": 'application/vnd.github.html,application/vnd.github.VERSION.raw'}
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      return new DataResult(Issue.fromJson(res.data), true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * issue的详请列表
   */
  static getIssueCommentDao(userName, repository, number, {page: 0}) async {
    String url = Address.getIssueComment(userName, repository, number) + Address.getPageParams("?", page);
    //{"Accept": 'application/vnd.github.html,application/vnd.github.VERSION.raw'}
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<Issue> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Issue.fromJson(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 增加issue的回复
   */
  static addIssueCommentDao(userName, repository, number, comment) async {
    String url = Address.addIssueComment(userName, repository, number);
    var res = await HttpManager.netFetch(url, {"body": comment}, {"Accept": 'application/vnd.github.VERSION.full+json'}, new Options(method: 'POST'));
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 编辑issue
   */
  static editIssueDao(userName, repository, number, issue) async {
    String url = Address.editIssue(userName, repository, number);
    var res = await HttpManager.netFetch(url, issue, {"Accept": 'application/vnd.github.VERSION.full+json'}, new Options(method: 'PATCH'));
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 锁定issue
   */
  static lockIssueDao(userName, repository, number, locked) async {
    String url = Address.lockIssue(userName, repository, number);
    var res = await HttpManager.netFetch(
        url, null, {"Accept": 'application/vnd.github.VERSION.full+json'}, new Options(method: locked ? "DELETE" : 'PUT', contentType: ContentType.TEXT),
        noTip: true);
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 创建issue
   */
  static createIssueDao(userName, repository, issue) async {
    String url = Address.createIssue(userName, repository);
    var res = await HttpManager.netFetch(url, issue, {"Accept": 'application/vnd.github.VERSION.full+json'}, new Options(method: 'POST'));
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 编辑issue回复
   */
  static editCommentDao(userName, repository, number, commentId, comment) async {
    String url = Address.editComment(userName, repository, commentId);
    var res = await HttpManager.netFetch(url, comment, {"Accept": 'application/vnd.github.VERSION.full+json'}, new Options(method: 'PATCH'));
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 删除issue回复
   */
  static deleteCommentDao(userName, repository, number, commentId) async {
    String url = Address.editComment(userName, repository, commentId);
    var res = await HttpManager.netFetch(url, null, null, new Options(method: 'DELETE'), noTip: true);
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    } else {
      return new DataResult(null, false);
    }
  }
}
