import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
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
class _ReposDetailInfoPageState extends GSYListState<ReposDetailInfoPage> {
  final String userName;

  final String reposName;

  final ReposDetailInfoPageControl reposDetailInfoPageControl;

  int selectIndex = 0;

  _ReposDetailInfoPageState(this.reposDetailInfoPageControl, this.userName, this.reposName);

  _renderEventItem(index) {
    if (index == 0) {
      return new ReposHeaderItem(reposDetailInfoPageControl.reposHeaderViewModel, (index) {
        selectIndex = index;
        clearData();
        showRefreshLoading();
      });
    }

    EventViewModel eventViewModel = pullLoadWidgetControl.dataList[index - 1];


    if (selectIndex == 1) {
      return new EventItem(
        pullLoadWidgetControl.dataList[index - 1],
        onPressed: () {;
        },
        needImage: false,
      );
    }
    return new EventItem(
      pullLoadWidgetControl.dataList[index - 1],
      onPressed: () {
        EventUtils.ActionUtils(context, eventViewModel.eventMap, userName + "/" + reposName);
      },
    );
  }

  _getDataLogic() async {
    if (selectIndex == 1) {
      return await ReposDao.getReposCommitsDao(userName, reposName, page: page);
    }
    return await ReposDao.getRepositoryEventDao(userName, reposName, page: page);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return GSYPullLoadWidget(
      pullLoadWidgetControl,
      (BuildContext context, int index) => _renderEventItem(index),
      handleRefresh,
      onLoadMore,
      refreshKey: refreshIndicatorKey,
    );
  }
}

class ReposDetailInfoPageControl {
  ReposHeaderViewModel reposHeaderViewModel = new ReposHeaderViewModel();
}
