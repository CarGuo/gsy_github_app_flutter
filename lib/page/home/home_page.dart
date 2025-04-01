import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/dynamic/dynamic_page.dart';
import 'package:gsy_github_app_flutter/page/my_page.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_page.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/page/home/widget/home_drawer.dart';
import 'package:lottie/lottie.dart';

/// 主页
/// Created by guoshuyu
/// Date: 2018-07-16
class HomePage extends StatefulWidget {
  static const String sName = "home";

  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<DynamicPageState> dynamicKey = GlobalKey();
  final GlobalKey<TrendPageState> trendKey = GlobalKey();
  final GlobalKey<MyPageState> myKey = GlobalKey();
  final GlobalKey rightKey = GlobalKey();

  /// 不退出
  _dialogExitApp(BuildContext context) async {
    ///如果是 android 回到桌面
    if (Platform.isAndroid) {
      AndroidIntent intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: "android.intent.category.HOME",
      );
      await intent.launch();
    }
  }

  _renderTab(icon, text) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[Icon(icon, size: 16.0), Text(text)],
      ),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [
      _renderTab(
          GSYICons.MAIN_DT, context.l10n.home_dynamic),
      _renderTab(GSYICons.MAIN_QS, context.l10n.home_trend),
      _renderTab(GSYICons.MAIN_MY, context.l10n.home_my),
    ];

    ///增加返回按键监听
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        _dialogExitApp(context);
      },
      child: GSYTabBarWidget(
        drawer: const HomeDrawer(),
        type: TabType.bottom,
        tabItems: tabs,
        tabViews: [
          DynamicPage(key: dynamicKey),
          TrendPage(key: trendKey),
          MyPage(key: myKey),
        ],
        onDoublePress: (index) {
          switch (index) {
            case 0:
              dynamicKey.currentState?.scrollToTop();
              break;
            case 1:
              trendKey.currentState?.scrollToTop();
              break;
            case 2:
              myKey.currentState?.scrollToTop();
              break;
          }
        },
        backgroundColor: GSYColors.primarySwatch,
        indicatorColor: GSYColors.white,
        title: GSYTitleBar(
          context.l10n.app_name,
          rightWidget: InkWell(
            onTap: () {
              RenderBox renderBox2 =
                  rightKey.currentContext?.findRenderObject() as RenderBox;
              var position = renderBox2.localToGlobal(Offset.zero);
              var size = renderBox2.size;
              var centerPosition = Offset(
                position.dx + size.width / 2,
                position.dy + size.height / 2,
              );
              NavigatorUtils.goSearchPage(context, centerPosition);
            },
            child: Container(
              key: rightKey,
              alignment: Alignment.centerRight,
              child: Lottie.asset('static/file/search.json',
                  width: 70,
                  height: 80,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight),
            ),
          ),
        ),
      ),
    );
  }
}
