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
 * Issue 详情头
 * Created by guoshuyu
 * on 2018/7/21.
 */

class IssueHeaderItem extends StatelessWidget {
  final IssueHeaderViewModel issueHeaderViewModel;

  final VoidCallback? onPressed;

  IssueHeaderItem(this.issueHeaderViewModel, {this.onPressed});

  _renderBottomContainer() {
    Color issueStateColor =
        issueHeaderViewModel.state == "open" ? Colors.green : Colors.red;

    ///底部Issue状态
    Widget bottomContainer = new Row(
      children: <Widget>[
        ///issue 关闭打开状态
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

        ///issue issue编码
        new Text(issueHeaderViewModel.issueTag,
            style: GSYConstant.smallTextWhite),
        new Padding(padding: new EdgeInsets.all(2.0)),

        ///issue 评论数
        new GSYIConText(
          GSYICons.ISSUE_ITEM_COMMENT,
          issueHeaderViewModel.commentCount,
          GSYConstant.smallTextWhite,
          GSYColors.white,
          15.0,
          padding: 2.0,
        ),
      ],
    );
    return bottomContainer;
  }

  ///关闭操作人
  _renderCloseByText() {
    return (issueHeaderViewModel.closedBy == null ||
            issueHeaderViewModel.closedBy!.trim().length == 0)
        ? new Container()
        : new Container(
            child: new Text(
              "Close By " + issueHeaderViewModel.closedBy!,
              style: GSYConstant.smallSubLightText,
            ),
            margin: new EdgeInsets.only(right: 5.0, top: 10.0, bottom: 10.0),
            alignment: Alignment.topRight);
  }

  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
      color: Theme.of(context).primaryColor,
      child: new TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.all(0.0)),
        onPressed: onPressed,
        child: new Padding(
          padding: new EdgeInsets.all(10.0),
          child: new Column(
            children: <Widget>[
              new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ///头像
                  new GSYUserIconWidget(
                      padding: const EdgeInsets.only(
                          top: 0.0, right: 10.0, left: 0.0),
                      width: 50.0,
                      height: 50.0,
                      image: issueHeaderViewModel.actionUserPic ??
                          GSYICons.DEFAULT_REMOTE_PIC,
                      onPressed: () {
                        NavigatorUtils.goPerson(
                            context, issueHeaderViewModel.actionUser);
                      }),
                  new Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new Row(
                          children: <Widget>[
                            ///名称
                            new Expanded(
                                child: new Text(
                                    issueHeaderViewModel.actionUser!,
                                    style: GSYConstant.normalTextWhite)),

                            ///时间
                            new Text(
                              issueHeaderViewModel.actionTime,
                              style: GSYConstant.smallSubLightText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        new Padding(padding: new EdgeInsets.all(2.0)),

                        ///底部Item
                        _renderBottomContainer(),
                        new Container(

                            ///评论标题
                            child: new Text(
                              issueHeaderViewModel.issueComment!,
                              style: GSYConstant.smallTextWhite,
                            ),
                            margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft),
                        new Padding(
                          padding: new EdgeInsets.only(
                              left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              ///评论内容
              GSYMarkdownWidget(
                  markdownData: issueHeaderViewModel.issueDesHtml,
                  style: GSYMarkdownWidget.DARK_THEME),

              ///close 用户
              _renderCloseByText()
            ],
          ),
        ),
      ),
    );
  }
}

class IssueHeaderViewModel {
  String actionTime = "---";
  String? actionUser = "---";
  String? actionUserPic;

  String? closedBy = "";
  bool? locked = false;
  String? issueComment = "---";
  String? issueDesHtml = "---";
  String commentCount = "---";
  String? state = "---";
  String issueDes = "---";
  String issueTag = "---";

  IssueHeaderViewModel();

  IssueHeaderViewModel.fromMap(Issue issueMap) {
    actionTime = CommonUtils.getNewsTimeStr(issueMap.createdAt!);
    actionUser = issueMap.user!.login;
    actionUserPic = issueMap.user!.avatar_url;
    closedBy = issueMap.closeBy != null ? issueMap.closeBy!.login : "";
    locked = issueMap.locked;
    issueComment = issueMap.title;
    issueDesHtml = issueMap.bodyHtml != null
        ? issueMap.bodyHtml
        : (issueMap.body != null)
            ? issueMap.body
            : "";
    commentCount = issueMap.commentNum.toString() + "";
    state = issueMap.state;
    issueDes = issueMap.body != null ? ": \n" + issueMap.body! : '';
    issueTag = "#" + issueMap.number.toString();
  }
}
