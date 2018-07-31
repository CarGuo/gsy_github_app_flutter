import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/EventUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYUserIconWidget.dart';

/**
 * 事件Item
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class EventItem extends StatelessWidget {
  final EventViewModel eventViewModel;

  final VoidCallback onPressed;

  final bool needImage;

  EventItem(this.eventViewModel, {this.onPressed, this.needImage = true}) : super();

  @override
  Widget build(BuildContext context) {
    Widget des = (eventViewModel.actionDes == null || eventViewModel.actionDes.length == 0)
        ? new Container()
        : new Container(
        child: new Text(
          eventViewModel.actionDes,
          style: GSYConstant.subSmallText,
          maxLines: 3,
        ),
        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
        alignment: Alignment.topLeft);

    Widget userImage = (needImage)
        ? new GSYUserIconWidget(
        padding: const EdgeInsets.only(top: 0.0, right: 5.0, left: 0.0),
        width: 30.0,
        height: 30.0,
        image: eventViewModel.actionUserPic,
        onPressed: () {
          NavigatorUtils.goPerson(context, eventViewModel.actionUser);
        })
        : Container();
    return new Container(
      child: new GSYCardItem(
          child: new FlatButton(
              onPressed: onPressed,
              child: new Padding(
                padding: new EdgeInsets.only(left: 0.0, top: 10.0, right: 0.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        userImage,
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
  var eventMap;

  EventViewModel.fromEventMap(Event event) {
    actionTime = CommonUtils.getNewsTimeStr(event.createdAt);
    actionUser = event.actor.login;
    actionUserPic = event.actor.avatar_url;
    var other = EventUtils.getActionAndDes(event);
    actionDes = other["des"];
    actionTarget = other["actionStr"];
  }

  EventViewModel.fromCommitMap(RepoCommit eventMap) {
    actionTime = CommonUtils.getNewsTimeStr(eventMap.commit.committer.date);
    actionUser = eventMap.commit.committer.name;
    actionDes = "sha:" + eventMap.sha;
    actionTarget = eventMap.commit.message;
  }

  EventViewModel.fromNotify(eventMap) {
    actionTime = CommonUtils.getNewsTimeStr(DateTime.parse(eventMap["updated_at"]));
    actionUser = eventMap["repository"]["full_name"];
    String type = eventMap["subject"]["type"];
    String status = eventMap["unread"] ? GSYStrings.notify_unread : GSYStrings.notify_readed;
    actionDes = eventMap["reason"] + "${GSYStrings.notify_type}：$type，${GSYStrings.notify_status}：$status";
    actionTarget = eventMap["subject"]["title"];
    this.eventMap = eventMap;
  }
}
