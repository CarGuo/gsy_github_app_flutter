import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/model/UserOrg.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/UserHeader.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';

/**
 * Created by guoshuyu
 * Date: 2018-08-30
 */

abstract class BasePersonState<T extends StatefulWidget> extends State<T> with AutomaticKeepAliveClientMixin<T>, GSYListState<T> {
  final List<UserOrg> orgList = new List();

  @protected
  renderItem(index, User userInfo, String beStaredCount, Color notifyColor, VoidCallback refreshCallBack, List<UserOrg> orgList) {
    if (index == 0) {
      return new UserHeaderItem(userInfo, beStaredCount, Theme.of(context).primaryColor,
          notifyColor: notifyColor, refreshCallBack: refreshCallBack, orgList: orgList);
    }
    if (userInfo.type == "Organization") {
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

  @override
  bool get wantKeepAlive => true;

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => true;

  @protected
  getUserOrg(String userName) {
    if (page <= 1 && userName != null) {
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
}
