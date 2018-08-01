import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/common/model/Repository.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailPage.dart';
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

  final ReposDetailParentControl reposDetailParentControl;

  ReposDetailInfoPage(this.reposDetailInfoPageControl, this.userName, this.reposName, this.reposDetailParentControl, {Key key}) : super(key: key);

  @override
  ReposDetailInfoPageState createState() => ReposDetailInfoPageState(reposDetailInfoPageControl, userName, reposName, reposDetailParentControl);
}

// ignore: mixin_inherits_from_not_object
class ReposDetailInfoPageState extends GSYListState<ReposDetailInfoPage> {
  final String userName;

  final String reposName;

  final ReposDetailInfoPageControl reposDetailInfoPageControl;

  final ReposDetailParentControl reposDetailParentControl;

  int selectIndex = 0;

  ReposDetailInfoPageState(this.reposDetailInfoPageControl, this.userName, this.reposName, this.reposDetailParentControl);

  _renderEventItem(index) {
    if (index == 0) {
      return new ReposHeaderItem(ReposHeaderViewModel.fromHttpMap(userName, reposName, reposDetailInfoPageControl.repository), (index) {
        selectIndex = index;
        clearData();
        showRefreshLoading();
      });
    }

    if (selectIndex == 1) {
      return new EventItem(
        EventViewModel.fromCommitMap(pullLoadWidgetControl.dataList[index - 1]),
        onPressed: () {
          RepoCommit model = pullLoadWidgetControl.dataList[index - 1];
          NavigatorUtils.goPushDetailPage(context, userName, reposName, model.sha, false);
        },
        needImage: false,
      );
    }
    return new EventItem(
      EventViewModel.fromEventMap(pullLoadWidgetControl.dataList[index - 1]),
      onPressed: () {
        EventUtils.ActionUtils(context, pullLoadWidgetControl.dataList[index - 1], userName + "/" + reposName);
      },
    );
  }

  _getDataLogic() async {
    if (selectIndex == 1) {
      return await ReposDao.getReposCommitsDao(userName, reposName, page: page, branch: reposDetailParentControl.currentBranch);
    }
    return await ReposDao.getRepositoryEventDao(userName, reposName, page: page, branch: reposDetailParentControl.currentBranch);
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
  Repository repository =  Repository.empty();
}
