import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/IssueDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
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
        flexibleSpace: new Container(
          padding: new EdgeInsets.only(left: 20.0, top: 12.0, right: 20.0, bottom: 12.0),
          color: Colors.white,
          child: new TextField(
              autofocus: false,
              decoration: new InputDecoration.collapsed(
                hintText: GSYStrings.repos_issue_search,
                hintStyle: GSYConstant.subSmallText,
              ),
              style: GSYConstant.smallText,
              onSubmitted: (result) {}),
        ),
        elevation: 0.0,
        backgroundColor: Color(GSYColors.mainBackgroundColor),
        bottom: new GSYSelectItemWidget([
          GSYStrings.repos_tab_issue_all,
          GSYStrings.repos_tab_issue_open,
          GSYStrings.repos_tab_issue_closed,
        ], (selectIndex) {}),
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
