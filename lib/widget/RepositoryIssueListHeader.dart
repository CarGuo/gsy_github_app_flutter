import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-19
 */

class RepositoryIssueListHeader extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
        color: Color(GSYColors.primaryValue),
        margin: EdgeInsets.all(10.0),
        shape: new RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: new Padding(
            padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 5.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                    child: new Text(
                  "All",
                  style: GSYConstant.middleTextWhite,
                  textAlign: TextAlign.center,
                )),
                new Container(width: 1.0, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                new Expanded(
                    child: new Text(
                  "Open",
                  style: GSYConstant.middleTextWhite,
                  textAlign: TextAlign.center,
                )),
                new Container(width: 1.0, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                new Expanded(
                    child: new Text(
                  "Closed",
                  style: GSYConstant.middleTextWhite,
                  textAlign: TextAlign.center,
                )),
              ],
            )));
  }

  @override
  Size get preferredSize {
    return new Size.fromHeight(50.0);
  }
}
