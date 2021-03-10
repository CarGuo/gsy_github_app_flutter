import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/model/Issue.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/**
 * Issue相关item
 * Created by guoshuyu
 * Date: 2018-07-19
 */
class IssueItem extends StatelessWidget {
  final IssueItemViewModel issueItemViewModel;

  ///点击
  final GestureTapCallback? onPressed;

  ///长按
  final GestureTapCallback? onLongPress;

  ///是否需要底部状态
  final bool hideBottom;

  ///是否需要限制内容行数
  final bool limitComment;

  IssueItem(this.issueItemViewModel,
      {this.onPressed,
      this.onLongPress,
      this.hideBottom = false,
      this.limitComment = true});

  ///issue 底部状态
  _renderBottomContainer() {
    Color issueStateColor =
        issueItemViewModel.state == "open" ? Colors.green : Colors.red;
    return (hideBottom)
        ? new Container()
        : new Row(
            children: <Widget>[
              ///issue 关闭打开状态
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

              ///issue标号
              new Expanded(
                child: new Text(issueItemViewModel.issueTag,
                    style: GSYConstant.smallSubText),
              ),

              ///评论数
              new GSYIConText(
                GSYICons.ISSUE_ITEM_COMMENT,
                issueItemViewModel.commentCount,
                GSYConstant.smallSubText,
                GSYColors.subTextColor,
                15.0,
                padding: 2.0,
              ),
            ],
          );
  }

  ///评论内容
  _renderCommentText() {
    return (limitComment)
        ? new Container(
            child: new Text(
              issueItemViewModel.issueComment,
              style: GSYConstant.smallSubText,
              maxLines: limitComment ? 2 : 1000,
            ),
            margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
            alignment: Alignment.topLeft,
          )
        : GSYMarkdownWidget(markdownData: issueItemViewModel.issueComment);
  }

  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
      child: new InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        child: new Padding(
          padding: new EdgeInsets.only(
              left: 5.0, top: 5.0, right: 10.0, bottom: 8.0),
          child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ///头像
                new GSYUserIconWidget(
                    width: 30.0,
                    height: 30.0,
                    image: issueItemViewModel.actionUserPic,
                    onPressed: () {
                      NavigatorUtils.goPerson(
                          context, issueItemViewModel.actionUser);
                    }),
                new Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          ///用户名
                          new Expanded(
                              child: new Text(issueItemViewModel.actionUser!,
                                  style: GSYConstant.smallTextBold)),
                          new Text(
                            issueItemViewModel.actionTime,
                            style: GSYConstant.smallSubText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      ///评论内容
                      _renderCommentText(),
                      new Padding(
                        padding: new EdgeInsets.only(
                            left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                      ),
                      _renderBottomContainer(),
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
  String? actionUser = "---";
  String? actionUserPic ;
  String issueComment = "---";
  String commentCount = "---";
  String? state = "---";
  String issueTag = "---";
  String number = "---";
  String id = "";

  IssueItemViewModel();

  IssueItemViewModel.fromMap(Issue issueMap, {needTitle = true}) {
    String fullName = CommonUtils.getFullName(issueMap.repoUrl);
    actionTime = CommonUtils.getNewsTimeStr(issueMap.createdAt!);
    actionUser = issueMap.user!.login;
    actionUserPic = issueMap.user!.avatar_url;
    if (needTitle) {
      issueComment = fullName + "- " + issueMap.title!;
      commentCount = issueMap.commentNum.toString();
      state = issueMap.state;
      issueTag = "#" + issueMap.number.toString();
      number = issueMap.number.toString();
    } else {
      issueComment = issueMap.body ?? "";
      id = issueMap.id.toString();
    }
  }
}
