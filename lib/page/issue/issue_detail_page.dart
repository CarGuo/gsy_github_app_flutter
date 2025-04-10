import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_flex_button.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_header_item.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_item.dart';

/// Issue 详情页面
/// Created by guoshuyu
/// on 2018/7/21.

class IssueDetailPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String issueNum;

  final bool needHomeIcon;

  const IssueDetailPage(this.userName, this.reposName, this.issueNum,
      {super.key, this.needHomeIcon = false});

  @override
  _IssueDetailPageState createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage>
    with
        AutomaticKeepAliveClientMixin<IssueDetailPage>,
        GSYListState<IssueDetailPage> {
  int selectIndex = 0;

  ///头部信息数据是否加载成功，成功了就可以显示底部状态
  bool headerStatus = false;

  String? htmlUrl;

  /// issue 的头部数据显示
  IssueHeaderViewModel issueHeaderViewModel = IssueHeaderViewModel();

  ///控制编辑时issue的title
  TextEditingController issueInfoTitleControl = TextEditingController();

  ///控制编辑时issue的content
  TextEditingController issueInfoValueControl = TextEditingController();

  ///绘制item
  _renderEventItem(index) {
    ///第一个绘制的是头部
    if (index == 0) {
      return IssueHeaderItem(issueHeaderViewModel, onPressed: () {});
    }
    Issue issue = pullLoadWidgetControl.dataList[index - 1];
    return IssueItem(
      IssueItemViewModel.fromMap(issue, needTitle: false),
      hideBottom: true,
      limitComment: false,
      onPressed: () {
        NavigatorUtils.showGSYDialog(
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(4.0)),
                      color: GSYColors.white,
                      border: Border.all(
                          color: GSYColors.subTextColor, width: 0.3)),
                  margin: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GSYFlexButton(
                        color: GSYColors.white,
                        textColor: GSYColors.primaryDarkValue,
                        text: context.l10n.issue_edit_issue_edit_commit,
                        onPress: () {
                          _editCommit(issue.id.toString(), issue.body);
                        },
                      ),
                      GSYFlexButton(
                        color: GSYColors.white,
                        text: context.l10n.issue_edit_issue_delete_commit,
                        onPress: () {
                          _deleteCommit(issue.id.toString());
                        },
                      ),
                      GSYFlexButton(
                        color: GSYColors.white,
                        text: context.l10n.issue_edit_issue_copy_commit,
                        onPress: () {
                          CommonUtils.copy(issue.body, context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            });
      },
    );
  }

  ///获取页面数据
  _getDataLogic() async {
    ///刷新时同时更新头部信息
    if (page <= 1) {
      _getHeaderInfo();
    }
    return await IssueRepository.getIssueCommentRequest(
        widget.userName, widget.reposName, widget.issueNum,
        page: page, needDb: page <= 1);
  }

  ///获取头部数据
  _getHeaderInfo() {
    IssueRepository.getIssueInfoRequest(
            widget.userName, widget.reposName, widget.issueNum)
        .then((res) {
      if (res != null && res.result) {
        _resolveHeaderInfo(res);
        return res.next?.call();
      }
      return Future.value(null);
    }).then((res) {
      if (res != null && res.result) {
        _resolveHeaderInfo(res);
      }
    });
  }

  ///数据转化显示
  _resolveHeaderInfo(res) {
    Issue? issue = res.data;
    setState(() {
      issueHeaderViewModel = IssueHeaderViewModel.fromMap(issue!);
      htmlUrl = issue.htmlUrl;
      headerStatus = true;
    });
  }

  ///编辑回复
  _editCommit(id, content) {
    Navigator.pop(context);
    String? contentData = content;
    issueInfoValueControl = TextEditingController(text: contentData);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      context.l10n.issue_edit_issue,
      null,
      (contentValue) {
        contentData = contentValue;
      },
      () {
        if (contentData == null || contentData!.trim().isEmpty) {
          showToast(context.l10n.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueRepository.editCommentRequest(widget.userName, widget.reposName,
            widget.issueNum, id, {"body": contentData}).then((result) {
          showRefreshLoading();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      valueController: issueInfoValueControl,
      needTitle: false,
    );
  }

  ///删除回复
  _deleteCommit(id) {
    Navigator.pop(context);
    CommonUtils.showLoadingDialog(context);
    //提交修改
    IssueRepository.deleteCommentRequest(
            widget.userName, widget.reposName, widget.issueNum, id)
        .then((result) {
      Navigator.pop(context);
      showRefreshLoading();
    });
  }

  ///编译 issue
  _editIssue() {
    String? title = issueHeaderViewModel.issueComment;
    String? content = issueHeaderViewModel.issueDesHtml;
    issueInfoTitleControl = TextEditingController(text: title);
    issueInfoValueControl = TextEditingController(text: content);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      context.l10n.issue_edit_issue,
      (titleValue) {
        title = titleValue;
      },
      (contentValue) {
        content = contentValue;
      },
      () {
        if (title == null || title!.trim().isEmpty) {
          showToast(context.l10n.issue_edit_issue_title_not_be_null);
          return;
        }
        if (content == null || content!.trim().isEmpty) {
          showToast(context.l10n.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueRepository.editIssueRequest(widget.userName, widget.reposName,
            widget.issueNum, {"title": title, "body": content}).then((result) {
          _getHeaderInfo();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      titleController: issueInfoTitleControl,
      valueController: issueInfoValueControl,
      needTitle: true,
    );
  }

  ///回复 issue
  _replyIssue() {
    //回复 Info
    issueInfoTitleControl = TextEditingController(text: "");
    issueInfoValueControl = TextEditingController(text: "");
    String? content = "";
    CommonUtils.showEditDialog(
      context,
      context.l10n.issue_reply_issue,
      null,
      (replyContent) {
        content = replyContent;
      },
      () {
        if (content == null || content?.trim().isEmpty == true) {
          showToast(context.l10n.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交评论
        IssueRepository.addIssueCommentRequest(
                widget.userName, widget.reposName, widget.issueNum, content)
            .then((result) {
          showRefreshLoading();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      needTitle: false,
      titleController: issueInfoTitleControl,
      valueController: issueInfoValueControl,
    );
  }

  ///获取底部状态控件显示
  _getBottomWidget() {
    List<Widget> bottomWidget = (!headerStatus)
        ? []
        : <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _replyIssue();
                  },
                  child: Text(context.l10n.issue_reply,
                      style: GSYConstant.smallText),
                ),
                Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                TextButton(
                  onPressed: () {
                    _editIssue();
                  },
                  child: Text(context.l10n.issue_edit,
                      style: GSYConstant.smallText),
                ),
                Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                TextButton(
                    onPressed: () {
                      CommonUtils.showLoadingDialog(context);
                      IssueRepository.editIssueRequest(
                          widget.userName, widget.reposName, widget.issueNum, {
                        "state": (issueHeaderViewModel.state == "closed")
                            ? 'open'
                            : 'closed'
                      }).then((result) {
                        _getHeaderInfo();
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                        (issueHeaderViewModel.state == 'closed')
                            ? context.l10n.issue_open
                            : context.l10n.issue_close,
                        style: GSYConstant.smallText)),
                Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                TextButton(
                    onPressed: () {
                      CommonUtils.showLoadingDialog(context);
                      IssueRepository.lockIssueRequest(
                              widget.userName,
                              widget.reposName,
                              widget.issueNum,
                              issueHeaderViewModel.locked)
                          .then((result) {
                        _getHeaderInfo();
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                        issueHeaderViewModel.locked!
                            ? context.l10n.issue_unlock
                            : context.l10n.issue_lock,
                        style: GSYConstant.smallText)),
              ],
            )
          ];
    return bottomWidget;
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
    Widget? widgetContent =
        (widget.needHomeIcon) ? null : GSYCommonOptionWidget(url: htmlUrl);
    return Scaffold(
      persistentFooterButtons: _getBottomWidget(),
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
