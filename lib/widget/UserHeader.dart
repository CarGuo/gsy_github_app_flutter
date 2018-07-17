import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-17
 */
class UserHeaderItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new GSYCardItem(
            color: Color(GSYColors.primaryValue),
            margin: EdgeInsets.all(0.0),
            shape: new RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4.0), bottomRight: Radius.circular(4.0))),
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
                          image: "fffffff",
                          width: 80.0,
                          height: 80.0,
                        ),
                      ),
                      new Padding(padding: EdgeInsets.all(10.0)),
                      new Expanded(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text("Login", style: GSYConstant.normalTextBold),
                            new GSYIConText(
                              GSYICons.REPOS_ITEM_USER,
                              "Name ",
                              GSYConstant.subLightSmallText,
                              Color(GSYColors.subLightTextColor),
                              10.0,
                              padding: 3.0,
                            ),
                            new GSYIConText(
                              GSYICons.REPOS_ITEM_USER,
                              "company ",
                              GSYConstant.subLightSmallText,
                              Color(GSYColors.subLightTextColor),
                              10.0,
                              padding: 3.0,
                            ),
                            new GSYIConText(
                              GSYICons.REPOS_ITEM_USER,
                              "location ",
                              GSYConstant.subLightSmallText,
                              Color(GSYColors.subLightTextColor),
                              10.0,
                              padding: 3.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  new Container(
                      child: new Text(
                        "link",
                        style: GSYConstant.subSmallText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                      alignment: Alignment.topLeft),
                  new Container(
                      child: new Text(
                        "desssssssssssss",
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
                      new Expanded(
                        child: new Center(
                          child: new Text("fff\nff"),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("fff\nff"),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("fff\nff"),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("fff\nff"),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("fff\nff"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
