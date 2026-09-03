import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
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

  const new({super.key});

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

    // rail 入口用 GSY 抽象的 GSYAdaptiveDestination，具体渲染成
    // Material NavigationRail / 第三方 adaptive shell / Cupertino 侧栏由
    // GSYAdaptiveNavigation 注入的 delegate 决定，页面本身不感知。
    final List<GSYAdaptiveDestination> railDestinations = [
      GSYAdaptiveDestination(
        icon: GSYICons.MAIN_DT,
        label: context.l10n.home_dynamic,
      ),
      GSYAdaptiveDestination(
        icon: GSYICons.MAIN_QS,
        label: context.l10n.home_trend,
      ),
      GSYAdaptiveDestination(
        icon: GSYICons.MAIN_MY,
        label: context.l10n.home_my,
      ),
    ];

    ///增加返回按键监听
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // P2 §2 修复（2026-09-03）：双栏 Master-Detail 模式下若 detail 栈里有
        // push 出去的页面（如 RepositoryDetailPage），系统 back 应先弹一层
        // detail，退回 GSYTwoPaneDetailPlaceholder，而不是直接把 HomePage 送到
        // 桌面。单栏 / compact 下 detailNavigatorKey 未挂载或栈为空，
        // canPop 会返回 false，走原本的 _dialogExitApp 行为，兼容既有体验。
        final detailNav =
            GSYAdaptiveNavigation.instance.detailNavigatorKey.currentState;
        if (detailNav != null && detailNav.canPop()) {
          detailNav.pop();
          return;
        }
        _dialogExitApp(context);
      },
      child: GSYTabBarWidget(
        drawer: const HomeDrawer(),
        type: TabType.bottom,
        // shell 顶层 host：dispose 时清 detail 栈，防御 logout / relogin
        // 快速切换场景下 GlobalKey reparent 到新树可能残留的栈。
        // 语义与副作用详见 [GSYTabBarWidget.clearDetailStackOnDispose]。
        clearDetailStackOnDispose: true,
        tabItems: tabs,
        tabViews: [
          DynamicPage(key: dynamicKey),
          TrendPage(key: trendKey),
          MyPage(key: myKey),
        ],
        railDestinations: railDestinations,
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
