import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';
import 'package:gsy_github_app_flutter/widget/GSYUserIconWidget.dart';

/**
 * Issue 详情头
 * Created by guoshuyu
 * on 2018/7/21.
 */

class IssueHeaderItem extends StatelessWidget {
  final IssueHeaderViewModel issueHeaderViewModel;

  final VoidCallback onPressed;

  IssueHeaderItem(this.issueHeaderViewModel, {this.onPressed});

  @override
  Widget build(BuildContext context) {
    Color issueStateColor = issueHeaderViewModel.state == "open" ? Colors.green : Colors.red;
    Widget bottomContainer = new Row(
      children: <Widget>[
        new GSYIConText(
          GSYICons.ISSUE_ITEM_ISSUE,
          issueHeaderViewModel.state,
          TextStyle(
            color: issueStateColor,
            fontSize: GSYConstant.smallTextSize,
          ),
          issueStateColor,
          15.0,
          padding: 2.0,
        ),
        new Padding(padding: new EdgeInsets.all(2.0)),
        new Text(issueHeaderViewModel.issueTag, style: GSYConstant.smallTextWhite),
        new Padding(padding: new EdgeInsets.all(2.0)),
        new GSYIConText(
          GSYICons.ISSUE_ITEM_COMMENT,
          issueHeaderViewModel.commentCount,
          GSYConstant.smallTextWhite,
          Color(GSYColors.white),
          15.0,
          padding: 2.0,
        ),
      ],
    );
    return new GSYCardItem(
      color: Color(GSYColors.primaryValue),
      child: new FlatButton(
        padding: new EdgeInsets.all(0.0),
        onPressed: onPressed,
        child: new Padding(
          padding: new EdgeInsets.all(10.0),
          child: new Column(
            children: <Widget>[
              new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new GSYUserIconWidget(
                      padding: const EdgeInsets.only(top: 0.0, right: 10.0, left: 0.0),
                      width: 50.0,
                      height: 50.0,
                      image: issueHeaderViewModel.actionUserPic,
                      onPressed: () {
                        NavigatorUtils.goPerson(context, issueHeaderViewModel.actionUser);
                      }),
                  new Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new Row(
                          children: <Widget>[
                            new Expanded(child: new Text(issueHeaderViewModel.actionUser, style: GSYConstant.normalTextWhite)),
                            new Text(
                              issueHeaderViewModel.actionTime,
                              style: GSYConstant.subSmallText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        new Padding(padding: new EdgeInsets.all(2.0)),
                        bottomContainer,
                        new Container(
                            child: new Text(
                              issueHeaderViewModel.issueComment,
                              style: GSYConstant.smallTextWhite,
                            ),
                            margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft),
                        new Padding(
                          padding: new EdgeInsets.only(left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              new Container(
                  child: new Text(
                    issueHeaderViewModel.issueDesHtml,
                    style: GSYConstant.smallTextWhite,
                  ),
                  margin: new EdgeInsets.all(10.0),
                  alignment: Alignment.topLeft)
            ],
          ),
        ),
      ),
    );
  }
}

class IssueHeaderViewModel {
  String actionTime = "---";
  String actionUser = "---";
  String actionUserPic = "---";
  String closed_by = "---";
  bool locked = false;
  String issueComment = "---";
  String issueDesHtml = "---";
  String commentCount = "---";
  String state = "---";
  String issueDes = "---";
  String issueTag = "---";

  IssueHeaderViewModel();

  IssueHeaderViewModel.fromMap(issueMap) {
    actionTime = CommonUtils.getNewsTimeStr(DateTime.parse(issueMap["created_at"]));
    actionUser = issueMap["user"]["login"];
    actionUserPic = issueMap["user"]["avatar_url"];
    closed_by = issueMap["closed_by"] != null ? issueMap["closed_by"]["login"] : "";
    locked = issueMap["locked"];
    issueComment = issueMap["title"];
    issueDesHtml = issueMap["body_html"] != null ? issueMap["body_html"] : (issueMap["body"] != null) ? issueMap["body"] : "";
    commentCount = issueMap["comments"].toString() + "";
    state = issueMap["state"];
    issueDes = issueMap["body"] != null ? ": \n" + issueMap["body"] : '';
    issueTag = "#" + issueMap["number"].toString();
  }
}
