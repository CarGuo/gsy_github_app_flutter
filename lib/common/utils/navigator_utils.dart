import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/model/common_list_datatype.dart';
import 'package:gsy_github_app_flutter/page/code_detail_page_web.dart';
import 'package:gsy_github_app_flutter/page/common_list_page.dart';
import 'package:gsy_github_app_flutter/page/debug/debug_data_page.dart';
import 'package:gsy_github_app_flutter/page/discussion/discussion_detail_page.dart';
import 'package:gsy_github_app_flutter/page/gsy_webview.dart';
import 'package:gsy_github_app_flutter/page/home/home_page.dart';
import 'package:gsy_github_app_flutter/page/honor_list_page.dart';
import 'package:gsy_github_app_flutter/page/issue/issue_detail_page.dart';
import 'package:gsy_github_app_flutter/page/issue/pull_request_files_page.dart';
import 'package:gsy_github_app_flutter/page/login/login_page.dart';
import 'package:gsy_github_app_flutter/page/login/login_webview.dart';
import 'package:gsy_github_app_flutter/page/notify/notify_page.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_user_page.dart';
import 'package:gsy_github_app_flutter/page/user/person_page.dart';
import 'package:gsy_github_app_flutter/page/photoview_page.dart';
import 'package:gsy_github_app_flutter/page/push/push_detail_page.dart';
import 'package:gsy_github_app_flutter/page/release/release_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_page.dart';
import 'package:gsy_github_app_flutter/page/search/search_page.dart';
import 'package:gsy_github_app_flutter/page/user_profile_page.dart';
import 'package:gsy_github_app_flutter/widget/never_overscroll_indicator.dart';

/// 导航栏
/// Created by guoshuyu
/// Date: 2018-07-16
class NavigatorUtils {
  ///替换
  static pushReplacementNamed(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
//    if (navigator == null) {
//      try {
//        navigator = Navigator.of(context);
//      } catch (e) {
//        error = true;
//      }
//    }
//
//    if (replace) {
//      ///如果可以返回，清空开始，然后塞入
//      if (!error && navigator.canPop()) {
//        navigator.pushAndRemoveUntil(
//          router,
//          ModalRoute.withName('/'),
//        );
//      } else {
//        ///如果不可返回，直接替换当前
//        navigator.pushReplacement(router);
//      }
//    } else {
//      navigator.push(router);
//    }
  }

  ///切换无参数页面
  static pushNamed(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  ///主页
  static goHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, HomePage.sName);
  }

  ///登录页
  static goLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, LoginPage.sName);
  }

  ///图片预览
  static gotoPhotoViewPage(BuildContext context, String? url) {
    Navigator.pushNamed(context, PhotoViewPage.sName, arguments: url);
  }

  ///个人中心
  static goPerson(BuildContext context, String? userName) {
    // P2 §2 Master-Detail：user profile 属于 detail 语义（列表 avatar tap 进来），
    // expanded 下 push 到右列，避免 root 覆盖 shell。
    _openDetailOrRouter(context, PersonPage(userName),
        routeName: 'person/$userName');
  }

  ///请求数据调试页面
  static goDebugDataPage(BuildContext context) {
    return NavigatorRouter(context, const DebugDataPage());
  }

  ///仓库详情
  static Future goReposDetail(
      BuildContext context, String? userName, String? reposName) {
    // P2 §2 Master-Detail：
    // - 双栏（canShowTwoPane）时把仓库详情 push 到右列的 detailNavigator，
    //   保持左列 master 列表可见，符合大屏 M3 Master-Detail 规范；
    // - 单栏（compact / medium / 用户 forceFullScreenDetail）时行为完全等价
    //   于原来的 SizeRoute 转场，不影响窄屏视觉体感。
    //
    // 消费点（trend / event_utils / notify / person / repos_header_item / …）
    // 全都通过这一个入口跳仓库详情，因此在这里做一次集中改造覆盖率最高，
    // 不需要在 15+ 处 caller 里各自判断 canShowTwoPane。
    final adaptiveNav = GSYAdaptiveNavigation.instance;
    final bool two = adaptiveNav.canShowTwoPane(context);
    if (two) {
      return adaptiveNav.openDetail(
        context,
        pageContainer(
          RepositoryDetailPage(userName!, reposName!),
          context,
        ),
        routeName: 'repos/$userName/$reposName',
      );
    }
    ///利用 SizeRoute 动画大小打开
    return Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RepositoryDetailPage(userName!, reposName!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            double begin = 0;
            double end = 1;
            var curve = Curves.ease;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return Align(
              child: SizeTransition(
                sizeFactor: animation.drive(tween),
                child: NeverOverScrollIndicator(
                  needOverload: false,
                  child: child,
                ),
              ),
            );
          },
        ));
  }

  ///荣耀列表
  static Future goHonorListPage(BuildContext context, List? list) {
    // P2 §2 Master-Detail：荣耀榜属于 detail 语义（从 person 页 stats 条 tap 进来），
    // expanded 下走右列内嵌 Navigator，避免用 root push 覆盖 shell。
    final adaptiveNav = GSYAdaptiveNavigation.instance;
    final Widget page = HonorListPage(list);
    if (adaptiveNav.canShowTwoPane(context)) {
      return adaptiveNav.openDetail(
        context,
        pageContainer(page, context),
        routeName: 'honor-list',
      );
    }
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          double begin = 0;
          double end = 1;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return Align(
            child: SizeTransition(
              sizeFactor: animation.drive(tween),
              child: NeverOverScrollIndicator(
                needOverload: false,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  ///仓库版本列表
  static Future goReleasePage(BuildContext context, String? userName,
      String? reposName, String releaseUrl, String tagUrl) {
    // P2 §2 Master-Detail：release 列表是仓库详情内的子 detail，与 goReposDetail
    // 同源；expanded 下应贴到右列。notify_page `.then((_) => _forceRefresh())`
    // 依赖 pop 后 Future 完成，openDetail 保持等价语义。
    final Widget page = ReleasePage(userName, reposName, releaseUrl, tagUrl);
    return _openDetailOrRouter(context, page,
        routeName: 'release/$userName/$reposName');
  }

  ///issue详情
  static Future goIssueDetail(
      BuildContext context, String? userName, String? reposName, String num,
      {bool needRightLocalIcon = false}) {
    // P2 §2 Master-Detail：见 [goReposDetail] 注释，issue 走的路径相同。
    // notify_page 里 `goIssueDetail(...).then((_) => _forceRefresh())` 依赖
    // 返回的 Future 在 detail pop 后完成，openDetail 的返回值语义与
    // `Navigator.push` 保持一致，因此改造后 caller 行为不变。
    final adaptiveNav = GSYAdaptiveNavigation.instance;
    final Widget page = IssueDetailPage(
      userName,
      reposName,
      num,
      needHomeIcon: needRightLocalIcon,
    );
    if (adaptiveNav.canShowTwoPane(context)) {
      return adaptiveNav.openDetail(
        context,
        pageContainer(page, context),
        routeName: 'issue/$userName/$reposName/$num',
      );
    }
    return NavigatorRouter(context, page);
  }

  /// GitHub Discussion 详情（roadmap §3.1 骨架阶段）
  ///
  /// 与 [goIssueDetail] 平行的入口：Discussion 走 GraphQL，不复用 issue REST。
  static Future goDiscussionDetail(
    BuildContext context,
    String owner,
    String reposName,
    int number, {
    bool needRightLocalIcon = false,
  }) {
    // P2 §2 Master-Detail：discussion 与 issue 同源，expanded 下走右列。
    return _openDetailOrRouter(
      context,
      DiscussionDetailPage(
        owner,
        reposName,
        number,
        needHomeIcon: needRightLocalIcon,
      ),
      routeName: 'discussion/$owner/$reposName/$number',
    );
  }

  ///通用列表
  static gotoCommonList(BuildContext context, String? title, String showType,
      CommonListDataType dataType,
      {String? userName, String? reposName}) {
    // P2 §2 Master-Detail：通用列表 (contributors / stargazers / watchers /
    // forks / branches …) 属于仓库详情下的子 detail，expanded 下走右列。
    _openDetailOrRouter(
      context,
      CommonListPage(
        title,
        showType,
        dataType,
        userName: userName,
        reposName: reposName,
      ),
      routeName: 'common-list/$showType/$userName/$reposName',
    );
  }

  ///仓库详情通知
  static Future goNotifyPage(BuildContext context) {
    // P2 §2 Master-Detail：notify 属于 drawer 打开的详情面板，expanded 下走右列。
    return _openDetailOrRouter(context, const NotifyPage(),
        routeName: 'notify');
  }

  ///用户趋势
  static Future goTrendUserPage(BuildContext context) {
    // P2 §2 Master-Detail：trend user 是 drawer / home 入口打开的详情，expanded 下走右列。
    return _openDetailOrRouter(context, const TrendUserPage(),
        routeName: 'trend-user');
  }

  ///搜索
  static Future goSearchPage(BuildContext context, Offset centerPosition) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Builder(builder: (BuildContext context) {
          return pageContainer(SearchPage(centerPosition), context);
        });
      },
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x01000000),
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  ///提交详情
  static Future goPushDetailPage(BuildContext context, String? userName,
      String? reposName, String? sha, bool needHomeIcon) {
    // P2 §2 Master-Detail：commit 详情属于仓库详情下的子 detail
    // （dynamic PushEvent tap / notify tap / release compare tap），
    // expanded 下走右列。这是本轮修复的核心：event tap 后 push loading
    // dismiss → goPushDetailPage 之前会走 root Navigator 盖 shell，
    // 观感是"loading 关掉后新页面从底部弹出并覆盖整个双栏"。
    return _openDetailOrRouter(
      context,
      PushDetailPage(
        sha,
        userName,
        reposName,
        needHomeIcon: needHomeIcon,
      ),
      routeName: 'push/$userName/$reposName/$sha',
    );
  }

  ///PR 变更文件页
  static Future goPullRequestFiles(BuildContext context, String userName,
      String reposName, int number) {
    // P2 §2 Master-Detail：PR files 属于 PR 详情下的子 detail，expanded 下走右列。
    return _openDetailOrRouter(
      context,
      PullRequestFilesPage(userName, reposName, number),
      routeName: 'pr-files/$userName/$reposName/$number',
    );
  }

  ///全屏Web页面
  static Future goGSYWebView(BuildContext context, String url, String? title) {
    return NavigatorRouter(context, GSYWebView(url, title));
  }

  ///登陆Web页面
  static Future goLoginWebView(BuildContext context, String url, String title) {
    return NavigatorRouter(context, LoginWebView(url, title));
  }

  ///文件代码详情Web
  static gotoCodeDetailPageWeb(BuildContext context,
      {String? title,
      String? userName,
      String? reposName,
      String? path,
      String? data,
      String? branch,
      String? lang,
      String? htmlUrl}) {
    // P2 §2 Master-Detail：文件代码 web 详情属于仓库详情下的子 detail，
    // expanded 下走右列内嵌 Navigator，避免把整块 shell 盖住。
    _openDetailOrRouter(
      context,
      CodeDetailPageWeb(
        title: title,
        userName: userName,
        reposName: reposName,
        path: path,
        data: data,
        lang: lang,
        branch: branch,
        htmlUrl: htmlUrl,
      ),
      routeName: 'code-detail/$userName/$reposName/$path',
    );
  }

  ///根据平台跳转文件代码详情Web
  static gotoCodeDetailPlatform(BuildContext context,
      {String? title,
      String? userName,
      String? reposName,
      String? path,
      String? data,
      String? branch,
      String? lang,
      String? htmlUrl}) {
    NavigatorUtils.gotoCodeDetailPageWeb(
      context,
      title: title,
      reposName: reposName,
      userName: userName,
      data: data,
      path: path,
      lang: lang,
      branch: branch,
    );
  }

  ///用户配置
  static gotoUserProfileInfo(BuildContext context) {
    // P2 §2 Master-Detail：user profile edit 属于用户详情的子 detail，
    // expanded 下走右列。
    _openDetailOrRouter(context, const UserProfileInfo(),
        routeName: 'user-profile-info');
  }

  ///公共打开方式
  static NavigatorRouter(BuildContext context, Widget widget) {
    return Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => pageContainer(widget, context)));
  }

  /// P2 §2 Master-Detail 集中分派入口。
  ///
  /// 目的：把"expanded 时 push 到右列 detailNavigator、compact/medium 时走
  /// 传统全屏 CupertinoPageRoute"这条判断，从 15+ 个 caller 里回收到一处。
  /// 这样：
  /// - 新加 detail 页时只用调 `_openDetailOrRouter`，不用每个 caller 自己 `if
  ///   canShowTwoPane`；
  /// - 判定口径统一走 [GSYAdaptiveNavigation.instance.canShowTwoPane]（内含
  ///   `forceFullScreenDetail` 用户偏好），避免漂移；
  /// - 返回 Future 的语义与 `NavigatorRouter` 一致（detail pop 才完成），保住
  ///   `.then((_) => _forceRefresh())` 一类 caller 姿势。
  ///
  /// 只对**真正的 detail 页**使用：webview / dialog / photoview / 全屏预览
  /// 类不能塞进右列内嵌 Navigator（不希望 rail + master 保留），仍走
  /// [NavigatorRouter]。
  static Future<T?> _openDetailOrRouter<T extends Object?>(
    BuildContext context,
    Widget page, {
    required String routeName,
  }) {
    // caller 通常拼 `'release/$userName/$reposName'`，其中一些参数在 Dart
    // 类型层是 `String?`。null 会被 `$` 插值成字面量字符串 `'null'`，
    // 写成 route settings.name 会得到 `'release/null/null'` 这种脏 key，
    // 反过来污染 talker / observer / 埋点。这里做一次基线兜底，把 `/null`
    // 段替换成 `/-`，caller 无需改签名（reviewer N3，2026-09-03）。
    final sanitizedRouteName = routeName.replaceAll('/null', '/-');
    final adaptiveNav = GSYAdaptiveNavigation.instance;
    if (adaptiveNav.canShowTwoPane(context)) {
      return adaptiveNav.openDetail<T>(
        context,
        pageContainer(page, context),
        routeName: sanitizedRouteName,
      );
    }
    return Navigator.push<T>(
      context,
      CupertinoPageRoute<T>(
        builder: (context) => pageContainer(page, context),
        settings: RouteSettings(name: sanitizedRouteName),
      ),
    );
  }

  ///Page页面的容器，做一次通用自定义
  static Widget pageContainer(widget, BuildContext context) {
    return MediaQuery(

        ///不受系统字体缩放影响
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: NeverOverScrollIndicator(
          needOverload: false,
          child: widget,
        ));
  }

  ///弹出 dialog
  static Future<T?> showGSYDialog<T>({
    required BuildContext context,
    bool barrierDismissible = true,
    WidgetBuilder? builder,
  }) {
    return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) {
          return MediaQuery(

              ///不受系统字体缩放影响
              data: MediaQueryData.fromView(
                      WidgetsBinding.instance.platformDispatcher.views.first)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: NeverOverScrollIndicator(
                needOverload: false,
                child: SafeArea(child: builder!(context)),
              ));
        });
  }
}
