import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/common/model/Repository.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/repository_detail_page.dart';
import 'package:gsy_github_app_flutter/widget/event_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/repos_header_item.dart';
import 'package:scoped_model/scoped_model.dart';

/**
 * 仓库详情动态信息页面
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class ReposDetailInfoPage extends StatefulWidget {
  final String userName;

  final String reposName;

  final OptionControl titleOptionControl;

  ReposDetailInfoPage(this.userName, this.reposName, this.titleOptionControl,
      {Key key})
      : super(key: key);

  @override
  ReposDetailInfoPageState createState() => ReposDetailInfoPageState();
}

class ReposDetailInfoPageState extends State<ReposDetailInfoPage>
    with
        AutomaticKeepAliveClientMixin<ReposDetailInfoPage>,
        GSYListState<ReposDetailInfoPage> {
  Repository repository = Repository.empty();

  int selectIndex = 0;

  ReposDetailInfoPageState();

  ///渲染时间Item或者提交Item
  _renderEventItem(index) {
    if (index == 0) {
      return new ReposHeaderItem(
          ReposHeaderViewModel.fromHttpMap(
              widget.userName, widget.reposName, repository), (index) {
        selectIndex = index;
        clearData();
        showRefreshLoading();
      });
    }

    if (selectIndex == 1) {
      ///提交
      return new EventItem(
        EventViewModel.fromCommitMap(pullLoadWidgetControl.dataList[index - 1]),
        onPressed: () {
          RepoCommit model = pullLoadWidgetControl.dataList[index - 1];
          NavigatorUtils.goPushDetailPage(
              context, widget.userName, widget.reposName, model.sha, false);
        },
        needImage: false,
      );
    }
    return new EventItem(
      EventViewModel.fromEventMap(pullLoadWidgetControl.dataList[index - 1]),
      onPressed: () {
        EventUtils.ActionUtils(
            context,
            pullLoadWidgetControl.dataList[index - 1],
            widget.userName + "/" + widget.reposName);
      },
    );
  }

  ///获取列表
  _getDataLogic() async {
    if (selectIndex == 1) {
      return await ReposDao.getReposCommitsDao(
        widget.userName,
        widget.reposName,
        page: page,
        branch: ReposDetailModel.of(context).currentBranch,
        needDb: page <= 1,
      );
    }
    return await ReposDao.getRepositoryEventDao(
      widget.userName,
      widget.reposName,
      page: page,
      branch: ReposDetailModel.of(context).currentBranch,
      needDb: page <= 1,
    );
  }

  ///获取详情
  _getReposDetail() {
    ReposDao.getRepositoryDetailDao(widget.userName, widget.reposName,
            ReposDetailModel.of(context).currentBranch)
        .then((result) {
      if (result != null && result.result) {
        setState(() {
          repository = result.data;
          widget.titleOptionControl.url = repository.htmlUrl;
        });
        return result.next;
      }
      return new Future.value(null);
    }).then((result) {
      if (result != null && result.result) {
        setState(() {
          repository = result.data;
          widget.titleOptionControl.url = repository.htmlUrl;
        });
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    _getReposDetail();
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
    super.build(context); //

    return ScopedModelDescendant<ReposDetailModel>(
      builder: (context, child, model) {
        return GSYPullLoadWidget(
          pullLoadWidgetControl,
          (BuildContext context, int index) => _renderEventItem(index),
          handleRefresh,
          onLoadMore,
          refreshKey: refreshIndicatorKey,
        );
      },
    ); // See
  }
}
