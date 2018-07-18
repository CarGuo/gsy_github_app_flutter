import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
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
class _MyPageState extends State<MyPage> with AutomaticKeepAliveClientMixin {
  bool isLoading = false;

  int page = 1;

  final List dataList = new List();

  final GSYPullLoadWidgetControl pullLoadWidgetControl = new GSYPullLoadWidgetControl();

  Future<Null> _handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page = 1;
    var result = await EventDao.getEventDao(_getUserName(), page: page);
    if (result != null && result.length > 0) {
      pullLoadWidgetControl.dataList.clear();
      setState(() {
        pullLoadWidgetControl.dataList.addAll(result);
      });
    }
    setState(() {
      pullLoadWidgetControl.needLoadMore = (result != null && result.length == Config.PAGE_SIZE);
    });
    isLoading = false;
    return null;
  }

  Future<Null> _onLoadMore() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page++;
    var result = await EventDao.getEventDao(_getUserName(), page: page);
    if (result != null && result.length > 0) {
      setState(() {
        pullLoadWidgetControl.dataList.addAll(result);
      });
    }
    setState(() {
      pullLoadWidgetControl.needLoadMore = (result != null);
    });
    isLoading = false;
    return null;
  }

  _renderEventItem(userInfo, index) {
    if (index == 0) {
      return new UserHeaderItem(userInfo);
    }
    return new EventItem(pullLoadWidgetControl.dataList[index - 1]);
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
  void didChangeDependencies() {
    pullLoadWidgetControl.dataList = dataList;
    if (pullLoadWidgetControl.dataList.length == 0) {
      _handleRefresh();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return GSYPullLoadWidget(
            pullLoadWidgetControl, (BuildContext context, int index) => _renderEventItem(store.state.userInfo, index), _handleRefresh, _onLoadMore);
      },
    );
  }
}
