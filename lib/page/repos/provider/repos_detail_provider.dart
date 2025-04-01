import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/model/repository_ql.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_page.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_network_provider.dart';

///仓库详情数据实体，包含有当前index，仓库数据，分支等等
class ReposDetailProvider with ChangeNotifier {
  late ReposNetWorkProvider network;
  final String userName;
  final String reposName;

  ReposDetailProvider({required this.userName, required this.reposName});

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  set currentIndex(int data) {
    _currentIndex = data;
    notifyListeners();
  }

  String _currentBranch = "";

  String get currentBranch => _currentBranch;

  set currentBranch(String data) {
    _currentBranch = data;
    notifyListeners();
  }

  BottomStatusModel? _bottomModel;

  BottomStatusModel? get bottomModel => _bottomModel;

  set bottomModel(BottomStatusModel? data) {
    _bottomModel = data;
    notifyListeners();
  }

  List<Widget>? _footerButtons;

  List<Widget>? get footerButtons => _footerButtons;

  set footerButtons(List<Widget>? data) {
    _footerButtons = data;
    notifyListeners();
  }

  List<String>? _branchList;

  List<String>? get branchList => _branchList;

  set branchList(List<String>? data) {
    _branchList = data;
    notifyListeners();
  }

  RepositoryQL? _repository;

  RepositoryQL? get repository => _repository;

  set repository(RepositoryQL? data) {
    _repository = data;
    notifyListeners();
  }

  String? _markdownData;

  String? get markdownData => _markdownData;

  set markdownData(String? data) {
    _markdownData = data;
    notifyListeners();
  }

  ///#################################################///

  ///获取网络端仓库的star等状态
  getReposStatus(
      List<Widget> Function(ReposDetailProvider p) getBottomWidget) async {
    String watchText =
        repository!.isSubscription == "SUBSCRIBED" ? "UnWatch" : "Watch";
    String starText = repository!.isStared! ? "UnStar" : "Star";
    IconData watchIcon = repository!.isSubscription == "SUBSCRIBED"
        ? GSYICons.REPOS_ITEM_WATCHED
        : GSYICons.REPOS_ITEM_WATCH;
    IconData starIcon = repository!.isStared!
        ? GSYICons.REPOS_ITEM_STARED
        : GSYICons.REPOS_ITEM_STAR;
    BottomStatusModel model =
        BottomStatusModel(watchText, starText, watchIcon, starIcon);
    bottomModel = model;
    footerButtons = getBottomWidget(this);
  }

  ///获取分支数据
  getBranchList() async {
    var result = await ReposRepository.getBranchesRequest(userName, reposName);
    if (result != null && result.result) {
      var res = result.data as List<String?>;
      branchList = res.where((item) => item != null).cast<String>().toList();
    }
  }

  ///####################### 单纯为了展示 provider 里使用 provider ##########################///

  Future<void> refreshReadme() async {
    var res = await network.refreshReadme(userName, reposName, currentBranch);
    if (res != null && res.result) {
      markdownData = res.data;
    }
    if (res.next != null) {
      res = await res.next?.call();
      markdownData = res.data;
    }
  }

  Future<void> getRepositoryDetailRequest(
      List<Widget> Function(ReposDetailProvider p) getBottomWidget) async {
    var result = await network.getRepositoryDetailRequest(
        userName, reposName, currentBranch);
    if (result.data.defaultBranch != null &&
        result.data.defaultBranch.length > 0) {
      currentBranch = result.data.defaultBranch;
    }
    repository = result.data;
    getReposStatus(getBottomWidget);

    if (result.next != null) {
      result = await result.next?.call();
      repository = result.data;
      getReposStatus(getBottomWidget);
    }
  }

  getReposCommitsRequest({page = 0, needDb = false}) async {
    return network.getReposCommitsRequest(
      userName,
      reposName,
      page: page,
      branch: currentBranch,
      needDb: page <= 1,
    );
  }

  getRepositoryEventRequest({page = 0, needDb = false}) async {
    return network.getRepositoryEventRequest(
      userName,
      reposName,
      page: page,
      branch: currentBranch,
      needDb: page <= 1,
    );
  }

  createForkRequest() async {
    return network.createForkRequest(userName, reposName);
  }

  doRepositoryWatchRequest() async {
    return network.doRepositoryWatchRequest(
        userName, reposName, repository!.isSubscription == "SUBSCRIBED");
  }

  doRepositoryStarRequest() async {
    return network.doRepositoryStarRequest(
        userName, reposName, repository!.isStared);
  }

  getReposFileDirRequest({path = '', text = false, isHtml = false}) async {
    return network.getReposFileDirRequest(userName, reposName,
        path: path, branch: currentBranch, text: text, isHtml: isHtml);
  }

  getRepositoryIssueRequest(state,
      {sort, direction, page = 0, needDb = false}) async {
    return network.getRepositoryIssueRequest(userName, reposName, state,
        sort: sort, direction: direction, page: page, needDb: needDb);
  }

  searchRepositoryRequest(q, state, {page = 1}) async {
    return network.searchRepositoryRequest(q, userName, reposName, state,
        page: page);
  }

  createIssueRequest(issue) async {
    return network.createIssueRequest(userName, reposName, issue);
  }
}
