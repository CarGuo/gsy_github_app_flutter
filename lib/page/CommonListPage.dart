import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/ReposItem.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';

/**
 * 通用list
 * Created by guoshuyu
 * on 2018/7/22.
 */

class CommonListPage extends StatefulWidget {
  final String userName;

  final String reposName;

  final String showType;

  final String dataType;

  final String title;

  CommonListPage(this.title, this.showType, this.dataType, {this.userName, this.reposName});

  @override
  _CommonListPageState createState() => _CommonListPageState(this.title, this.showType, this.dataType, this.userName, this.reposName);
}

// ignore: mixin_inherits_from_not_object
class _CommonListPageState extends GSYListState<CommonListPage> {
  final String userName;

  final String reposName;

  final String title;

  final String showType;

  final String dataType;

  _CommonListPageState(this.title, this.showType, this.dataType, this.userName, this.reposName);

  _renderItem(index) {
    if(pullLoadWidgetControl.dataList == 0) {
      return null;
    }
    var data = pullLoadWidgetControl.dataList[index];
    switch (showType) {
      case 'repository':
        return new ReposItem(data, onPressed: () {
          NavigatorUtils.goReposDetail(context, data.ownerName, data.repositoryName);
        });
      case 'user':
        return new UserItem(data, onPressed: () {
          NavigatorUtils.goPerson(context, data.userName);
        });
      case 'org':
        return null;
      case 'issue':
        return null;
      case 'release':
        return null;
      case 'notify':
        return null;
    }
  }

  _getDataLogic() async {
    switch (dataType) {
      case 'follower':
        return await UserDao.getFollowerListDao(userName, page);
      case 'followed':
        return await UserDao.getFollowedListDao(userName, page);
      case 'user_repos':
        return await ReposDao.getUserRepositoryDao(userName, page, null);
      case 'user_star':
        return await ReposDao.getStarRepositoryDao(userName, page, null);
      case 'repo_star':
        return await ReposDao.getRepositoryStarDao(userName, reposName, page);
      case 'repo_watcher':
        return await ReposDao.getRepositoryWatcherDao(userName, reposName, page);
      case 'repo_fork':
        return await ReposDao.getRepositoryForksDao(userName, reposName, page);
      case 'repo_release':
        return null;
      case 'repo_tag':
        return null;
      case 'notify':
        return null;
      case 'history':
        return null;
      case 'topics':
        return null;
      case 'user_be_stared':
        return null;
      case 'user_orgs':
        return null;
    }
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
    return new Scaffold(
      appBar: new AppBar(
          title: new Text(
        title,
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
