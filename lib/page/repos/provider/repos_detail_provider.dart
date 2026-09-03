import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/model/branch.dart';
import 'package:gsy_github_app_flutter/model/repository_ql.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_page.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_network_provider.dart';

///仓库详情数据实体，包含有当前index，仓库数据，分支等等
class ReposDetailProvider with ChangeNotifier {
  late ReposNetWorkProvider network;
  final String userName;
  final String reposName;

  new({required this.userName, required this.reposName});

  /// 记录本 provider 是否已经被 [ChangeNotifier.dispose] 掉。
  ///
  /// **不是** UI 层 State 的 `mounted`——那个是 State 生命周期字段，与
  /// ChangeNotifier 无关。这里的语义是：本 provider **已被 Provider 库
  /// dispose**（例如 MultiProvider 卸载或 State recreate 覆盖旧 provider），
  /// 后续 async 回调回来时**不应再 notifyListeners**，否则命中
  /// `ChangeNotifier.debugAssertNotDisposed` 抛 "used after disposed"。
  ///
  /// 这条防御**只处理症状**——真正 root cause 是 detail 页 State 提前
  /// dispose（reviewer P0-1 未定位透），先让 log 干净下来。
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  set currentIndex(int data) {
    _currentIndex = data;
    _safeNotify();
  }

  String _currentBranch = "";

  /// 用户是否手动切过分支。true 时，后续 repo detail 请求返回的 defaultBranch
  /// 不会再覆盖用户的选择，避免"切了分支被静默回滚"。
  bool _userSelectedBranch = false;

  bool get isUserSelectedBranch => _userSelectedBranch;

  String get currentBranch => _currentBranch;

  set currentBranch(String data) {
    _currentBranch = data;
    _safeNotify();
  }

  /// 用户主动通过 branch picker 选择分支时调用，会锁定 defaultBranch 覆盖逻辑。
  void selectBranch(String data) {
    _currentBranch = data;
    _userSelectedBranch = true;
    _safeNotify();
  }

  BottomStatusModel? _bottomModel;

  BottomStatusModel? get bottomModel => _bottomModel;

  set bottomModel(BottomStatusModel? data) {
    _bottomModel = data;
    _safeNotify();
  }

  List<Widget>? _footerButtons;

  List<Widget>? get footerButtons => _footerButtons;

  set footerButtons(List<Widget>? data) {
    _footerButtons = data;
    _safeNotify();
  }

  List<Branch>? _branchList;

  List<Branch>? get branchList => _branchList;

  set branchList(List<Branch>? data) {
    _branchList = data;
    _safeNotify();
  }

  /// 仓库 labels 缓存，供 issue 列表筛选 chip 使用。
  /// 首次进入 issue tab 时懒加载一次，后续切分支/切 issue 状态时不重复拉取
  /// （labels 是 repo scope，跨 branch 相同）。
  List<String>? _labelsCache;

  List<String>? get labelsCache => _labelsCache;

  RepositoryQL? _repository;

  RepositoryQL? get repository => _repository;

  set repository(RepositoryQL? data) {
    _repository = data;
    _safeNotify();
  }

  String? _markdownData;

  String? get markdownData => _markdownData;

  set markdownData(String? data) {
    _markdownData = data;
    _safeNotify();
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
      branchList = (result.data as List<Branch>);
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
    if (!_userSelectedBranch &&
        result.data.defaultBranch != null &&
        result.data.defaultBranch.length > 0) {
      currentBranch = result.data.defaultBranch;
    }
    repository = result.data;
    getReposStatus(getBottomWidget);

    if (result.next != null) {
      result = await result.next?.call();
      if (!_userSelectedBranch &&
          result.data.defaultBranch != null &&
          result.data.defaultBranch.length > 0) {
        currentBranch = result.data.defaultBranch;
      }
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
      {sort, direction, labels, page = 0, needDb = false}) async {
    return network.getRepositoryIssueRequest(userName, reposName, state,
        sort: sort,
        direction: direction,
        labels: labels,
        page: page,
        needDb: needDb);
  }

  /// 拉取仓库 labels 列表并缓存。首次调用后，labelsCache 会被填充；再次调用
  /// 若 [force] 为 false 会直接返回缓存，供 filter dialog 打开时快速展示 chip。
  Future<List<String>> getRepositoryLabels({bool force = false}) async {
    if (!force && _labelsCache != null) {
      return _labelsCache!;
    }
    final result =
        await network.getRepositoryLabelsRequest(userName, reposName);
    if (result != null && result.result == true && result.data is List) {
      _labelsCache = List<String>.from(result.data as List);
      _safeNotify();
      return _labelsCache!;
    }
    _labelsCache = <String>[];
    return _labelsCache!;
  }

  searchRepositoryRequest(q, state, {page = 1}) async {
    return network.searchRepositoryRequest(q, userName, reposName, state,
        page: page);
  }

  createIssueRequest(issue) async {
    return network.createIssueRequest(userName, reposName, issue);
  }
}
