import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/model/push_commit.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/page/push/widget/push_coed_item.dart';
import 'package:gsy_github_app_flutter/page/push/widget/push_header.dart';
import 'package:gsy_github_app_flutter/common/utils/diff_html_renderer.dart';

/// 提交信息详情页
/// Created by guoshuyu
/// Date: 2018-07-27

class PushDetailPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String? sha;

  final bool needHomeIcon;

  const new(this.sha, this.userName, this.reposName,
      {super.key, this.needHomeIcon = false});

  @override
  _PushDetailPageState createState() => _PushDetailPageState();
}

class _PushDetailPageState extends State<PushDetailPage>
    with
        AutomaticKeepAliveClientMixin<PushDetailPage>,
        GSYListState<PushDetailPage> {
  ///提价信息页面的头部数据实体
  PushHeaderViewModel pushHeaderViewModel = PushHeaderViewModel();

  String? htmlUrl;

  bool _openingDiff = false;

  @override
  Future<void> handleRefresh() async {
    if (isLoading) {
      return;
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
    return;
  }

  ///绘制头部和提交item
  _renderEventItem(index) {
    if (index == 0) {
      return PushHeader(pushHeaderViewModel);
    }
    PushCodeItemViewModel itemViewModel = PushCodeItemViewModel.fromMap(
        pullLoadWidgetControl.dataList[index - 1]);
    return PushCodeItem(itemViewModel, () => _openDiff(itemViewModel));
  }

  Future<void> _openDiff(PushCodeItemViewModel file) async {
    // 2026-10-24 FPR-103: one job owns this opening intent. Keep UI/context and
    // navigation on the caller; only pure HTML preparation crosses isolates.
    if (_openingDiff) return;
    _openingDiff = true;
    final title = file.name;
    final patch = file.patch;
    final userName = widget.userName;
    final reposName = widget.reposName;
    final sourceRoutes = <Route<dynamic>>[];
    ModalRoute<dynamic>? sourceRoute = ModalRoute.of(context);
    while (sourceRoute != null && !sourceRoutes.contains(sourceRoute)) {
      sourceRoutes.add(sourceRoute);
      final navigator = sourceRoute.navigator;
      sourceRoute = navigator == null ? null : ModalRoute.of(navigator.context);
    }
    try {
      final html = await renderDiffHtml(DiffHtmlRequest(patch: patch));
      if (!mounted || sourceRoutes.any((route) => !route.isCurrent)) return;
      NavigatorUtils.gotoCodeDetailPlatform(
        context,
        title: title,
        reposName: reposName,
        userName: userName,
        path: patch,
        data: html,
        branch: '',
      );
    } catch (error, stack) {
      // 2026-10-24: async work must retain Flutter's gesture error reporting.
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'diff rendering',
        context: ErrorDescription('while preparing a commit diff'),
      ));
    } finally {
      _openingDiff = false;
    }
  }

  _getDataLogic() async {
    return await ReposRepository.getReposCommitsInfoRequest(
        widget.userName!, widget.reposName!, widget.sha);
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
        (widget.needHomeIcon) ? null : GSYCommonOptionWidget(url: htmlUrl);
    return Scaffold(
      appBar: AppBar(
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
