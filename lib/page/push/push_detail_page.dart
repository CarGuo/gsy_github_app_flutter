import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/model/PushCommit.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/page/push/widget/push_coed_item.dart';
import 'package:gsy_github_app_flutter/page/push/widget/push_header.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';

/**
 * 提交信息详情页
 * Created by guoshuyu
 * Date: 2018-07-27
 */

class PushDetailPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String? sha;

  final bool needHomeIcon;

  PushDetailPage(this.sha, this.userName, this.reposName,
      {this.needHomeIcon = false});

  @override
  _PushDetailPageState createState() => _PushDetailPageState();
}

class _PushDetailPageState extends State<PushDetailPage>
    with
        AutomaticKeepAliveClientMixin<PushDetailPage>,
        GSYListState<PushDetailPage> {
  ///提价信息页面的头部数据实体
  PushHeaderViewModel pushHeaderViewModel = new PushHeaderViewModel();

  String? htmlUrl;

  @override
  Future<Null> handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page = 1;

    ///获取提交信息
    var res = await _getDataLogic();
    if (res != null && res.result) {
      PushCommit? pushCommit = res.data;
      pullLoadWidgetControl.dataList.clear();
      if (isShow) {
        setState(() {
          pushHeaderViewModel = PushHeaderViewModel.forMap(pushCommit!);
          pullLoadWidgetControl.dataList.addAll(pushCommit.files!);
          pullLoadWidgetControl.needLoadMore.value = false;
          htmlUrl = pushCommit.htmlUrl;
        });
      }
    }
    isLoading = false;
    return null;
  }

  ///绘制头部和提交item
  _renderEventItem(index) {
    if (index == 0) {
      return new PushHeader(pushHeaderViewModel);
    }
    PushCodeItemViewModel itemViewModel = PushCodeItemViewModel.fromMap(
        pullLoadWidgetControl.dataList[index - 1]);
    return new PushCodeItem(itemViewModel, () {
      String html = HtmlUtils.generateCode2HTml(
          HtmlUtils.parseDiffSource(itemViewModel.patch, false),
          backgroundColor: GSYColors.webDraculaBackgroundColorString,
          lang: '',
          userBR: false);
      NavigatorUtils.gotoCodeDetailPlatform(
        context,
        title: itemViewModel.name,
        reposName: widget.reposName,
        userName: widget.userName,
        path: itemViewModel.patch,
        data: new Uri.dataFromString(html,
                mimeType: 'text/html', encoding: Encoding.getByName("utf-8"))
            .toString(),
        branch: "",
      );
    });
  }

  _getDataLogic() async {
    return await ReposDao.getReposCommitsInfoDao(
        widget.userName, widget.reposName, widget.sha);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {}

  @override
  requestLoadMore() async {
    return null;
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    Widget? widgetContent =
        (widget.needHomeIcon) ? null : new GSYCommonOptionWidget(url: htmlUrl);
    return new Scaffold(
      appBar: new AppBar(
        title: GSYTitleBar(
          widget.reposName,
          rightWidget: widgetContent,
          needRightLocalIcon: widget.needHomeIcon,
          iconData: GSYICons.HOME,
          onRightIconPressed: (_) {
            NavigatorUtils.goReposDetail(
                context, widget.userName, widget.reposName);
          },
        ),
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderEventItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
