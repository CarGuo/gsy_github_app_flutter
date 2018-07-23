import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * 用户item
 * Created by guoshuyu
 * Date: 2018-07-23
 */
class UserItem extends StatelessWidget {
  final UserItemViewModel userItemViewModel;

  final VoidCallback onPressed;

  final bool needImage;

  UserItem(this.userItemViewModel, {this.onPressed, this.needImage = true}) : super();

  @override
  Widget build(BuildContext context) {
    Widget userImage = new IconButton(
        padding: EdgeInsets.only(top: 0.0, left: 0.0, bottom: 0.0, right: 10.0),
        icon: new ClipOval(
          child: new FadeInImage.assetNetwork(
            placeholder: "static/images/logo.png",
            //预览图
            fit: BoxFit.fitWidth,
            image: userItemViewModel.userPic,
            width: 30.0,
            height: 30.0,
          ),
        ),
        onPressed: null);
    return new Container(
        child: new GSYCardItem(
      child: new FlatButton(
        onPressed: onPressed,
        child: new Padding(
          padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 10.0),
          child: new Row(
            children: <Widget>[
              userImage,
              new Expanded(child: new Text(userItemViewModel.userName, style: GSYConstant.smallTextBold)),
            ],
          ),
        ),
      ),
    ));
  }
}

class UserItemViewModel {
  String userPic;
  String userName;

  UserItemViewModel(this.userName, this.userPic);
}
