import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gsy_github_app_flutter/common/dao/DaoResult.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';
import 'package:gsy_github_app_flutter/common/net/trending/GithubTrending.dart';
import 'package:gsy_github_app_flutter/page/RepositoryFileListPage.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/ReposHeaderItem.dart';
import 'package:gsy_github_app_flutter/widget/ReposItem.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-16
 */

class ReposDao {
  /**
   * 趋势数据
   * @param page 分页，趋势数据其实没有分页
   * @param since 数据时长， 本日，本周，本月
   * @param languageType 语言
   */
  static getTrendDao({since = 'daily', languageType, page = 0}) async {
    String url = Address.trending(since, languageType);
    var res = await new GitHubTrending().fetchTrending(url);
    if (res != null && res.result && res.data.length > 0) {
      List<ReposViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        TrendingRepoModel model = data[i];
        ReposViewModel reposViewModel = new ReposViewModel();
        reposViewModel.ownerName = model.name;
        reposViewModel.ownerPic = model.contributors[0];
        reposViewModel.repositoryName = model.reposName;
        reposViewModel.repositoryStar = model.starCount;
        reposViewModel.repositoryFork = model.forkCount;
        reposViewModel.repositoryWatch = model.meta;
        reposViewModel.repositoryType = model.language;
        reposViewModel.repositoryDes = model.description;
        list.add(reposViewModel);
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 仓库的详情数据
   */
  static getRepositoryDetailDao(userName, reposName, branch) async {
    String url = Address.getReposDetail(userName, reposName) + "?ref=" + branch;
    var res = await HttpManager.netFetch(url, null, {"Accept": 'application/vnd.github.mercy-preview+json'}, null);
    if (res != null && res.result && res.data.length > 0) {
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      return new DataResult(ReposHeaderViewModel.fromHttpMap(reposName, userName, data), true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 仓库活动事件
   */
  static getRepositoryEventDao(userName, reposName, {page = 0, branch = "master"}) async {
    String url = Address.getReposEvent(userName, reposName) + Address.getPageParams("?", page) + "&ref=" + branch;
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<EventViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(EventViewModel.fromEventMap(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取用户对当前仓库的star、watcher状态
   */
  static getRepositoryStatusDao(userName, reposName) async {
    String urls = Address.resolveStarRepos(userName, reposName);
    String urlw = Address.resolveWatcherRepos(userName, reposName);
    var resS = await HttpManager.netFetch(urls, null, null, new Options(contentType: ContentType.TEXT), noTip: true);
    var resW = await HttpManager.netFetch(urlw, null, null, new Options(contentType: ContentType.TEXT), noTip: true);
    var data = {"star": resS.result, "watch": resW.result};
    return new DataResult(data, true);
  }

  /**
   * 获取仓库的提交列表
   */
  static getReposCommitsDao(userName, reposName, {page = 0, branch = "master"}) async {
    String url = Address.getReposCommits(userName, reposName) + Address.getPageParams("?", page) + "&ref=" + branch;
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<EventViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(EventViewModel.fromCommitMap(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /***
   * 获取仓库的文件列表
   */
  static getReposFileDirDao(userName, reposName, {path = '', branch, text = false}) async {
    String url = Address.reposDataDir(userName, reposName, path, branch);
    var res = await HttpManager.netFetch(
      url,
      null,
      {"Accept": 'application/vnd.github.html'},
      new Options(contentType: text ? ContentType.TEXT : ContentType.JSON),
    );
    if (res != null && res.result) {
      List<FileItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      List<FileItemViewModel> dirs = [];
      List<FileItemViewModel> files = [];
      for (int i = 0; i < data.length; i++) {
        FileItemViewModel file = FileItemViewModel.fromMap(data[i]);
        if (file.type == 'file') {
          files.add(file);
        } else {
          dirs.add(file);
        }
      }
      list.addAll(dirs);
      list.addAll(files);
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * star仓库
   */
  static Future<DataResult> doRepositoryStarDao(userName, reposName, star) async {
    String url = Address.resolveStarRepos(userName, reposName);
    var res = await HttpManager.netFetch(url, null, null, new Options(method: !star ? 'PUT' : 'DELETE', contentType: ContentType.TEXT));
    return Future<DataResult>(() {
      return new DataResult(null, res.result);
    });
  }

  /**
   * watcher仓库
   */
  static doRepositoryWatchDao(userName, reposName, watch) async {
    String url = Address.resolveWatcherRepos(userName, reposName);
    var res = await HttpManager.netFetch(url, null, null, new Options(method: !watch ? 'PUT' : 'DELETE', contentType: ContentType.TEXT));
    return new DataResult(null, res.result);
  }

  /**
   * 获取当前仓库所有订阅用户
   */
  static getRepositoryWatcherDao(userName, reposName, page) async {
    String url = Address.getReposWatcher(userName, reposName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<UserItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(new UserItemViewModel(data[i]['login'], data[i]["avatar_url"]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取当前仓库所有star用户
   */
  static getRepositoryStarDao(userName, reposName, page) async {
    String url = Address.getReposStar(userName, reposName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<UserItemViewModel> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(new UserItemViewModel(data[i]['login'], data[i]["avatar_url"]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取仓库的fork分支
   */
  static getRepositoryForksDao(userName, reposName, page) async {
    String url = Address.getReposForks(userName, reposName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data.length > 0) {
      List<ReposViewModel> list = new List();
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(ReposViewModel.fromMap(data));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取当前仓库所有star用户
   */
  static getStarRepositoryDao(userName, page, sort) async {
    String url = Address.userStar(userName, sort) + Address.getPageParams("&", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data.length > 0) {
      List<ReposViewModel> list = new List();
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(ReposViewModel.fromMap(data));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 用户的仓库
   */
  static getUserRepositoryDao(userName, page, sort) async {
    String url = Address.userRepos(userName, sort) + Address.getPageParams("&", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data.length > 0) {
      List<ReposViewModel> list = new List();
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(ReposViewModel.fromMap(data));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 创建仓库的fork分支
   */
  static createForkDao(userName, reposName) async {
    String url = Address.createFork(userName, reposName);
    var res = await HttpManager.netFetch(url, null, null, new Options(method: "POST", contentType: ContentType.TEXT));
    return new DataResult(null, res.result);
  }

  /**
   * 获取当前仓库所有分支
   */
  static getBranchesDao(userName, reposName) async {
    String url = Address.getbranches(userName, reposName);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data.length > 0) {
      List<String> list = new List();
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(data['name']);
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 用户的前100仓库
   */
  static getUserRepository100StatusDao(userName) async {
    String url = Address.userRepos(userName, 'pushed') + "&page=1&per_page=100";
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data.length > 0) {
      int stared = 0;
      for (int i = 0; i < res.data.length; i++) {
        var data = res.data[i];
        stared += data["watchers_count"];
      }
      return new DataResult(stared, true);
    }
    return new DataResult(null, false);
  }
}
