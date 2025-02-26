import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/CommonListDataType.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_item.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';

/// 通用list
/// Created by guoshuyu
/// on 2018/7/22.

class CommonListPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String showType;

  final CommonListDataType dataType;

  final String? title;

  const CommonListPage(this.title, this.showType, this.dataType,
      {super.key, this.userName, this.reposName});

  @override
  _CommonListPageState createState() => _CommonListPageState();
}

class _CommonListPageState extends State<CommonListPage>
    with
        AutomaticKeepAliveClientMixin<CommonListPage>,
        GSYListState<CommonListPage> {
  _CommonListPageState();

  _renderItem(index) {
    if (pullLoadWidgetControl.dataList.isEmpty) {
      return null;
    }
    var data = pullLoadWidgetControl.dataList[index];
    switch (widget.showType) {
      case 'repository':
        ReposViewModel reposViewModel = ReposViewModel.fromMap(data);
        return ReposItem(reposViewModel, onPressed: () {
          NavigatorUtils.goReposDetail(
              context, reposViewModel.ownerName, reposViewModel.repositoryName);
        });
      case 'repositoryql':
        ReposViewModel reposViewModel = ReposViewModel.fromQL(data);
        return ReposItem(reposViewModel, onPressed: () {
          NavigatorUtils.goReposDetail(
              context, reposViewModel.ownerName, reposViewModel.repositoryName);
        });
      case 'user':
        return UserItem(UserItemViewModel.fromMap(data), onPressed: () {
          NavigatorUtils.goPerson(context, data.login);
        });
      case 'org':
        return UserItem(UserItemViewModel.fromOrgMap(data), onPressed: () {
          NavigatorUtils.goPerson(context, data.login);
        });
      case 'issue':
        return null;
      case 'release':
        return null;
      case 'notify':
        return null;
    }
  }

  _getDataLogic() async {
    return switch (widget.dataType) {
      CommonListDataType.follower => await UserRepository.getFollowerListRequest(
          widget.userName, page,
          needDb: page <= 1),
      CommonListDataType.followed => await UserRepository.getFollowedListRequest(
          widget.userName, page,
          needDb: page <= 1),
      CommonListDataType.userRepos => await ReposRepository.getUserRepositoryRequest(
          widget.userName, page, null,
          needDb: page <= 1),
      CommonListDataType.userStar => await ReposRepository.getStarRepositoryRequest(
          widget.userName, page, null,
          needDb: page <= 1),
      CommonListDataType.repoStar => await ReposRepository.getRepositoryStarRequest(
          widget.userName, widget.reposName, page,
          needDb: page <= 1),
      CommonListDataType.repoWatcher => await ReposRepository.getRepositoryWatcherRequest(
          widget.userName, widget.reposName, page,
          needDb: page <= 1),
      CommonListDataType.repoFork => await ReposRepository.getRepositoryForksRequest(
          widget.userName, widget.reposName, page,
          needDb: page <= 1),
      CommonListDataType.history => await ReposRepository.getHistoryRequest(page),
      CommonListDataType.topics =>
        await ReposRepository.searchTopicRepositoryRequest(widget.userName, page: page),
      CommonListDataType.userOrgs =>
        await UserRepository.getUserOrgsRequest(widget.userName, page, needDb: page <= 1),
      _ => null,
    };
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return Scaffold(
      appBar: AppBar(
          title: Text(
        widget.title ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
