import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/ReposHeaderItem.dart';

/**
 * 仓库详情动态信息页面
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class ReposDetailInfoPage extends StatefulWidget {
  @override
  _ReposDetailInfoPageState createState() => _ReposDetailInfoPageState();
}

// ignore: mixin_inherits_from_not_object
class _ReposDetailInfoPageState extends State<ReposDetailInfoPage> with AutomaticKeepAliveClientMixin {
  bool isLoading = false;

  int page = 1;

  final List dataList = new List();

  final GSYPullLoadWidgetControl pullLoadWidgetControl = new GSYPullLoadWidgetControl();

  Future<Null> _handleRefresh() async {
   /* if (isLoading) {
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
    isLoading = false;*/
    return null;
  }

  Future<Null> _onLoadMore() async {
    /*if (isLoading) {
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
    isLoading = false;*/
    return null;
  }

  _renderEventItem(index) {
    if (index == 0) {
      return new ReposHeaderItem();
    }
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
    return GSYPullLoadWidget(pullLoadWidgetControl, (BuildContext context, int index) => _renderEventItem(index), _handleRefresh, _onLoadMore);
  }
}
