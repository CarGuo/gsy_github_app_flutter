import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/model/PushCommit.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCommonOptionWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/widget/PushCoedItem.dart';
import 'package:gsy_github_app_flutter/widget/PushHeader.dart';
import 'package:gsy_github_app_flutter/common/utils/HtmlUtils.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-27
 */

class PushDetailPage extends StatefulWidget {
  final String userName;

  final String reposName;

  final String sha;

  final bool needHomeIcon;

  PushDetailPage(this.sha, this.userName, this.reposName, {this.needHomeIcon = false});

  @override
  _PushDetailPageState createState() => _PushDetailPageState(sha, userName, reposName, needHomeIcon);
}

class _PushDetailPageState extends State<PushDetailPage> with AutomaticKeepAliveClientMixin<PushDetailPage>, GSYListState<PushDetailPage> {
  final String userName;

  final String reposName;

  final String sha;

  bool needHomeIcon = false;

  PushHeaderViewModel pushHeaderViewModel = new PushHeaderViewModel();

  final OptionControl titleOptionControl = new OptionControl();

  _PushDetailPageState(this.sha, this.userName, this.reposName, this.needHomeIcon);

  @override
  Future<Null> handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page = 1;
    var res = await _getDataLogic();
    if (res != null && res.result) {
      PushCommit pushCommit = res.data;
      pullLoadWidgetControl.dataList.clear();
      if (isShow) {
        setState(() {
          pushHeaderViewModel = PushHeaderViewModel.forMap(pushCommit);
          pullLoadWidgetControl.dataList.addAll(pushCommit.files);
          pullLoadWidgetControl.needLoadMore = false;
          titleOptionControl.url = pushCommit.htmlUrl;
        });
      }
    }
    isLoading = false;
    return null;
  }

  _renderEventItem(index) {
    if (index == 0) {
      return new PushHeader(pushHeaderViewModel);
    }
    PushCodeItemViewModel itemViewModel = PushCodeItemViewModel.fromMap(pullLoadWidgetControl.dataList[index - 1]);
    return new PushCodeItem(itemViewModel, () {
      if (Platform.isIOS) {
        NavigatorUtils.gotoCodeDetailPage(
          context,
          title: itemViewModel.name,
          userName: userName,
          reposName: reposName,
          data: itemViewModel.patch,
          htmlUrl: itemViewModel.blob_url,
        );
      } else {
        String html = HtmlUtils.generateCode2HTml(HtmlUtils.parseDiffSource(itemViewModel.patch, false),
            backgroundColor: GSYColors.webDraculaBackgroundColorString, lang: '', userBR: false);
        CommonUtils.launchWebView(context, itemViewModel.name, html);
      }
    });
  }

  _getDataLogic() async {
    return await ReposDao.getReposCommitsInfoDao(userName, reposName, sha);
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
    Widget widget = (needHomeIcon) ? null : new GSYCommonOptionWidget(titleOptionControl);
    return new Scaffold(
      appBar: new AppBar(
        title: GSYTitleBar(
          reposName,
          rightWidget: widget,
          needRightLocalIcon: needHomeIcon,
          iconData: GSYICons.HOME,
          onPressed: () {
            NavigatorUtils.goReposDetail(context, userName, reposName);
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
