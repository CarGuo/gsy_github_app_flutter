import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/IssueDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
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

  IssueDetailPage(this.userName, this.reposName, this.issueNum);

  @override
  _IssueDetailPageState createState() => _IssueDetailPageState(issueNum, userName, reposName);
}

// ignore: mixin_inherits_from_not_object
class _IssueDetailPageState extends GSYListState<IssueDetailPage> {
  final String userName;

  final String reposName;

  final String issueNum;

  int selectIndex = 0;

  bool headerStatus = false;

  IssueHeaderViewModel issueHeaderViewModel = new IssueHeaderViewModel();

  _IssueDetailPageState(this.issueNum, this.userName, this.reposName);

  _renderEventItem(index) {
    if (index == 0) {
      return new IssueHeaderItem(issueHeaderViewModel, onPressed: () {});
    }
    IssueItemViewModel issueItemViewModel = pullLoadWidgetControl.dataList[index - 1];
    return new IssueItem(
      issueItemViewModel,
      hideBottom: true,
      limitComment: false,
      onPressed: () {},
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

  _getBottomWidget() {
    List<Widget> bottomWidget = (!headerStatus)
        ? []
        : <Widget>[
            new FlatButton(
                onPressed: () {
                  CommonUtils.showLoadingDialog(context);
                  /*return ReposDao.doRepositoryStarDao(userName, reposName, bottomStatusModel.star).then((result) {
                  _getHeaderInfo();
                  Navigator.pop(context);
                });*/
                },
                child: new Text(GSYStrings.issue_reply, style: GSYConstant.smallText)),
            new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
            new FlatButton(onPressed: () {}, child: new Text(GSYStrings.issue_edit, style: GSYConstant.smallText)),
            new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
            new FlatButton(
                onPressed: () {
                  CommonUtils.showLoadingDialog(context);
                  IssueDao.editIssueDao(userName, reposName, issueNum, {"state": (issueHeaderViewModel.state == "closed") ? 'open' : 'closed'}).then((result) {
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
    return new Scaffold(
      persistentFooterButtons: _getBottomWidget(),
      appBar: new AppBar(
          title: new Text(
        reposName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )),
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
