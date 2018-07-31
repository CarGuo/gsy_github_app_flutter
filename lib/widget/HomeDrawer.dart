import 'dart:io';

import 'package:get_version/get_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/dao/IssueDao.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYFlexButton.dart';

/**
 * 主页drawer
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class HomeDrawer extends StatelessWidget {
  showAboutDialog(BuildContext context, String versionName) {
    versionName ??= "Null";
    showDialog(
        context: context,
        builder: (BuildContext context) => AboutDialog(
              applicationName: GSYStrings.app_name,
              applicationVersion: GSYStrings.app_version + ": " + versionName,
              applicationIcon: new Image(image: new AssetImage(GSYICons.DEFAULT_USER_ICON), width: 50.0, height: 50.0),
              applicationLegalese: "http://github.com/CarGuo",
            ));
  }

  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        User user = store.state.userInfo;
        return new Drawer(
          //侧边栏按钮Drawer
          child: new ListView(
            children: <Widget>[
              new UserAccountsDrawerHeader(
                //Material内置控件
                accountName: new Text(
                  user.login != null ? user.login : "---",
                  style: GSYConstant.largeTextWhite,
                ),
                accountEmail: new Text(
                  user.email != null ? user.email : user.name != null ? user.name : "---",
                  style: GSYConstant.subNormalText,
                ),
                //用户名
                //用户邮箱
                currentAccountPicture: new GestureDetector(
                  //用户头像
                  onTap: () {},
                  child: new CircleAvatar(
                    //圆形图标控件
                    backgroundImage: new NetworkImage(user.avatar_url != null ? user.avatar_url : "---"),
                  ),
                ),
                decoration: new BoxDecoration(
                  //用一个BoxDecoration装饰器提供背景图片
                  color: Color(GSYColors.primaryValue),
                ),
              ),
              new ListTile(
                  title: new Text(
                    GSYStrings.home_reply,
                    style: GSYConstant.normalText,
                  ),
                  onTap: () {
                    String content = "";
                    CommonUtils.showEditDialog(context, GSYStrings.home_reply, (title) {}, (res) {
                      content = res;
                    }, () {
                      if (content == null || content.length == 0) {
                        return;
                      }
                      CommonUtils.showLoadingDialog(context);
                      IssueDao.createIssueDao("CarGuo", "GSYGithubAppFlutter", {"title": GSYStrings.home_reply, "body": content}).then((result) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      });
                    }, needTitle: false);
                  }),
              new ListTile(
                  title: new Text(
                    GSYStrings.home_check_update,
                    style: GSYConstant.normalText,
                  ),
                  onTap: () {
                    ReposDao.getNewsVersion(context, true);
                  }),
              new ListTile(
                  title: new Text(
                    GSYStrings.home_about,
                    style: GSYConstant.normalText,
                  ),
                  onTap: () {
                    GetVersion.projectVersion.then((value) {
                      showAboutDialog(context, value);
                    });
                  }),
              new ListTile(
                  title: new GSYFlexButton(
                    text: GSYStrings.Login_out,
                    color: Colors.redAccent,
                    textColor: Color(GSYColors.textWhite),
                    onPress: () {
                      UserDao.clearAll(store);
                      EventDao.clearEvent(store);
                      NavigatorUtils.goLogin(context);
                    },
                  ),
                  onTap: () {}),
            ],
          ),
        );
      },
    );
  }
}
