import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';
import 'package:gsy_github_app_flutter/widget/PushCoedItem.dart';

/**
 * 提交详情的头
 * Created by guoshuyu
 * Date: 2018-07-27
 */
class PushHeader extends StatelessWidget {
  final PushHeaderViewModel pushHeaderViewModel;

  PushHeader(this.pushHeaderViewModel);

  _getIconItem(IconData icon, String text) {
    return new GSYIConText(
      icon,
      text,
      GSYConstant.subSmallText,
      Color(GSYColors.subTextColor),
      15.0,
      padding: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
      color: Color(GSYColors.primaryValue),
      child: new FlatButton(
        padding: new EdgeInsets.all(0.0),
        onPressed: () {},
        child: new Padding(
          padding: new EdgeInsets.all(10.0),
          child: new Column(
            children: <Widget>[
              new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new IconButton(
                      icon: new ClipOval(
                        child: new FadeInImage.assetNetwork(
                          placeholder: "static/images/logo.png",
                          //预览图
                          fit: BoxFit.fitWidth,
                          image: pushHeaderViewModel.actionUserPic,
                          width: 90.0,
                          height: 90.0,
                        ),
                      ),
                      onPressed: () {
                        NavigatorUtils.goPerson(context, pushHeaderViewModel.actionUser);
                      }),
                  new Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new Row(
                          children: <Widget>[
                            _getIconItem(GSYICons.PUSH_ITEM_EDIT, pushHeaderViewModel.editCount),
                            new Container(width: 8.0),
                            _getIconItem(GSYICons.PUSH_ITEM_ADD, pushHeaderViewModel.addCount),
                            new Container(width: 8.0),
                            _getIconItem(GSYICons.PUSH_ITEM_MIN, pushHeaderViewModel.deleteCount),
                            new Container(width: 8.0),
                          ],
                        ),
                        new Padding(padding: new EdgeInsets.all(2.0)),
                        new Container(
                            child: new Text(
                              pushHeaderViewModel.pushTime,
                              style: GSYConstant.smallTextWhite,
                              maxLines: 2,
                            ),
                            margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft),
                        new Container(
                            child: new Text(
                              pushHeaderViewModel.pushDes,
                              style: GSYConstant.smallTextWhite,
                              maxLines: 2,
                            ),
                            margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft),
                        new Padding(
                          padding: new EdgeInsets.only(left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PushHeaderViewModel {
  String actionUser = "---";
  String actionUserPic = "---";
  String pushDes = "---";
  String pushTime = "---";
  String editCount = "---";
  String addCount = "---";
  String deleteCount = "---";
  List<PushCodeItemViewModel> files = new List();
  PushHeaderViewModel();

  PushHeaderViewModel.forMap(pushMap) {
    String name = "---";
    String pic = "---";
    if (pushMap["committer"] != null) {
      name = pushMap["committer"]["login"];
    } else if (pushMap["commit"] != null && pushMap["commit"]["author"] != null) {
      name = pushMap["commit"]["author"]["name"];
    }
    if (pushMap["committer"] != null && pushMap["committer"]["avatar_url"] != null) {
      pic = pushMap["committer"]["avatar_url"];
    }
    actionUser = name;
    actionUserPic = pic;
    pushDes = "Push at " + pushMap["commit"]["message"];
    pushTime = CommonUtils.getNewsTimeStr(DateTime.parse(pushMap["commit"]["committer"]["date"]));
    ;
    editCount = pushMap["files"].length.toString() + "";
    addCount = pushMap["stats"]["additions"].toString() + "";
    deleteCount = pushMap["stats"]["deletions"].toString() + "";
  }
}
