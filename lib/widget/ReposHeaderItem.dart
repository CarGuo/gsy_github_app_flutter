import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';

/**
 * 仓库详情信息头控件
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class ReposHeaderItem extends StatelessWidget {
  ReposHeaderItem() : super();

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new GSYCardItem(
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
                      child: new Text("carguo", style: GSYConstant.normalTextMitWhite),
                    ),
                    new Text(" /  ", style: GSYConstant.normalTextMitWhite),
                    new Text("22222", style: GSYConstant.normalTextMitWhite),
                  ],
                ),
                new Padding(padding: new EdgeInsets.all(5.0)),
                new Row(
                  children: <Widget>[
                    new Text("JAVA ", style: GSYConstant.smallTextWhite),
                    new Text(" 1112M  ", style: GSYConstant.smallTextWhite),
                    new Text(" MIT ", style: GSYConstant.smallTextWhite),
                  ],
                ),
                new Padding(padding: new EdgeInsets.all(5.0)),
                new Container(
                    child: new Text("ffffffffffffffffffffffffffffffffff", style: GSYConstant.middleTextWhite),
                    margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                    alignment: Alignment.topLeft),
                new Container(
                    child: new Text("fffffff", style: GSYConstant.smallTextWhite),
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
                        new Expanded(
                          child: new Center(
                            child: new GSYIConText(
                              GSYICons.REPOS_ITEM_STAR,
                              "666",
                              GSYConstant.middleSubText,
                              Color(GSYColors.subTextColor),
                              15.0,
                              padding: 3.0,
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                          ),
                        ),
                        new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                        new Expanded(
                          child: new Center(
                            child: new GSYIConText(
                              GSYICons.REPOS_ITEM_FORK,
                              "666",
                              GSYConstant.middleSubText,
                              Color(GSYColors.subTextColor),
                              15.0,
                              padding: 3.0,
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                          ),
                        ),
                        new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                        new Expanded(
                          child: new Center(
                            child: new GSYIConText(
                              GSYICons.REPOS_ITEM_ISSUE,
                              "666",
                              GSYConstant.middleSubText,
                              Color(GSYColors.subTextColor),
                              15.0,
                              padding: 3.0,
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                          ),
                        ),
                        new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                        new Expanded(
                          child: new Center(
                            child: new GSYIConText(
                              GSYICons.REPOS_ITEM_ISSUE,
                              "666",
                              GSYConstant.middleSubText,
                              Color(GSYColors.subTextColor),
                              15.0,
                              padding: 3.0,
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          )),
    );
  }
}
