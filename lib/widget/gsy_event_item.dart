import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/model/Event.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';
import 'package:gsy_github_app_flutter/model/Notification.dart' as Model;

/**
 * 事件Item
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class GSYEventItem extends StatelessWidget {
  final EventViewModel eventViewModel;

  final VoidCallback? onPressed;

  final bool needImage;

  GSYEventItem(this.eventViewModel, {this.onPressed, this.needImage = true})
      : super();

  @override
  Widget build(BuildContext context) {
    Widget des = (eventViewModel.actionDes == null ||
            eventViewModel.actionDes!.length == 0)
        ? new Container()
        : new Container(
            child: new Text(
              eventViewModel.actionDes!,
              style: GSYConstant.smallSubText,
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
          child: new TextButton(
              onPressed: onPressed,
              child: new Padding(
                padding: new EdgeInsets.only(
                    left: 0.0, top: 10.0, right: 0.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        userImage,
                        new Expanded(
                            child: new Text(eventViewModel.actionUser!,
                                style: GSYConstant.smallTextBold)),
                        new Text(eventViewModel.actionTime,
                            style: GSYConstant.smallSubText),
                      ],
                    ),
                    new Container(
                        child: new Text(eventViewModel.actionTarget!,
                            style: GSYConstant.smallTextBold),
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
  String? actionUser;
  String? actionUserPic;
  String? actionDes;
  late String actionTime;
  String? actionTarget;

  EventViewModel.fromEventMap(Event event) {
    actionTime = CommonUtils.getNewsTimeStr(event.createdAt!);
    actionUser = event.actor!.login;
    actionUserPic = event.actor!.avatar_url;
    var as = EventUtils.getActionAndDes(event);
    actionDes = as.des;
    actionTarget = as.actionStr;
  }

  EventViewModel.fromCommitMap(RepoCommit eventMap) {
    actionTime = CommonUtils.getNewsTimeStr(eventMap.commit!.committer!.date!);
    actionUser = eventMap.commit!.committer!.name;
    actionDes = "sha:" + eventMap.sha!;
    actionTarget = eventMap.commit!.message;
  }

  EventViewModel.fromNotify(BuildContext context, Model.Notification eventMap) {
    actionTime = CommonUtils.getNewsTimeStr(eventMap.updateAt!);
    actionUser = eventMap.repository!.fullName;
    String? type = eventMap.subject!.type;
    String status = eventMap.unread!
        ? GSYLocalizations.i18n(context)!.notify_unread
        : GSYLocalizations.i18n(context)!.notify_readed;
    actionDes = eventMap.reason! +
        "${GSYLocalizations.i18n(context)!.notify_type}：$type，${GSYLocalizations.i18n(context)!.notify_status}：$status";
    actionTarget = eventMap.subject!.title;
  }
}
