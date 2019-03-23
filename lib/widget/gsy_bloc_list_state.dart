import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/bloc/base/base_bloc.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';

/**
 * 上下拉刷新列表的通用State
 * Created by guoshuyu
 * Date: 2018-07-20
 */
mixin GSYListState<T extends StatefulWidget> on State<T>, AutomaticKeepAliveClientMixin<T> {

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  bool isShow = false;

  bool isLoading = false;


  showRefreshLoading() {
    new Future.delayed(const Duration(seconds: 0), () {
      refreshIndicatorKey.currentState.show().then((e) {});
      return true;
    });
  }

  @protected
  resolveRefreshResult(res) {
    if (res != null && res.result) {
      if (isShow) {
        bloc.refreshData(res.data);
      }
    }
  }

  @protected
  Future<Null> handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    var res = await requestRefresh();
    resolveRefreshResult(res);
    if (res.next != null) {
      var resNext = await res.next;
      resolveRefreshResult(resNext);
    }
    isLoading = false;
    return null;
  }

  @protected
  Future<Null> onLoadMore() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    var res = await requestLoadMore();
    if (res != null && res.result) {
      if (isShow) {
        bloc.loadMoreData(res.data);
      }
    }
    isLoading = false;
    return null;
  }

  @protected
  clearData() {
    if (isShow) {
      bloc.clearData();
    }
  }

  ///下拉刷新数据
  @protected
  requestRefresh();

  ///上拉更多请求数据
  @protected
  requestLoadMore();

  ///是否需要第一次进入自动刷新
  @protected
  bool get isRefreshFirst;

  ///是否需要头部
  @protected
  bool get needHeader => false;

  ///是否需要保持
  @override
  bool get wantKeepAlive => true;

  @protected
  BlocListBase get bloc;

  @override
  void initState() {
    isShow = true;
    super.initState();
    if (bloc.getDataLength() == 0 && isRefreshFirst) {
      showRefreshLoading();
    }
  }

  @override
  void dispose() {
    isShow = false;
    isLoading = false;
    super.dispose();
  }
}
