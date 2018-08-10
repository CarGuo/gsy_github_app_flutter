import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/model/UserOrg.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/redux/UserRedux.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/UserHeader.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';
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
  String beStaredCount = '---';

  Color notifyColor = const Color(GSYColors.subTextColor);

  final List<UserOrg> orgList = new List();

  _renderEventItem(userInfo, index) {
    if (index == 0) {
      return new UserHeaderItem(
        userInfo,
        beStaredCount,
        notifyColor: notifyColor,
        refreshCallBack: () {
          _refreshNotify();
        },
        orgList: orgList,
      );
    }

    if (getUserType() == "Organization") {
      return new UserItem(UserItemViewModel.fromMap(pullLoadWidgetControl.dataList[index - 1]), onPressed: () {
        NavigatorUtils.goPerson(context, UserItemViewModel.fromMap(pullLoadWidgetControl.dataList[index - 1]).userName);
      });
    } else {
      Event event = pullLoadWidgetControl.dataList[index - 1];
      return new EventItem(EventViewModel.fromEventMap(event), onPressed: () {
        EventUtils.ActionUtils(context, event, "");
      });
    }
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

  getUserType() {
    if (_getStore().state.userInfo == null) {
      return null;
    }
    return _getStore().state.userInfo.type;
  }

  _refreshNotify() {
    UserDao.getNotifyDao(false, false, 0).then((res) {
      if (res != null && res.result && res.data.length > 0) {
        notifyColor = Colors.blue;
      } else {
        notifyColor = Color(GSYColors.subTextColor);
      }
    });
  }

  _getUserOrg(String userName) {
    if (page <= 1) {
      UserDao.getUserOrgsDao(userName, page, needDb: true).then((res) {
        if (res != null && res.result) {
          setState(() {
            orgList.clear();
            orgList.addAll(res.data);
          });
          return res.next;
        }
        return new Future.value(null);
      }).then((res) {
        if (res != null && res.result) {
          setState(() {
            orgList.clear();
            orgList.addAll(res.data);
          });
        }
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    pullLoadWidgetControl.needHeader = true;
    super.initState();
  }

  _getDataLogic() async {
    if (getUserType() == "Organization") {
      return await UserDao.getMemberDao(_getUserName(), page);
    }
    return await EventDao.getEventDao(_getUserName(), page: page, needDb: page <= 1);
  }

  @override
  requestRefresh() async {
    UserDao.getUserInfo(null).then((res) {
      if (res != null && res.result) {
        _getStore().dispatch(UpdateUserAction(res.data));
        _getUserOrg(_getUserName());
      }
    });
    ReposDao.getUserRepository100StatusDao(_getUserName()).then((res) {
      if (res != null && res.result) {
        if (isShow) {
          setState(() {
            beStaredCount = res.data.toString();
          });
        }
      }
    });
    _refreshNotify();
    return await _getDataLogic();
  }

  @override
  requestLoadMore() async {
    return await _getDataLogic();
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
