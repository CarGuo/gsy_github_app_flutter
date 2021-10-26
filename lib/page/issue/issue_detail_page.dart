import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/issue_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/model/Issue.dart';
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

/**
 * Issue 详情页面
 * Created by guoshuyu
 * on 2018/7/21.
 */

class IssueDetailPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String issueNum;

  final bool needHomeIcon;

  IssueDetailPage(this.userName, this.reposName, this.issueNum,
      {this.needHomeIcon = false});

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
  IssueHeaderViewModel issueHeaderViewModel = new IssueHeaderViewModel();

  ///控制编辑时issue的title
  TextEditingController issueInfoTitleControl = new TextEditingController();

  ///控制编辑时issue的content
  TextEditingController issueInfoValueControl = new TextEditingController();

  ///绘制item
  _renderEventItem(index) {
    ///第一个绘制的是头部
    if (index == 0) {
      return new IssueHeaderItem(issueHeaderViewModel, onPressed: () {});
    }
    Issue issue = pullLoadWidgetControl.dataList[index - 1];
    return new IssueItem(
      IssueItemViewModel.fromMap(issue, needTitle: false),
      hideBottom: true,
      limitComment: false,
      onPressed: () {
        NavigatorUtils.showGSYDialog(
            context: context,
            builder: (BuildContext context) {
              return new Center(
                child: new Container(
                  decoration: new BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      color: GSYColors.white,
                      border: new Border.all(
                          color: GSYColors.subTextColor, width: 0.3)),
                  margin: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new GSYFlexButton(
                        color: GSYColors.white,
                        textColor: GSYColors.primaryDarkValue,
                        text: GSYLocalizations.i18n(context)!
                            .issue_edit_issue_edit_commit,
                        onPress: () {
                          _editCommit(issue.id.toString(), issue.body);
                        },
                      ),
                      new GSYFlexButton(
                        color: GSYColors.white,
                        text: GSYLocalizations.i18n(context)!
                            .issue_edit_issue_delete_commit,
                        onPress: () {
                          _deleteCommit(issue.id.toString());
                        },
                      ),
                      new GSYFlexButton(
                        color: GSYColors.white,
                        text: GSYLocalizations.i18n(context)!
                            .issue_edit_issue_copy_commit,
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
    return await IssueDao.getIssueCommentDao(
        widget.userName, widget.reposName, widget.issueNum,
        page: page, needDb: page <= 1);
  }

  ///获取头部数据
  _getHeaderInfo() {
    IssueDao.getIssueInfoDao(widget.userName, widget.reposName, widget.issueNum)
        .then((res) {
      if (res != null && res.result) {
        _resolveHeaderInfo(res);
        return res.next?.call();
      }
      return new Future.value(null);
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
    issueInfoValueControl = new TextEditingController(text: contentData);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      GSYLocalizations.i18n(context)!.issue_edit_issue,
      null,
      (contentValue) {
        contentData = contentValue;
      },
      () {
        if (contentData == null || contentData!.trim().length == 0) {
          Fluttertoast.showToast(
              msg: GSYLocalizations.i18n(context)!
                  .issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueDao.editCommentDao(widget.userName, widget.reposName,
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
    IssueDao.deleteCommentDao(
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
    issueInfoTitleControl = new TextEditingController(text: title);
    issueInfoValueControl = new TextEditingController(text: content);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      GSYLocalizations.i18n(context)!.issue_edit_issue,
      (titleValue) {
        title = titleValue;
      },
      (contentValue) {
        content = contentValue;
      },
      () {
        if (title == null || title!.trim().length == 0) {
          Fluttertoast.showToast(
              msg: GSYLocalizations.i18n(context)!
                  .issue_edit_issue_title_not_be_null);
          return;
        }
        if (content == null || content!.trim().length == 0) {
          Fluttertoast.showToast(
              msg: GSYLocalizations.i18n(context)!
                  .issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueDao.editIssueDao(widget.userName, widget.reposName,
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
    issueInfoTitleControl = new TextEditingController(text: "");
    issueInfoValueControl = new TextEditingController(text: "");
    String? content = "";
    CommonUtils.showEditDialog(
      context,
      GSYLocalizations.i18n(context)!.issue_reply_issue,
      null,
      (replyContent) {
        content = replyContent;
      },
      () {
        if (content == null || content?.trim().length == 0) {
          Fluttertoast.showToast(
              msg: GSYLocalizations.i18n(context)!
                  .issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交评论
        IssueDao.addIssueCommentDao(
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
                new TextButton(
                  onPressed: () {
                    _replyIssue();
                  },
                  child: new Text(GSYLocalizations.i18n(context)!.issue_reply,
                      style: GSYConstant.smallText),
                ),
                new Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                new TextButton(
                  onPressed: () {
                    _editIssue();
                  },
                  child: new Text(GSYLocalizations.i18n(context)!.issue_edit,
                      style: GSYConstant.smallText),
                ),
                new Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                new TextButton(
                    onPressed: () {
                      CommonUtils.showLoadingDialog(context);
                      IssueDao.editIssueDao(
                          widget.userName, widget.reposName, widget.issueNum, {
                        "state": (issueHeaderViewModel.state == "closed")
                            ? 'open'
                            : 'closed'
                      }).then((result) {
                        _getHeaderInfo();
                        Navigator.pop(context);
                      });
                    },
                    child: new Text(
                        (issueHeaderViewModel.state == 'closed')
                            ? GSYLocalizations.i18n(context)!.issue_open
                            : GSYLocalizations.i18n(context)!.issue_close,
                        style: GSYConstant.smallText)),
                new Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                new TextButton(
                    onPressed: () {
                      CommonUtils.showLoadingDialog(context);
                      IssueDao.lockIssueDao(widget.userName, widget.reposName,
                              widget.issueNum, issueHeaderViewModel.locked)
                          .then((result) {
                        _getHeaderInfo();
                        Navigator.pop(context);
                      });
                    },
                    child: new Text(
                        issueHeaderViewModel.locked!
                            ? GSYLocalizations.i18n(context)!.issue_unlock
                            : GSYLocalizations.i18n(context)!.issue_lock,
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
        (widget.needHomeIcon) ? null : new GSYCommonOptionWidget(url: htmlUrl);
    return new Scaffold(
      persistentFooterButtons: _getBottomWidget(),
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
