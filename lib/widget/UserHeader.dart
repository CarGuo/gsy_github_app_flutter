import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-17
 */
class UserHeaderItem extends StatelessWidget {
  final User userInfo;

  UserHeaderItem(this.userInfo);

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
                          image: userInfo.avatar_url,
                          width: 80.0,
                          height: 80.0,
                        ),
                      ),
                      new Padding(padding: EdgeInsets.all(10.0)),
                      new Expanded(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text(userInfo.login, style: GSYConstant.largeTextWhiteBold),
                            new Text(userInfo.name, style: GSYConstant.subLightSmallText),
                            new GSYIConText(
                              GSYICons.USER_ITEM_COMPANY,
                              userInfo.company == null ? GSYStrings.nothing_now : userInfo.company,
                              GSYConstant.subLightSmallText,
                              Color(GSYColors.subLightTextColor),
                              10.0,
                              padding: 3.0,
                            ),
                            new GSYIConText(
                              GSYICons.USER_ITEM_LOCATION,
                              userInfo.location == null ? GSYStrings.nothing_now : userInfo.location,
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
                      child: new GSYIConText(
                        GSYICons.USER_ITEM_LINK,
                        userInfo.blog == null ? GSYStrings.nothing_now : userInfo.blog,
                        GSYConstant.subLightSmallText,
                        Color(GSYColors.subLightTextColor),
                        10.0,
                        padding: 3.0,
                      ),
                      margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                      alignment: Alignment.topLeft),
                  new Container(
                      child: new Text(
                        userInfo.bio == null ? GSYStrings.nothing_now : userInfo.bio,
                        style: GSYConstant.subLightSmallText,
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
                          child: new Text("仓库\n" + userInfo.public_repos.toString(), textAlign: TextAlign.center, style: GSYConstant.subSmallText),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("粉丝\n" + userInfo.followers.toString(), textAlign: TextAlign.center, style: GSYConstant.subSmallText),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text(
                            "关注\n" + userInfo.following.toString(),
                            textAlign: TextAlign.center,
                            style: GSYConstant.subSmallText,
                          ),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("星标\n---", textAlign: TextAlign.center, style: GSYConstant.subSmallText),
                        ),
                      ),
                      new Expanded(
                        child: new Center(
                          child: new Text("荣耀\n---", textAlign: TextAlign.center, style: GSYConstant.subSmallText),
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
