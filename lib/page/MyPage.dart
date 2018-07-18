
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/UserHeader.dart';
import 'package:redux/redux.dart';
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

// ignore: mixin_inherits_from_not_object
class _MyPageState extends State<MyPage>  with AutomaticKeepAliveClientMixin  {

  bool isLoading = false;

  int page = 1;

  final List dataList = new List();

  final GSYPullLoadWidgetControl pullLoadWidgetControl = new GSYPullLoadWidgetControl();

  Future<Null> _handleRefresh() async {
    return null;
  }

  Future<Null> _onLoadMore() async {
    return null;
  }

  _renderEventItem(userInfo, index) {
    if(index == 0) {
      return new UserHeaderItem(userInfo);
    }
  }

  Store<GSYState> _getStore() {
    return StoreProvider.of(context);
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
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return GSYPullLoadWidget(pullLoadWidgetControl, (BuildContext context, int index) => _renderEventItem(store.state.userInfo, index),
            _handleRefresh, _onLoadMore);
      },
    );
  }
}
