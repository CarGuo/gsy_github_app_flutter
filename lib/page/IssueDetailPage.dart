import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/IssueDao.dart';
import 'package:gsy_github_app_flutter/common/model/Issue.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCommonOptionWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYFlexButton.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/widget/IssueHeaderItem.dart';
import 'package:gsy_github_app_flutter/widget/IssueItem.dart';

/**
 * Created by guoshuyu
 * on 2018/7/21.
 */

class IssueDetailPage extends StatefulWidget {
  final String userName;

  final String reposName;

  final String issueNum;

  final bool needHomeIcon;

  IssueDetailPage(this.userName, this.reposName, this.issueNum, {this.needHomeIcon = false});

  @override
  _IssueDetailPageState createState() => _IssueDetailPageState(issueNum, userName, reposName, needHomeIcon);
}

// ignore: mixin_inherits_from_not_object
class _IssueDetailPageState extends GSYListState<IssueDetailPage> {
  final String userName;

  final String reposName;

  final String issueNum;

  int selectIndex = 0;

  bool headerStatus = false;

  bool needHomeIcon = false;

  IssueHeaderViewModel issueHeaderViewModel = new IssueHeaderViewModel();

  TextEditingController issueInfoTitleControl = new TextEditingController();

  TextEditingController issueInfoValueControl = new TextEditingController();

  TextEditingController issueInfoCommitValueControl = new TextEditingController();

  _IssueDetailPageState(this.issueNum, this.userName, this.reposName, this.needHomeIcon);

  _renderEventItem(index) {
    if (index == 0) {
      return new IssueHeaderItem(issueHeaderViewModel, onPressed: () {
      });
    }
    Issue issue = pullLoadWidgetControl.dataList[index - 1];
    return new IssueItem(
      IssueItemViewModel.fromMap(issue, needTitle: false),
      hideBottom: true,
      limitComment: false,
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return new Center(
                child: new Container(
                  decoration: new BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      color: Colors.white,
                      border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)),
                  margin: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new GSYFlexButton(
                        color: Colors.white,
                        text: GSYStrings.issue_edit_issue_edit_commit,
                        onPress: () {
                          _editCommit(issue.id.toString(), issue.title);
                        },
                      ),
                      new GSYFlexButton(
                        color: Colors.white,
                        text: GSYStrings.issue_edit_issue_delete_commit,
                        onPress: () {
                          _deleteCommit(issue.id.toString());
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

  _getDataLogic() async {
    if (page <= 1) {
      _getHeaderInfo();
    }
    return await IssueDao.getIssueCommentDao(userName, reposName, issueNum, page: page);
  }

  _getHeaderInfo() async {
    var res = await IssueDao.getIssueInfoDao(userName, reposName, issueNum);
    if (res != null && res.result) {
      setState(() {
        issueHeaderViewModel = res.data;
        headerStatus = true;
      });
    }
  }

  _editCommit(id, content) {
    Navigator.pop(context);
    String contentData = content;
    issueInfoValueControl = new TextEditingController(text: contentData);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      GSYStrings.issue_edit_issue,
      null,
          (contentValue) {
        contentData = contentValue;
      },
          () {
        if (contentData == null || contentData
            .trim()
            .length == 0) {
          Fluttertoast.showToast(msg: GSYStrings.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueDao.editCommentDao(userName, reposName, issueNum, id, {"body": contentData}).then((result) {
          showRefreshLoading();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      valueController: issueInfoValueControl,
      needTitle: false,
    );
  }

  _deleteCommit(id) {
    Navigator.pop(context);
    CommonUtils.showLoadingDialog(context);
    //提交修改
    IssueDao.deleteCommentDao(userName, reposName, issueNum, id).then((result) {
      Navigator.pop(context);
      showRefreshLoading();
    });
  }

  _editIssue() {
    String title = issueHeaderViewModel.issueComment;
    String content = issueHeaderViewModel.issueDesHtml;
    issueInfoTitleControl = new TextEditingController(text: title);
    issueInfoValueControl = new TextEditingController(text: content);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      GSYStrings.issue_edit_issue,
          (titleValue) {
        title = titleValue;
      },
          (contentValue) {
        content = contentValue;
      },
          () {
        if (title == null || title
            .trim()
            .length == 0) {
          Fluttertoast.showToast(msg: GSYStrings.issue_edit_issue_title_not_be_null);
          return;
        }
        if (content == null || content
            .trim()
            .length == 0) {
          Fluttertoast.showToast(msg: GSYStrings.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueDao.editIssueDao(userName, reposName, issueNum, {"title": title, "body": content}).then((result) {
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

  _replyIssue() {
    //回复 Info
    String content = "";
    CommonUtils.showEditDialog(context, GSYStrings.issue_reply_issue, null, (replyContent) {
      content = replyContent;
    }, () {
      if (content == null || content
          .trim()
          .length == 0) {
        Fluttertoast.showToast(msg: GSYStrings.issue_edit_issue_content_not_be_null);
        return;
      }
      CommonUtils.showLoadingDialog(context);
      //提交评论
      IssueDao.addIssueCommentDao(userName, reposName, issueNum, content).then((result) {
        showRefreshLoading();
        Navigator.pop(context);
        Navigator.pop(context);
      });
    }, needTitle: false);
  }

  _getBottomWidget() {
    List<Widget> bottomWidget = (!headerStatus)
        ? []
        : <Widget>[
      new FlatButton(
        onPressed: () {
          _replyIssue();
        },
        child: new Text(GSYStrings.issue_reply, style: GSYConstant.smallText),
      ),
      new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
      new FlatButton(
        onPressed: () {
          _editIssue();
        },
        child: new Text(GSYStrings.issue_edit, style: GSYConstant.smallText),
      ),
      new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
      new FlatButton(
          onPressed: () {
            CommonUtils.showLoadingDialog(context);
            IssueDao.editIssueDao(userName, reposName, issueNum, {"state": (issueHeaderViewModel.state == "closed") ? 'open' : 'closed'}).then((
                result) {
              _getHeaderInfo();
              Navigator.pop(context);
            });
          },
          child: new Text((issueHeaderViewModel.state == 'closed') ? GSYStrings.issue_open : GSYStrings.issue_close, style: GSYConstant.smallText)),
      new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
      new FlatButton(
          onPressed: () {
            CommonUtils.showLoadingDialog(context);
            IssueDao.lockIssueDao(userName, reposName, issueNum, issueHeaderViewModel.locked).then((result) {
              _getHeaderInfo();
              Navigator.pop(context);
            });
          },
          child: new Text((issueHeaderViewModel.locked) ? GSYStrings.issue_unlock : GSYStrings.issue_lock, style: GSYConstant.smallText)),
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
    String url = Address.hostWeb + userName + "/" + reposName + "/issues/" + issueNum;
    Widget widget = (needHomeIcon) ? null : new GSYCommonOptionWidget(url);
    return new Scaffold(
      persistentFooterButtons: _getBottomWidget(),
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
