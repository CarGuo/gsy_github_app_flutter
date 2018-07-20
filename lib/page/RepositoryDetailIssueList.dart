import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/IssueDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYSearchInputWidget.dart';
import 'package:gsy_github_app_flutter/widget/IssueItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYSelectItemWidget.dart';

/**
 * 仓库详情issue列表
 * Created by guoshuyu
 * Date: 2018-07-19
 */
class RepositoryDetailIssuePage extends StatefulWidget {
  final String userName;

  final String reposName;

  RepositoryDetailIssuePage(this.userName, this.reposName);

  @override
  _RepositoryDetailIssuePageState createState() => _RepositoryDetailIssuePageState(userName, reposName);
}

// ignore: mixin_inherits_from_not_object
class _RepositoryDetailIssuePageState extends GSYListState<RepositoryDetailIssuePage> {
  final String userName;

  final String reposName;

  String issueState;

  _RepositoryDetailIssuePageState(this.userName, this.reposName);

  _renderEventItem(index) {
    IssueItemViewModel issueItemViewModel = pullLoadWidgetControl.dataList[index];
    return new IssueItem(
      issueItemViewModel,
      onPressed: () {},
    );
  }

  _resolveSelectIndex(selectIndex) {
    clearData();
    switch (selectIndex) {
      case 0:
        issueState = null;
        break;
      case 1:
        issueState = 'open';
        break;
      case 2:
        issueState = "closed";
        break;
    }
    showRefreshLoading();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => true;

  @override
  requestLoadMore() async {
    return await IssueDao.getRepositoryIssueDao(userName, reposName, issueState, page: page);
  }

  @override
  requestRefresh() async {
    return await IssueDao.getRepositoryIssueDao(userName, reposName, issueState, page: page);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new Scaffold(
      backgroundColor: Color(GSYColors.mainBackgroundColor),
      appBar: new AppBar(
        leading: new Container(),
        flexibleSpace: GSYSearchInputWidget((value){}),
        elevation: 0.0,
        backgroundColor: Color(GSYColors.mainBackgroundColor),
        bottom: new GSYSelectItemWidget([
          GSYStrings.repos_tab_issue_all,
          GSYStrings.repos_tab_issue_open,
          GSYStrings.repos_tab_issue_closed,
        ], (selectIndex) {
          _resolveSelectIndex(selectIndex);
        }),
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderEventItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
