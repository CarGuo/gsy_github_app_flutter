import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/UserHeader.dart';
import 'package:redux/redux.dart';

/**
 * 主页我的tab页
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

// ignore: mixin_inherits_from_not_object
class _MyPageState extends GSYListState<MyPage> {

  _renderEventItem(userInfo, index) {
    if (index == 0) {
      return new UserHeaderItem(userInfo);
    }
    EventViewModel eventViewModel = pullLoadWidgetControl.dataList[index - 1];
    return new EventItem(pullLoadWidgetControl.dataList[index - 1], onPressed: () {
      EventUtils.ActionUtils(context, eventViewModel.eventMap, "");
    });
  }

  Store<GSYState> _getStore() {
    return StoreProvider.of(context);
  }

  _getUserName() {
    if (_getStore().state.userInfo == null) {
      return null;
    }
    return _getStore().state.userInfo.login;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    pullLoadWidgetControl.needHeader = true;
    super.initState();
  }

  @override
  requestRefresh() async {
    return await EventDao.getEventDao(_getUserName(), page: page);
  }

  @override
  requestLoadMore() async {
    return await EventDao.getEventDao(_getUserName(), page: page);
  }

  @override
  bool get isRefreshFirst => false;

  @override
  bool get needHeader => true;

  @override
  void didChangeDependencies() {
    if (pullLoadWidgetControl.dataList.length == 0) {
      showRefreshLoading();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return GSYPullLoadWidget(
          pullLoadWidgetControl,
          (BuildContext context, int index) => _renderEventItem(store.state.userInfo, index),
          handleRefresh,
          onLoadMore,
          refreshKey: refreshIndicatorKey,
        );
      },
    );
  }
}
