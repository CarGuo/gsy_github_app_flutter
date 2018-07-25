import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';

/**
 * 仓库Item
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class ReposItem extends StatelessWidget {
  final ReposViewModel reposViewModel;

  final VoidCallback onPressed;

  ReposItem(this.reposViewModel, {this.onPressed}) : super();

  _getBottomItem(IconData icon, String text, {int flex = 2}) {
    return new Expanded(
      flex: flex,
      child: new Center(
        child: new GSYIConText(
          icon,
          text,
          GSYConstant.subSmallText,
          Color(GSYColors.subTextColor),
          15.0,
          padding: 5.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new GSYCardItem(
          child: new FlatButton(
              onPressed: onPressed,
              child: new Padding(
                padding: new EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new RawMaterialButton(
                            constraints: new BoxConstraints(minWidth: 0.0, minHeight: 0.0),
                            padding: new EdgeInsets.all(0.0),
                            onPressed: () {
                              NavigatorUtils.goPerson(context, reposViewModel.ownerName);
                            },
                            child: new ClipOval(
                              child: new FadeInImage.assetNetwork(
                                placeholder: "static/images/logo.png",
                                //预览图
                                fit: BoxFit.fitWidth,
                                image: reposViewModel.ownerPic,
                                width: 40.0,
                                height: 40.0,
                              ),
                            )),
                        new Padding(padding: EdgeInsets.all(10.0)),
                        new Expanded(
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new Text(reposViewModel.repositoryName, style: GSYConstant.normalTextBold),
                              new GSYIConText(
                                GSYICons.REPOS_ITEM_USER,
                                reposViewModel.ownerName,
                                GSYConstant.subLightSmallText,
                                Color(GSYColors.subLightTextColor),
                                10.0,
                                padding: 3.0,
                              ),
                            ],
                          ),
                        ),
                        new Text(reposViewModel.repositoryType, style: GSYConstant.subSmallText),
                      ],
                    ),
                    new Container(
                        child: new Text(
                          reposViewModel.repositoryDes,
                          style: GSYConstant.subSmallText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                        alignment: Alignment.topLeft),
                    new Padding(padding: EdgeInsets.all(10.0)),
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _getBottomItem(GSYICons.REPOS_ITEM_STAR, reposViewModel.repositoryStar),
                        _getBottomItem(GSYICons.REPOS_ITEM_FORK, reposViewModel.repositoryFork),
                        _getBottomItem(GSYICons.REPOS_ITEM_ISSUE, reposViewModel.repositoryWatch, flex: 4),
                      ],
                    ),
                  ],
                ),
              ))),
    );
  }
}

class ReposViewModel {
  String ownerName;
  String ownerPic;
  String repositoryName;
  String repositoryStar;
  String repositoryFork;
  String repositoryWatch;
  String hideWatchIcon;
  String repositoryType = "";
  String repositoryDes;

  ReposViewModel();

  ReposViewModel.fromMap(data) {
    ownerName = data["owner"]["login"];
    ownerPic = data["owner"]["avatar_url"];
    repositoryName = data["name"];
    repositoryStar = data["watchers_count"].toString();
    repositoryFork = data["forks_count"].toString();
    repositoryWatch = data["open_issues"].toString();
    repositoryType = data["language"] != null ? data["language"] : '---';
    repositoryDes = data["description"] != null ? data["description"] : '---';
  }
}
