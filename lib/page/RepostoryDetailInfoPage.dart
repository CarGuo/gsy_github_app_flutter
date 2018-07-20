import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/ReposHeaderItem.dart';

/**
 * 仓库详情动态信息页面
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class ReposDetailInfoPage extends StatefulWidget {
  final String userName;

  final String reposName;
  final ReposDetailInfoPageControl reposDetailInfoPageControl;

  ReposDetailInfoPage(this.reposDetailInfoPageControl, this.userName, this.reposName);

  @override
  _ReposDetailInfoPageState createState() => _ReposDetailInfoPageState(reposDetailInfoPageControl, userName, reposName);
}

// ignore: mixin_inherits_from_not_object
class _ReposDetailInfoPageState extends State<ReposDetailInfoPage> with AutomaticKeepAliveClientMixin {
  final String userName;

  final String reposName;

  bool isLoading = false;

  int page = 1;

  final List dataList = new List();

  final ReposDetailInfoPageControl reposDetailInfoPageControl;

  final GSYPullLoadWidgetControl pullLoadWidgetControl = new GSYPullLoadWidgetControl();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  _ReposDetailInfoPageState(this.reposDetailInfoPageControl, this.userName, this.reposName);

  Future<Null> _handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page = 1;
    var res = await ReposDao.getRepositoryEventDao(userName, reposName, page: page);
    if (res != null && res.result) {
      pullLoadWidgetControl.dataList.clear();
      setState(() {
        pullLoadWidgetControl.dataList.addAll(res.data);
      });
    }
    setState(() {
      pullLoadWidgetControl.needLoadMore = (res != null && res.data != null && res.data.length == Config.PAGE_SIZE);
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
    var res = await ReposDao.getRepositoryEventDao(userName, reposName, page: page);
    if (res != null && res.result) {
      setState(() {
        pullLoadWidgetControl.dataList.addAll(res.data);
      });
    }
    setState(() {
      pullLoadWidgetControl.needLoadMore = (res != null && res.data != null && res.data.length == Config.PAGE_SIZE);
    });
    isLoading = false;
    return null;
  }

  _renderEventItem(index) {
    if (index == 0) {
      return new ReposHeaderItem(reposDetailInfoPageControl.reposHeaderViewModel);
    }

    EventViewModel eventViewModel = pullLoadWidgetControl.dataList[index - 1];
    return new EventItem(
      pullLoadWidgetControl.dataList[index - 1],
      onPressed: () {
        EventUtils.ActionUtils(context, eventViewModel.eventMap, "");
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    pullLoadWidgetControl.needHeader = true;
    pullLoadWidgetControl.dataList = dataList;
    if (pullLoadWidgetControl.dataList.length == 0) {
      new Future.delayed(const Duration(seconds: 0), () {
        _refreshIndicatorKey.currentState.show().then((e) {});
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return GSYPullLoadWidget(
      pullLoadWidgetControl,
      (BuildContext context, int index) => _renderEventItem(index),
      _handleRefresh,
      _onLoadMore,
      refreshKey: _refreshIndicatorKey,
    );
  }
}

class ReposDetailInfoPageControl {
  ReposHeaderViewModel reposHeaderViewModel = new ReposHeaderViewModel();
}
