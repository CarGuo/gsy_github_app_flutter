import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_version/get_version.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/DaoResult.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/net/Api.dart';
import 'package:gsy_github_app_flutter/common/net/trending/GithubTrending.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/page/RepositoryFileListPage.dart';
import 'package:gsy_github_app_flutter/widget/PushCoedItem.dart';
import 'package:gsy_github_app_flutter/widget/PushHeader.dart';
import 'package:gsy_github_app_flutter/widget/ReleaseItem.dart';
import 'package:gsy_github_app_flutter/widget/ReposHeaderItem.dart';
import 'package:gsy_github_app_flutter/widget/ReposItem.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';
import 'package:pub_semver/pub_semver.dart';

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
    String url = Address.getReposEvent(userName, reposName) + Address.getPageParams("?", page);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<Event> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(Event.fromJson(data[i]));
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
    String url = Address.getReposCommits(userName, reposName) + Address.getPageParams("?", page) + "&sha=" + branch;
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      List<RepoCommit> list = new List();
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < data.length; i++) {
        list.add(RepoCommit.fromJson(data[i]));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /***
   * 获取仓库的文件列表
   */
  static getReposFileDirDao(userName, reposName, {path = '', branch, text = false, isHtml = false}) async {
    String url = Address.reposDataDir(userName, reposName, path, branch);
    var res = await HttpManager.netFetch(
      url,
      null,
      //text ? {"Accept": 'application/vnd.github.VERSION.raw'} : {"Accept": 'application/vnd.github.html'},
      isHtml ? {"Accept": 'application/vnd.github.html'} : {"Accept": 'application/vnd.github.VERSION.raw'},
      new Options(contentType: text ? ContentType.text : ContentType.json),
    );
    if (res != null && res.result) {
      if (text) {
        return new DataResult(res.data, true);
      }
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

  /**
   * 详情的remde数据
   */
  static getRepositoryDetailReadmeDao(userName, reposName, branch) async {
    String url = Address.readmeFile(userName + '/' + reposName, branch);
    var res = await HttpManager.netFetch(url, null, {"Accept": 'application/vnd.github.VERSION.raw'}, new Options(contentType: ContentType.TEXT));
    //var res = await HttpManager.netFetch(url, null, {"Accept": 'application/vnd.github.html'}, new Options(contentType: ContentType.TEXT));
    if (res != null && res.result) {
      return new DataResult(res.data, true);
    }
    return new DataResult(null, false);
  }

  /**
   * 搜索仓库
   * @param q 搜索关键字
   * @param sort 分类排序，beat match、most star等
   * @param order 倒序或者正序
   * @param type 搜索类型，人或者仓库 null \ 'user',
   * @param page
   * @param pageSize
   */
  static searchRepositoryDao(q, language, sort, order, type, page, pageSize) async {
    if (language != null) {
      q = q + "%2Blanguage%3A$language";
    }
    String url = Address.search(q, sort, order, type, page, pageSize);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (type == null) {
      if (res != null && res.result && res.data["items"] != null) {
        List<ReposViewModel> list = new List();
        var dataList = res.data["items"];
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
    } else {
      if (res != null && res.result && res.data["items"] != null) {
        List<UserItemViewModel> list = new List();
        var data = res.data["items"];
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
  }

  /**
   * 获取仓库的单个提交详情
   */
  static getReposCommitsInfoDao(userName, reposName, sha) async {
    String url = Address.getReposCommitsInfo(userName, reposName, sha);
    var res = await HttpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      PushHeaderViewModel pushHeaderViewModel = PushHeaderViewModel.forMap(res.data);
      var files = res.data["files"];
      for (int i = 0; i < files.length; i++) {
        pushHeaderViewModel.files.add(PushCodeItemViewModel.fromMap(files[i]));
      }
      return new DataResult(pushHeaderViewModel, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取仓库的release列表
   */
  static getRepositoryReleaseDao(userName, reposName, page, {needHtml = true, release = true}) async {
    String url = release
        ? Address.getReposRelease(userName, reposName) + Address.getPageParams("?", page)
        : Address.getReposTag(userName, reposName) + Address.getPageParams("?", page);

    var res = await HttpManager.netFetch(
      url,
      null,
      {"Accept": (needHtml ? 'application/vnd.github.html,application/vnd.github.VERSION.raw' : "")},
      null,
    );
    if (res != null && res.result && res.data.length > 0) {
      List<ReleaseItemViewModel> list = new List();
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(ReleaseItemViewModel.fromMap(data));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 版本更新
   */
  static getNewsVersion(context, showTip) async {
    //ios不检查更新
    if (Platform.isIOS) {
      return;
    }
    var res = await getRepositoryReleaseDao("CarGuo", 'GSYGithubAppFlutter', 1, needHtml: false);
    if (res != null && res.result && res.data.length > 0) {
      //github只能有release的versionName，没有code，囧
      String versionName = res.data[0].actionTitle;
      if (versionName != null) {
        if (Config.DEBUG) {
          print("versionName " + versionName);
        }
        var appVersion = await GetVersion.projectVersion;
        if (Config.DEBUG) {
          print("appVersion " + appVersion);
        }
        Version versionNameNum = Version.parse(versionName);
        Version currentNum = Version.parse(appVersion);
        int result = versionNameNum.compareTo(currentNum);
        if (Config.DEBUG) {
          print("versionNameNum " + versionNameNum.toString() + " currentNum " + currentNum.toString());
        }
        if (Config.DEBUG) {
          print("newsHad " + result.toString());
        }
        if (result > 0) {
          CommonUtils.showUpdateDialog(context, res.data[0].actionTitle + ": " + res.data[0].body);
        } else {
          if (showTip) Fluttertoast.showToast(msg: GSYStrings.app_not_new_version);
        }
      }
    }
  }
}
