import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class HomeDrawer extends StatelessWidget {
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
                  user.login,
                  style: GSYConstant.largeTextWhite,
                ),
                accountEmail: new Text(
                  user.email != null ?  user.email: user.name,
                  style: GSYConstant.subNormalText,
                ),
                //用户名
                //用户邮箱
                currentAccountPicture: new GestureDetector(
                  //用户头像
                  onTap: () {},
                  child: new CircleAvatar(
                    //圆形图标控件
                    backgroundImage: new NetworkImage(user.avatar_url),
                  ),
                ),
                decoration: new BoxDecoration(
                  //用一个BoxDecoration装饰器提供背景图片
                  color: Color(GSYColors.primaryValue),
                ),
              ),
              new ListTile(
                  //第一个功能项
                  title: new Text(GSYStrings.Login_out, style: GSYConstant.normalText,),
                  onTap: () {}),
            ],
          ),
        );
      },
    );
  }
}
