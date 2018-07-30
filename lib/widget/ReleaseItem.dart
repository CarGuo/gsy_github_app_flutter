import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * 版本TagItem
 * Created by guoshuyu
 * Date: 2018-07-30
 */

class ReleaseItem extends StatelessWidget {
  final ReleaseItemViewModel releaseItemViewModel;

  final GestureTapCallback onPressed;
  final GestureLongPressCallback onLongPress;

  ReleaseItem(this.releaseItemViewModel, {this.onPressed, this.onLongPress}) : super();

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new GSYCardItem(
        child: new InkWell(
          onTap: onPressed,
          onLongPress: () {},
          child: new Padding(
            padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 10.0),
            child: new Row(
              children: <Widget>[
                new Expanded(child: new Text(releaseItemViewModel.actionTitle, style: GSYConstant.smallTextBold)),
                new Container(child: new Text(releaseItemViewModel.actionTime ?? "", style: GSYConstant.subSmallText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReleaseItemViewModel {
  String actionTime;
  String actionTitle;
  String actionMode;
  String actionTarget;
  String actionTargetHtml;

  ReleaseItemViewModel();

  ReleaseItemViewModel.fromMap(map) {
    actionTime = CommonUtils.getNewsTimeStr(DateTime.parse(map["published_at"]));
    actionTitle = map["name"] ?? map["tag_name"];
    actionTarget = map["target_commitish"];
    actionTargetHtml = map["body_html"];
  }
}
