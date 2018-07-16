import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-16
 */

class ReposItem extends StatelessWidget {
  final ReposViewModel reposViewModel;

  ReposItem(this.reposViewModel) : super();

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new GSYCardItem(
          child: new FlatButton(
              onPressed: () => {},
              child: new Padding(
                padding: new EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new ClipOval(
                          child: new FadeInImage.assetNetwork(
                            placeholder: "static/images/logo.png",
                            //预览图
                            fit: BoxFit.fitWidth,
                            image: "FFFF",
                            width: 40.0,
                            height: 40.0,
                          ),
                        ),
                        new Padding(padding: EdgeInsets.all(10.0)),
                        new Expanded(
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new Text("FFFF", style: GSYConstant.normalTextBold),
                              new GSYIConText(
                                GSYICons.REPOS_ITEM_USER,
                                "FFF",
                                GSYConstant.subLightSmallText,
                                Color(GSYColors.subLightTextColor),
                                10.0,
                                padding: 3.0,
                              ),
                            ],
                          ),
                        ),
                        new Text("FFFF", style: GSYConstant.subSmallText),
                      ],
                    ),
                    new Container(
                        child: new Text("ggggggggggggggggggggggggggggggg", style: GSYConstant.subSmallText),
                        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                        alignment: Alignment.topLeft),
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
  String repositoryTyp;
  String repositoryDes;
}
