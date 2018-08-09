import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:redux/redux.dart';

/**
 * 用户信息中心
 * Created by guoshuyu
 * Date: 2018-08-08
 */

class UserProfileInfo extends StatefulWidget {
  UserProfileInfo();

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfileInfo> {
  _renderItem(IconData leftIcon, String title, String value, VoidCallback onPressed) {
    return new GSYCardItem(
      child: new RawMaterialButton(
        onPressed: onPressed,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(15.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        child: new Row(
          children: <Widget>[
            new Icon(leftIcon),
            new Container(
              width: 10.0,
            ),
            new Text(title, style: GSYConstant.subNormalText),
            new Container(
              width: 10.0,
            ),
            new Expanded(child: new Text(value, style: GSYConstant.normalText)),
            new Container(
              width: 10.0,
            ),
            new Icon(GSYICons.REPOS_ITEM_NEXT, size: 12.0),
          ],
        ),
      ),
    );
  }

  static const String user_profile_name = "名字";
  static const String user_profile_email = "邮箱";
  static const String user_profile_link = "链接";
  static const String user_profile_org = "公司";
  static const String user_profile_location = "位置";
  static const String user_profile_info = "简介";

  _showEditDialog(String title, String value, String key, Store store) {
    String content = value ?? "";
    CommonUtils.showEditDialog(context, title, (title) {}, (res) {
      content = res;
    }, () {
      if (content == null || content.length == 0) {
        return;
      }
      CommonUtils.showLoadingDialog(context);

      UserDao.updateUserDao({key: content}, store).then((res) {
        Navigator.of(context).pop();
        if(res != null && res.result) {
          Navigator.of(context).pop();
        }
      });
    }, titleController: new TextEditingController(), valueController: new TextEditingController(text: value), needTitle: false);
  }

  List<Widget> _renderList(User userInfo, Store store) {
    return [
      _renderItem(Icons.info, GSYStrings.user_profile_name, userInfo.name ?? "---", () {
        _showEditDialog(GSYStrings.user_profile_name, userInfo.name, "name", store);
      }),
      _renderItem(Icons.email, GSYStrings.user_profile_email, userInfo.email ?? "---", () {
        _showEditDialog(GSYStrings.user_profile_email, userInfo.email, "email", store);
      }),
      _renderItem(Icons.link, GSYStrings.user_profile_link, userInfo.blog ?? "---", () {
        _showEditDialog(GSYStrings.user_profile_link, userInfo.blog, "blog", store);
      }),
      _renderItem(Icons.group, GSYStrings.user_profile_org, userInfo.company ?? "---", () {
        _showEditDialog(GSYStrings.user_profile_org, userInfo.company, "company", store);
      }),
      _renderItem(Icons.location_on, GSYStrings.user_profile_location, userInfo.location ?? "---", () {
        _showEditDialog(GSYStrings.user_profile_location, userInfo.location, "location", store);
      }),
      _renderItem(Icons.message, GSYStrings.user_profile_info, userInfo.bio ?? "---", () {
        _showEditDialog(GSYStrings.user_profile_info, userInfo.bio, "bio", store);
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(builder: (context, store) {
      return Scaffold(
        appBar: new AppBar(title: new Text(GSYStrings.home_user_info)),
        body: new Container(
          color: Colors.white,
          child: new SingleChildScrollView(
            child: new Column(
              children: _renderList(store.state.userInfo, store),
            ),
          ),
        ),
      );
    });
  }
}
