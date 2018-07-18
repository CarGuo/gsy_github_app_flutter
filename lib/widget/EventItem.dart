import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/page/PersonPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * 事件Item
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class EventItem extends StatelessWidget {

  final EventViewModel eventViewModel;

  final VoidCallback onPressed;

  EventItem(this.eventViewModel, {this.onPressed}) : super();

  @override
  Widget build(BuildContext context) {
    Widget des = (eventViewModel.actionDes == null || eventViewModel.actionDes.length == 0)
        ? new Container()
        : new Container(
            child: new Text(eventViewModel.actionDes, style: GSYConstant.subSmallText),
            margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
            alignment: Alignment.topLeft);
    return new Container(
      child: new GSYCardItem(
          child: new FlatButton(
              onPressed: onPressed,
              child: new Padding(
                padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        new IconButton(
                            icon: new ClipOval(
                              child: new FadeInImage.assetNetwork(
                                placeholder: "static/images/logo.png",
                                //预览图
                                fit: BoxFit.fitWidth,
                                image: eventViewModel.actionUserPic,
                                width: 30.0,
                                height: 30.0,
                              ),
                            ),
                            onPressed: () {
                              NavigatorUtils.goPerson(context, eventViewModel.actionUser);
                            }),
                        new Padding(padding: EdgeInsets.all(5.0)),
                        new Expanded(child: new Text(eventViewModel.actionUser, style: GSYConstant.smallTextBold)),
                        new Text(eventViewModel.actionTime, style: GSYConstant.subSmallText),
                      ],
                    ),
                    new Container(
                        child: new Text(eventViewModel.actionTarget, style: GSYConstant.smallTextBold),
                        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                        alignment: Alignment.topLeft),
                    des,
                  ],
                ),
              ))),
    );
  }
}

class EventViewModel {
  String actionUser;
  String actionUserPic;
  String actionDes;
  String actionTime;
  String actionTarget;

  EventViewModel.fromEventMap(eventMap) {
    actionTime = CommonUtils.getNewsTimeStr(DateTime.parse(eventMap["created_at"]));
    actionUser = eventMap["actor"]["display_login"];
    actionUserPic = eventMap["actor"]["avatar_url"];
    var other = EventUtils.getActionAndDes(eventMap);
    actionDes = other["des"];
    actionTarget = other["actionStr"];
  }
}
