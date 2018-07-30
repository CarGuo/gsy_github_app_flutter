import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:redux/redux.dart';

/**
 * 主页动态tab页
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class DynamicPage extends StatefulWidget {
  @override
  _DynamicPageState createState() => _DynamicPageState();
}

// ignore: mixin_inherits_from_not_object
class _DynamicPageState extends GSYListState<DynamicPage> {

  @override
  Future<Null> handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page = 1;
    var result = await EventDao.getEventReceived(_getStore(), page: page);
    setState(() {
      pullLoadWidgetControl.needLoadMore = (result != null && result.length == Config.PAGE_SIZE);
    });
    isLoading = false;
    return null;
  }

  @override
  Future<Null> onLoadMore() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page++;
    var result = await EventDao.getEventReceived(_getStore(), page: page);
    setState(() {
      pullLoadWidgetControl.needLoadMore = (result != null);
    });
    isLoading = false;
    return null;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() {

  }

  @override
  requestLoadMore() {

  }

  @override
  bool get isRefreshFirst => false;

  @override
  void initState() {
    super.initState();
    ReposDao.getNewsVersion(context, false);

  }

  @override
  void didChangeDependencies() {
    pullLoadWidgetControl.dataList = _getStore().state.eventList;
    if (pullLoadWidgetControl.dataList.length == 0) {
      showRefreshLoading();
    }
    super.didChangeDependencies();
  }

  _renderEventItem(EventViewModel e) {
    return new EventItem(
      e,
      onPressed: () {
        EventUtils.ActionUtils(context, e.eventMap, "");
      },
    );
  }

  Store<GSYState> _getStore() {
    return StoreProvider.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return GSYPullLoadWidget(
          pullLoadWidgetControl,
          (BuildContext context, int index) => _renderEventItem(pullLoadWidgetControl.dataList[index]), handleRefresh, onLoadMore, refreshKey: refreshIndicatorKey,
        );
      },
    );
  }
}
