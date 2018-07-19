import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
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
class _DynamicPageState extends State<DynamicPage> with AutomaticKeepAliveClientMixin {
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
    var result = await EventDao.getEventReceived(_getStore(), page: page);
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
    var result = await EventDao.getEventReceived(_getStore(), page: page);
    setState(() {
      pullLoadWidgetControl.needLoadMore = (result != null);
    });
    isLoading = false;
    return null;
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    pullLoadWidgetControl.dataList = _getStore().state.eventList;
    if (pullLoadWidgetControl.dataList.length == 0) {
      _handleRefresh();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return GSYPullLoadWidget(pullLoadWidgetControl, (BuildContext context, int index) => _renderEventItem(pullLoadWidgetControl.dataList[index]),
            _handleRefresh, _onLoadMore);
      },
    );
  }
}
