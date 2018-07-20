import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';
import 'package:gsy_github_app_flutter/widget/GSYSelectItemWidget.dart';

/**
 * 仓库详情信息头控件
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class ReposHeaderItem extends StatelessWidget {
  final SelectItemChanged selectItemChanged;

  final ReposHeaderViewModel reposHeaderViewModel;

  ReposHeaderItem(this.reposHeaderViewModel, this.selectItemChanged) : super();

  _getBottomItem(IconData icon, String text) {
    return new Expanded(
      child: new Center(
        child: new GSYIConText(
          icon,
          text,
          GSYConstant.middleSubText,
          Color(GSYColors.subTextColor),
          15.0,
          padding: 3.0,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String createStr = reposHeaderViewModel.repositoryIsFork
        ? "Frok at " + " " + reposHeaderViewModel.repositoryParentName + '\n'
        : "Create at " + " " + reposHeaderViewModel.created_at + "\n";

    String updateStr = "Last commit at " + reposHeaderViewModel.push_at;

    String infoText = createStr + ((reposHeaderViewModel.push_at != null) ? updateStr : '');

    return new Column(
      children: <Widget>[
        new GSYCardItem(
            color: new Color(GSYColors.primaryValue),
            child: new Padding(
              padding: new EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Row(
                    children: <Widget>[
                      new RawMaterialButton(
                        constraints: new BoxConstraints(minWidth: 0.0, minHeight: 0.0),
                        padding: new EdgeInsets.all(0.0),
                        onPressed: () {},
                        child: new Text(reposHeaderViewModel.ownerName, style: GSYConstant.normalTextMitWhiteBold),
                      ),
                      new Text(" /", style: GSYConstant.normalTextMitWhiteBold),
                      new Text(" " + reposHeaderViewModel.repositoryName, style: GSYConstant.normalTextMitWhiteBold),
                    ],
                  ),
                  new Padding(padding: new EdgeInsets.all(5.0)),
                  new Row(
                    children: <Widget>[
                      new Text(reposHeaderViewModel.repositoryType != null ? reposHeaderViewModel.repositoryType : "--",
                          style: GSYConstant.subLightSmallText),
                      new Container(width: 5.3, height: 1.0),
                      new Text(reposHeaderViewModel.repositorySize != null ? reposHeaderViewModel.repositorySize : "--",
                          style: GSYConstant.subLightSmallText),
                      new Container(width: 5.3, height: 1.0),
                      new Text(reposHeaderViewModel.license != null ? reposHeaderViewModel.license : "--", style: GSYConstant.subLightSmallText),
                    ],
                  ),
                  new Padding(padding: new EdgeInsets.all(5.0)),
                  new Container(
                      child: new Text(reposHeaderViewModel.repositoryDes, style: GSYConstant.subSmallText),
                      margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                      alignment: Alignment.topLeft),
                  new Container(
                      child: new Text(infoText, style: GSYConstant.subSmallText),
                      margin: new EdgeInsets.only(top: 6.0, bottom: 2.0, right: 5.0),
                      alignment: Alignment.topRight),
                  new Divider(
                    color: Color(GSYColors.subTextColor),
                  ),
                  new Padding(
                      padding: new EdgeInsets.all(5.0),
                      child: new Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _getBottomItem(GSYICons.REPOS_ITEM_STAR, reposHeaderViewModel.repositoryStar),
                          _getBottomItem(GSYICons.REPOS_ITEM_FORK, reposHeaderViewModel.repositoryFork),
                          _getBottomItem(GSYICons.REPOS_ITEM_WATCH, reposHeaderViewModel.repositoryWatch),
                          _getBottomItem(GSYICons.REPOS_ITEM_ISSUE, reposHeaderViewModel.repositoryIssue),
                        ],
                      )),
                ],
              ),
            )),
        new GSYSelectItemWidget([
          GSYStrings.repos_tab_activity,
          GSYStrings.repos_tab_commits,
        ], selectItemChanged)
      ],
    );
  }
}

class ReposHeaderViewModel {
  String ownerName = '---';
  String ownerPic = "---";
  String repositoryName = "---";
  String repositorySize = "---";
  String repositoryStar = "---";
  String repositoryFork = "---";
  String repositoryWatch = "---";
  String repositoryIssue = "---";
  String repositoryIssueClose = "";
  String repositoryIssueAll = "";
  String repositoryType = "---";
  String repositoryDes = "---";
  String repositoryLastActivity = "";
  String repositoryParentName = "";
  String created_at = "";
  String push_at = "";
  String license = "";
  bool repositoryStared = false;
  bool repositoryForked = false;
  bool repositoryWatched = false;
  bool repositoryIsFork = false;

  ReposHeaderViewModel();

  ReposHeaderViewModel.fromHttpMap(reposName, ownerName, map) {
    this.ownerName = ownerName;
    this.ownerPic = map["owner"]["avatar_url"];
    this.repositoryName = reposName;
    this.repositoryStar = map["watchers_count"] != null ? map["watchers_count"].toString() : "";
    this.repositoryFork = map["forks_count"] != null ? map["forks_count"].toString() : "";
    this.repositoryWatch = map["subscribers_count"] != null ? map["subscribers_count"].toString() : "";
    this.repositoryIssue = map["open_issues_count"] != null ? map["open_issues_count"].toString() : "";
    this.repositoryIssueClose = map["closed_issues_count"] != null ? map["closed_issues_count"].toString() : "";
    this.repositoryIssueAll = map["all_issues_count"] != null ? map["all_issues_count"].toString() : "";
    this.repositorySize = ((map["size"] / 1024.0)).toString().substring(0, 3) + "M";
    this.repositoryType = map["language"];
    this.repositoryDes = map["description"];
    this.repositoryIsFork = map["fork"];
    this.license = map["license"] != null ? map["license"]["name"] : "";
    this.repositoryParentName = map["parent"] != null ? map["parent"]["full_name"] : null;
    this.created_at = CommonUtils.getNewsTimeStr(DateTime.parse(map["created_at"]));
    this.push_at = CommonUtils.getNewsTimeStr(DateTime.parse(map["pushed_at"]));
  }
}
