import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/UserHeader.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class PersonPage extends StatefulWidget {
  static final String sName = "person";

  final String userName;

  PersonPage(this.userName, {Key key}) : super(key: key);

  @override
  _PersonState createState() => _PersonState(userName);
}

// ignore: mixin_inherits_from_not_object
class _PersonState extends State<PersonPage> with AutomaticKeepAliveClientMixin {
  final String userName;

  User userInfo = User.empty();

  _PersonState(this.userName);

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
    var userResult = await UserDao.getUserInfo(userName);
    if (userResult != null && userResult.result) {
      userInfo = userResult.data;
      setState(() {
        userInfo = userResult.data;
      });
    } else {
      return null;
    }

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

  _renderEventItem(index) {
    if (index == 0) {
      return new UserHeaderItem(userInfo);
    }
    return new EventItem(pullLoadWidgetControl.dataList[index - 1]);
  }

  _getUserName() {
    if (userInfo == null) {
      return new User.empty();
    }
    return userInfo.login;
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
    return new Scaffold(
        appBar: new AppBar(
          title: new Text((userInfo != null && userInfo.login != null) ? userInfo.login : ""),
        ),
        body: GSYPullLoadWidget(pullLoadWidgetControl, (BuildContext context, int index) => _renderEventItem(index), _handleRefresh, _onLoadMore));
  }
}
