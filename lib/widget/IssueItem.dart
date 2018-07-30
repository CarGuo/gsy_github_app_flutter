import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';

/**
 * Issue相关item
 * Created by guoshuyu
 * Date: 2018-07-19
 */
class IssueItem extends StatelessWidget {
  final IssueItemViewModel issueItemViewModel;

  final GestureTapCallback onPressed;
  final GestureTapCallback onLongPress;

  final bool hideBottom;

  final bool limitComment;

  IssueItem(this.issueItemViewModel, {this.onPressed, this.onLongPress, this.hideBottom = false, this.limitComment = true});

  @override
  Widget build(BuildContext context) {
    Color issueStateColor = issueItemViewModel.state == "open" ? Colors.green : Colors.red;
    Widget bottomContainer = (hideBottom)
        ? new Container()
        : new Row(
            children: <Widget>[
              new GSYIConText(
                GSYICons.ISSUE_ITEM_ISSUE,
                issueItemViewModel.state,
                TextStyle(
                  color: issueStateColor,
                  fontSize: GSYConstant.smallTextSize,
                ),
                issueStateColor,
                15.0,
                padding: 2.0,
              ),
              new Padding(padding: new EdgeInsets.all(2.0)),
              new Expanded(
                child: new Text(issueItemViewModel.issueTag, style: GSYConstant.subSmallText),
              ),
              new GSYIConText(
                GSYICons.ISSUE_ITEM_COMMENT,
                issueItemViewModel.commentCount,
                GSYConstant.subSmallText,
                Color(GSYColors.subTextColor),
                15.0,
                padding: 2.0,
              ),
            ],
          );
    return new GSYCardItem(
      child: new InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        child: new Padding(
          padding: new EdgeInsets.only(left: 5.0, top: 5.0, right: 10.0, bottom: 8.0),
          child: new Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            new IconButton(
                icon: new ClipOval(
                  child: new FadeInImage.assetNetwork(
                    placeholder: "static/images/logo.png",
                    //预览图
                    fit: BoxFit.fitWidth,
                    image: issueItemViewModel.actionUserPic,
                    width: 30.0,
                    height: 30.0,
                  ),
                ),
                onPressed: () {
                  NavigatorUtils.goPerson(context, issueItemViewModel.actionUser);
                }),
            new Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Row(
                    children: <Widget>[
                      new Expanded(child: new Text(issueItemViewModel.actionUser, style: GSYConstant.smallTextBold)),
                      new Text(
                        issueItemViewModel.actionTime,
                        style: GSYConstant.subSmallText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  new Container(
                      child: new Text(
                        issueItemViewModel.issueComment,
                        style: GSYConstant.subSmallText,
                        maxLines: limitComment ? 2 : 1000,
                      ),
                      margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                      alignment: Alignment.topLeft),
                  new Padding(
                    padding: new EdgeInsets.only(left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                  ),
                  bottomContainer,
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class IssueItemViewModel {
  String actionTime = "---";
  String actionUser = "---";
  String actionUserPic = "---";
  String issueComment = "---";
  String commentCount = "---";
  String state = "---";
  String issueTag = "---";
  String number = "---";
  String id = "";

  IssueItemViewModel();

  IssueItemViewModel.fromMap(issueMap, {needTitle = true}) {
    String fullName = CommonUtils.getFullName(issueMap["repository_url"]);
    actionTime = CommonUtils.getNewsTimeStr(DateTime.parse(issueMap["created_at"]));
    actionUser = issueMap["user"]["login"];
    actionUserPic = issueMap["user"]["avatar_url"];
    if (needTitle) {
      issueComment = fullName + "- " + issueMap["title"];
      commentCount = issueMap["comments"].toString();
      state = issueMap["state"];
      issueTag = "#" + issueMap["number"].toString();
      number = issueMap["number"].toString();
    } else {
      issueComment = issueMap["body"] ?? "";
      id = issueMap["id"].toString();
    }
  }
}
