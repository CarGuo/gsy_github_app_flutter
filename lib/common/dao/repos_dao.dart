import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart';
import 'package:gsy_github_app_flutter/common/net/transformer.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/read_history_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_commits_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_detail_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_detail_readme_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_event_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_fork_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_star_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/repository_watcher_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/repos/trend_repository_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/user/user_repos_db_provider.dart';
import 'package:gsy_github_app_flutter/db/provider/user/user_stared_db_provider.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/dao/dao_result.dart';
import 'package:gsy_github_app_flutter/model/Branch.dart';
import 'package:gsy_github_app_flutter/model/Event.dart';
import 'package:gsy_github_app_flutter/model/FileModel.dart';
import 'package:gsy_github_app_flutter/model/PushCommit.dart';
import 'package:gsy_github_app_flutter/model/Release.dart';
import 'package:gsy_github_app_flutter/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/model/Repository.dart';
import 'package:gsy_github_app_flutter/model/RepositoryQL.dart';
import 'package:gsy_github_app_flutter/model/TrendingRepoModel.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/net/api.dart';
import 'package:gsy_github_app_flutter/common/net/trending/github_trending.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  static getTrendDao(
      {since = 'daily', languageType, page = 0, needDb = true}) async {
    TrendRepositoryDbProvider provider = new TrendRepositoryDbProvider();
    String languageTypeDb = languageType ?? "*";

    next() async {
      String url = Address.trendingApi(since, languageType);
      var result = await httpManager.netFetch(
          url, null, {"api-token": Config.API_TOKEN}, null,
          noTip: true);
      if (result != null && result.result && result.data is List) {
        List<TrendingRepoModel> list =[];
        var data = result.data;
        if (data == null || data.length == 0) {
          return new DataResult(null, false);
        }
        if (needDb) {
          provider.insert(languageTypeDb + "V2", since, json.encode(data));
        }
        for (int i = 0; i < data.length; i++) {
          TrendingRepoModel model = TrendingRepoModel.fromJson(data[i]);
          list.add(model);
        }
        return new DataResult(list, true);
      } else {
        String url = Address.trending(since, languageType);
        var res = await new GitHubTrending().fetchTrending(url);
        if (res != null && res.result && res.data.length > 0) {
          List<TrendingRepoModel?> list = [];
          var data = res.data;
          if (data == null || data.length == 0) {
            return new DataResult(null, false);
          }
          if (needDb) {
            provider.insert(languageTypeDb + "V2", since, json.encode(data));
          }
          for (int i = 0; i < data.length; i++) {
            TrendingRepoModel? model = data[i];
            list.add(model);
          }
          return new DataResult(list, true);
        } else {
          return new DataResult(null, false);
        }
      }
    }

    if (needDb) {
      List<TrendingRepoModel>? list =
          await provider.getData(languageTypeDb + "V2", since);
      if (list == null || list.length == 0) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 仓库的详情数据
   */
  static getRepositoryDetailDao(userName, reposName, branch,
      {needDb = true}) async {
    String? fullName = userName + "/" + reposName + "v3";
    RepositoryDetailDbProvider provider = new RepositoryDetailDbProvider();

    next() async {
      var result = await getRepository(userName, reposName);
      if (result != null && result.data != null) {
        var data = result.data!["repository"];
        if (data == null) {
          return new DataResult(null, false);
        }
        var repositoryQL = RepositoryQL.fromMap(data);
        if (needDb) {
          provider.insert(fullName, json.encode(data));
        }
        saveHistoryDao(fullName, DateTime.now(), json.encode(data));
        return new DataResult(repositoryQL, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      RepositoryQL? repositoryQL = await provider.getRepository(fullName);
      if (repositoryQL == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(repositoryQL, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 仓库活动事件
   */
  static getRepositoryEventDao(userName, reposName,
      {page = 0, branch = "master", needDb = false}) async {
    String? fullName = userName + "/" + reposName;
    RepositoryEventDbProvider provider = new RepositoryEventDbProvider();

    next() async {
      String url = Address.getReposEvent(userName, reposName) +
          Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<Event> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(Event.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(fullName, json.encode(data));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<Event>? list = await provider.getEvents(fullName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 获取用户对当前仓库的star、watcher状态
   */
  static getRepositoryStatusDao(userName, reposName) async {
    String urls = Address.resolveStarRepos(userName, reposName);
    String urlw = Address.resolveWatcherRepos(userName, reposName);
    var resS = await httpManager.netFetch(urls, null, null, null, noTip: true);
    var resW = await httpManager.netFetch(urlw, null, null, null, noTip: true);
    var data = {"star": resS!.result, "watch": resW!.result};
    return new DataResult(data, true);
  }

  /**
   * 获取仓库的提交列表
   */
  static getReposCommitsDao(userName, reposName,
      {page = 0, branch = "master", needDb = false}) async {
    String? fullName = userName + "/" + reposName;

    RepositoryCommitsDbProvider provider = new RepositoryCommitsDbProvider();

    next() async {
      String url = Address.getReposCommits(userName, reposName) +
          Address.getPageParams("?", page) +
          "&sha=" +
          branch;
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<RepoCommit> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(RepoCommit.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(fullName, branch, json.encode(data));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<RepoCommit>? list = await provider.getData(fullName, branch);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /***
   * 获取仓库的文件列表
   */
  static getReposFileDirDao(userName, reposName,
      {path = '', branch, text = false, isHtml = false}) async {
    String url = Address.reposDataDir(userName, reposName, path, branch);
    var res = await httpManager.netFetch(
      url,
      null,
      //text ? {"Accept": 'application/vnd.github.VERSION.raw'} : {"Accept": 'application/vnd.github.html'},
      isHtml
          ? {"Accept": 'application/vnd.github.html'}
          : {"Accept": 'application/vnd.github.VERSION.raw'},
      new Options(contentType: text ? "text" : "json"),
    );
    if (res != null && res.result) {
      if (text) {
        return new DataResult(res.data, true);
      }
      List<FileModel> list = [];
      var data = res.data;
      if (data == null || data.length == 0) {
        return new DataResult(null, false);
      }
      List<FileModel> dirs = [];
      List<FileModel> files = [];
      for (int i = 0; i < data.length; i++) {
        FileModel file = FileModel.fromJson(data[i]);
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
  static Future<DataResult> doRepositoryStarDao(
      userName, reposName, star) async {
    String url = Address.resolveStarRepos(userName, reposName);
    var res = await httpManager.netFetch(
        url, null, null, new Options(method: !star ? 'PUT' : 'DELETE'));
    return Future<DataResult>(() {
      return new DataResult(null, res!.result);
    });
  }

  /**
   * watcher仓库
   */
  static doRepositoryWatchDao(userName, reposName, watch) async {
    String url = Address.resolveWatcherRepos(userName, reposName);
    var res = await httpManager.netFetch(
        url, null, null, new Options(method: !watch ? 'PUT' : 'DELETE'));
    return new DataResult(null, res!.result);
  }

  /**
   * 获取当前仓库所有订阅用户
   */
  static getRepositoryWatcherDao(userName, reposName, page,
      {needDb = false}) async {
    String? fullName = userName + "/" + reposName;
    RepositoryWatcherDbProvider provider = new RepositoryWatcherDbProvider();

    next() async {
      String url = Address.getReposWatcher(userName, reposName) +
          Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<User> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(new User.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(fullName, json.encode(data));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<User>? list = await provider.geData(fullName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 获取当前仓库所有star用户
   */
  static getRepositoryStarDao(userName, reposName, page,
      {needDb = false}) async {
    String? fullName = userName + "/" + reposName;
    RepositoryStarDbProvider provider = new RepositoryStarDbProvider();
    next() async {
      String url = Address.getReposStar(userName, reposName) +
          Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result) {
        List<User> list = [];
        var data = res.data;
        if (data == null || data.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(new User.fromJson(data[i]));
        }
        if (needDb) {
          provider.insert(fullName, json.encode(data));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<User>? list = await provider.geData(fullName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 获取仓库的fork分支
   */
  static getRepositoryForksDao(userName, reposName, page,
      {needDb = false}) async {
    String? fullName = userName + "/" + reposName;
    RepositoryForkDbProvider provider = new RepositoryForkDbProvider();
    next() async {
      String url = Address.getReposForks(userName, reposName) +
          Address.getPageParams("?", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result && res.data.length > 0) {
        List<Repository> list = [];
        var dataList = res.data;
        if (dataList == null || dataList.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < dataList.length; i++) {
          var data = dataList[i];
          list.add(Repository.fromJson(data));
        }
        if (needDb) {
          provider.insert(fullName, json.encode(dataList));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<Repository>? list = await provider.geData(fullName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 获取用户所有star
   */
  static getStarRepositoryDao(userName, page, sort, {needDb = false}) async {
    UserStaredDbProvider provider = new UserStaredDbProvider();
    next() async {
      String url =
          Address.userStar(userName, sort) + Address.getPageParams("&", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result && res.data.length > 0) {
        List<Repository> list = [];
        var dataList = res.data;
        if (dataList == null || dataList.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < dataList.length; i++) {
          var data = dataList[i];
          list.add(Repository.fromJson(data));
        }
        if (needDb) {
          provider.insert(userName, json.encode(dataList));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<Repository>? list = await provider.geData(userName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 用户的仓库
   */
  static getUserRepositoryDao(userName, page, sort, {needDb = false}) async {
    UserReposDbProvider provider = new UserReposDbProvider();
    next() async {
      String url =
          Address.userRepos(userName, sort) + Address.getPageParams("&", page);
      var res = await httpManager.netFetch(url, null, null, null);
      if (res != null && res.result && res.data.length > 0) {
        List<Repository> list = [];
        var dataList = res.data;
        if (dataList == null || dataList.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < dataList.length; i++) {
          var data = dataList[i];
          list.add(Repository.fromJson(data));
        }
        if (needDb) {
          provider.insert(userName, json.encode(dataList));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    }

    if (needDb) {
      List<Repository>? list = await provider.geData(userName);
      if (list == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(list, true, next: next);
      return dataResult;
    }
    return await next();
  }

  /**
   * 创建仓库的fork分支
   */
  static createForkDao(userName, reposName) async {
    String url = Address.createFork(userName, reposName);
    var res = await httpManager.netFetch(
        url, null, null, new Options(method: "POST"));
    return new DataResult(null, res!.result);
  }

  /**
   * 获取当前仓库所有分支
   */
  static getBranchesDao(userName, reposName) async {
    String url = Address.getbranches(userName, reposName);
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.data.length > 0) {
      List<String?> list = [];
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];

        ///测试代码
        Serializer<Branch?> serializerForType =
            serializers.serializerForType(Branch) as Serializer<Branch?>;
        var test = serializers.deserializeWith<Branch?>(serializerForType, data);

        /// 反序列化
        Map result = serializers.serializeWith(serializerForType, test) as Map<dynamic, dynamic>;
        print("###### $test ${result}");

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
    var res = await httpManager.netFetch(url, null, null, null);
    List<Repository> honorList = [];
    if (res != null && res.result && res.data.length > 0) {
      int stared = 0;
      for (int i = 0; i < res.data.length; i++) {
        var data = res.data[i];
        Repository repository = new Repository.fromJson(data);
        stared += repository.watchersCount!;
        honorList.add(repository);
      }
      //排序
      honorList.sort((r1, r2) => r2.watchersCount! - r1.watchersCount!);
      return new DataResult({"stared": stared, "list": honorList}, true);
    }
    return new DataResult(null, false);
  }

  /**
   * 详情的remde数据
   */
  static getRepositoryDetailReadmeDao(userName, reposName, branch,
      {needDb = true}) async {
    String? fullName = userName + "/" + reposName;
    RepositoryDetailReadmeDbProvider provider =
        new RepositoryDetailReadmeDbProvider();

    next() async {
      String url = Address.readmeFile(userName + '/' + reposName, branch);
      var res = await httpManager.netFetch(
          url,
          null,
          {"Accept": 'application/vnd.github.VERSION.raw'},
          new Options(contentType: "text/plain; charset=utf-8"));
      //var res = await httpManager.netFetch(url, null, {"Accept": 'application/vnd.github.html'}, new Options(contentType: ContentType.text));
      if (res != null && res.result) {
        if (needDb) {
          provider.insert(fullName, branch, res.data);
        }
        return new DataResult(res.data, true);
      }
      return new DataResult(null, false);
    }

    if (needDb) {
      String? readme = await provider.getRepositoryReadme(fullName, branch);
      if (readme == null) {
        return await next();
      }
      DataResult dataResult = new DataResult(readme, true, next: next);
      return dataResult;
    }
    return await next();
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
  static searchRepositoryDao(
      q, language, sort, order, type, page, pageSize) async {
    if (language != null) {
      q = q + "%2Blanguage%3A$language";
    }
    String url = Address.search(q, sort, order, type, page, pageSize);
    var res = await httpManager.netFetch(url, null, null, null);
    if (type == null) {
      if (res != null && res.result && res.data["items"] != null) {
        List<Repository> list = [];
        var dataList = res.data["items"];
        if (dataList == null || dataList.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < dataList.length; i++) {
          var data = dataList[i];
          list.add(Repository.fromJson(data));
        }
        return new DataResult(list, true);
      } else {
        return new DataResult(null, false);
      }
    } else {
      if (res != null && res.result && res.data["items"] != null) {
        List<User> list = [];
        var data = res.data["items"];
        if (data == null || data.length == 0) {
          return new DataResult(null, false);
        }
        for (int i = 0; i < data.length; i++) {
          list.add(new User.fromJson(data[i]));
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
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result) {
      PushCommit pushCommit = PushCommit.fromJson(res.data);
      return new DataResult(pushCommit, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取仓库的release列表
   */
  static getRepositoryReleaseDao(userName, reposName, page,
      {needHtml = true, release = true}) async {
    String url = release
        ? Address.getReposRelease(userName, reposName) +
            Address.getPageParams("?", page)
        : Address.getReposTag(userName, reposName) +
            Address.getPageParams("?", page);

    var res = await httpManager.netFetch(
        url,
        null,
        {
          "Accept":
              'application/vnd.github.html,application/vnd.github.VERSION.raw'
        },
        null);
    if (res != null && res.result && res.data.length > 0) {
      List<Release> list = [];
      var dataList = res.data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(Release.fromJson(data));
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
    var res = await getRepositoryReleaseDao("CarGuo", 'gsy_github_app_flutter', 1,
        needHtml: false);
    if (res != null && res.result && res.data.length > 0) {
      Release release = res.data[0];
      String? versionName = release.name;
      if (versionName != null) {
        if (Config.DEBUG!) {
          print("versionName " + versionName);
        }

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        var appVersion = packageInfo.version;

        if (Config.DEBUG!) {
          print("appVersion " + appVersion);
        }
        Version versionNameNum = Version.parse(versionName);
        Version currentNum = Version.parse(appVersion);
        int result = versionNameNum.compareTo(currentNum);
        if (Config.DEBUG!) {
          print("versionNameNum " +
              versionNameNum.toString() +
              " currentNum " +
              currentNum.toString());
        }
        if (Config.DEBUG!) {
          print("newsHad " + result.toString());
        }
        if (result > 0) {
          CommonUtils.showUpdateDialog(
              context, release.name! + ": " + release.body!);
        } else {
          if (showTip)
            Fluttertoast.showToast(
                msg: GSYLocalizations.i18n(context)!.app_not_new_version);
        }
      }
    }
  }

  /**
   * 获取issue总数
   */
  static getRepositoryIssueStatusDao(userName, repository) async {
    String url = Address.getReposIssue(userName, repository, null, null, null) +
        "&per_page=1";
    var res = await httpManager.netFetch(url, null, null, null);
    if (res != null && res.result && res.headers != null) {
      try {
        StringList? link = res.headers['link'];
        if (link != null) {
          var [linkFirst, _] = link;
          int indexStart = linkFirst.lastIndexOf("page=") + 5;
          int indexEnd = linkFirst.lastIndexOf(">");
          if (indexStart >= 0 && indexEnd >= 0) {
            String count = linkFirst.substring(indexStart, indexEnd);
            return new DataResult(count, true);
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return new DataResult(null, false);
  }

  /**
   * 搜索话题
   */
  static searchTopicRepositoryDao(searchTopic, {page = 0}) async {
    String url =
        Address.searchTopic(searchTopic) + Address.getPageParams("&", page);
    var res = await httpManager.netFetch(url, null, null, null);
    var data = (res!.data != null && res.data["items"] != null)
        ? res.data["items"]
        : res.data;
    if (res.result && data != null && data.length > 0) {
      List<Repository> list = [];
      var dataList = data;
      if (dataList == null || dataList.length == 0) {
        return new DataResult(null, false);
      }
      for (int i = 0; i < dataList.length; i++) {
        var data = dataList[i];
        list.add(Repository.fromJson(data));
      }
      return new DataResult(list, true);
    } else {
      return new DataResult(null, false);
    }
  }

  /**
   * 获取阅读历史
   */
  static getHistoryDao(page) async {
    ReadHistoryDbProvider provider = new ReadHistoryDbProvider();
    List<RepositoryQL?>? list = await provider.geData(page);
    if (list == null || list.length <= 0) {
      return new DataResult(null, false);
    }
    return new DataResult(list, true);
  }

  /**
   * 保存阅读历史
   */
  static saveHistoryDao(String? fullName, DateTime dateTime, String data) {
    ReadHistoryDbProvider provider = new ReadHistoryDbProvider();
    provider.insert(fullName, dateTime, data);
  }
}
