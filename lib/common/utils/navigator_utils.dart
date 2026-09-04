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
  ///
  /// RouteLevel: rootFullscreen —— 通过命名路由挂到根 Navigator，覆盖 shell 全屏预览图片。
  /// 归属规则详见 [docs/01-architecture/route-topology.md §4](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md)。
  /// 内部禁止调 [_openDetailOrRouter] / [goPerson] / [goReposDetail] / [goIssueDetail]
  /// 一类 shellDetail caller：本页不在 shell 树里，push 到 detailNavigator 会被自身盖住。
  static gotoPhotoViewPage(BuildContext context, String? url) {
    Navigator.pushNamed(context, PhotoViewPage.sName, arguments: url);
  }

  ///个人中心
  static goPerson(BuildContext context, String? userName) {
    // P2 §2 Master-Detail：user profile 属于 detail 语义（列表 avatar tap 进来），
    // expanded 下 push 到右列，避免 root 覆盖 shell。
    _openDetailOrRouter(context,
        routeName: 'person/$userName',
        pageBuilder: (_) => PersonPage(userName));
  }

  ///请求数据调试页面
  ///
  /// RouteLevel: rootFullscreen —— 通过 [NavigatorRouter] push 到根 Navigator，
  /// 全屏调试面板，非 shell detail 语义。归属规则详见
  /// [docs/01-architecture/route-topology.md §4](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md)。
  /// 内部禁止调 [_openDetailOrRouter] / [goPerson] / [goReposDetail] / [goIssueDetail]
  /// 一类 shellDetail caller：本页盖在 shell 上，右列 detail 不可见，用户会看到"点了没反应"。
  static goDebugDataPage(BuildContext context) {
    return NavigatorRouter(context, const DebugDataPage());
  }

  ///仓库详情
  static Future goReposDetail(
      BuildContext context, String? userName, String? reposName) {
    // P2 §2 Master-Detail：
    // - 双栏（canShowTwoPane）时把仓库详情 push 到右列的 detailNavigator，
    //   保持左列 master 列表可见，符合大屏 M3 Master-Detail 规范；
    // - 单栏（compact / medium / 用户 forceFullScreenDetail）时走
    //   [_openDetailOrRouter] 的 CupertinoPageRoute 全屏 push，与其它
    //   shellDetail 一致。
    //
    // **route-topology v0.2.2 订正**：原先 compact 侧使用 PageRouteBuilder +
    // SizeTransition 做自定义放大转场；本轮为了支持"断点跨越时把仓库详情
    // 从 root 侧迁到 detail 侧"（bug a 修复），需要 shellDetail 的路由构造
    // 走同一条 builder 记账通道。SizeTransition 只对首次 push 有意义，迁移
    // 重放不能再套一次转场（会看到详情"再放大一遍"）。收敛做法：把 compact
    // 侧转场退化为 Cupertino 默认转场，与 Search / Discussion 一致，观感虽
    // 少一次放大动画，但换来跨断点保栈 + 保业务参数，是本轮明确取舍。
    //
    // 消费点（trend / event_utils / notify / person / repos_header_item / …）
    // 全都通过这一个入口跳仓库详情，因此在这里做一次集中改造覆盖率最高。
    return _openDetailOrRouter(
      context,
      routeName: 'repos/$userName/$reposName',
      pageBuilder: (_) => RepositoryDetailPage(userName!, reposName!),
    );
  }

  ///荣耀列表
  static Future goHonorListPage(BuildContext context, List? list) {
    // P2 §2 Master-Detail：荣耀榜属于 detail 语义（从 person 页 stats 条 tap 进来），
    // expanded 下走右列内嵌 Navigator，避免用 root push 覆盖 shell。
    // v0.2.2 起 compact 侧退化为 Cupertino 转场以复用同一份 builder 记账通道
    // （见 [goReposDetail] 里同款订正说明）。
    return _openDetailOrRouter(
      context,
      routeName: 'honor-list',
      pageBuilder: (_) => HonorListPage(list),
    );
  }

  ///仓库版本列表
  static Future goReleasePage(BuildContext context, String? userName,
      String? reposName, String releaseUrl, String tagUrl) {
    // P2 §2 Master-Detail：release 列表是仓库详情内的子 detail，与 goReposDetail
    // 同源；expanded 下应贴到右列。notify_page `.then((_) => _forceRefresh())`
    // 依赖 pop 后 Future 完成，openDetail 保持等价语义。
    return _openDetailOrRouter(
      context,
      routeName: 'release/$userName/$reposName',
      pageBuilder: (_) => ReleasePage(userName, reposName, releaseUrl, tagUrl),
    );
  }

  ///issue详情
  static Future goIssueDetail(
      BuildContext context, String? userName, String? reposName, String num,
      {bool needRightLocalIcon = false}) {
    // P2 §2 Master-Detail：见 [goReposDetail] 注释，issue 走的路径相同。
    // notify_page 里 `goIssueDetail(...).then((_) => _forceRefresh())` 依赖
    // 返回的 Future 在 detail pop 后完成，_openDetailOrRouter 的返回值语义
    // 与 `Navigator.push` 保持一致，因此改造后 caller 行为不变。
    // v0.2.2 起走 [_openDetailOrRouter] 统一 builder 记账通道，compact 侧
    // 转场从 NavigatorRouter 的 CupertinoPageRoute 变成 _openDetailOrRouter
    // 内部构造的 CupertinoPageRoute（语义等价）。
    return _openDetailOrRouter(
      context,
      routeName: 'issue/$userName/$reposName/$num',
      pageBuilder: (_) => IssueDetailPage(
        userName,
        reposName,
        num,
        needHomeIcon: needRightLocalIcon,
      ),
    );
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
      routeName: 'discussion/$owner/$reposName/$number',
      pageBuilder: (_) => DiscussionDetailPage(
        owner,
        reposName,
        number,
        needHomeIcon: needRightLocalIcon,
      ),
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
      routeName: 'common-list/$showType/$userName/$reposName',
      pageBuilder: (_) => CommonListPage(
        title,
        showType,
        dataType,
        userName: userName,
        reposName: reposName,
      ),
    );
  }

  ///仓库详情通知
  static Future goNotifyPage(BuildContext context) {
    // P2 §2 Master-Detail：notify 属于 drawer 打开的详情面板，expanded 下走右列。
    return _openDetailOrRouter(context,
        routeName: 'notify', pageBuilder: (_) => const NotifyPage());
  }

  ///用户趋势
  static Future goTrendUserPage(BuildContext context) {
    // P2 §2 Master-Detail：trend user 是 drawer / home 入口打开的详情，expanded 下走右列。
    return _openDetailOrRouter(context,
        routeName: 'trend-user', pageBuilder: (_) => const TrendUserPage());
  }

  ///搜索
  ///
  /// RouteLevel: shellDetail —— 归入 detail 语义。route-topology.md §2 方向 A：
  /// compact / medium 与 forceFullScreenDetail 走 [CupertinoPageRoute] 全屏 push
  /// 到 caller Navigator（[_openDetailOrRouter] 单栏兜底路径），expanded 双栏
  /// 落右列 detailNavigator 走 [MaterialPageRoute] 默认转场
  /// （见 [GSYAdaptiveNavigationDelegate.openDetail] 实现，非 FadeTransition）。
  /// 避免 root overlay 覆盖 shell 导致内部 tap 卡片时右列 detail 变化不可见
  /// （用户以为"点了没反应"）。
  ///
  /// 弧形入场分档由 [SearchPage.build] 里 `context.isCompactWindow` 决定：
  /// - compact 保留 [CRAnimation] 圆形放大入场（消费 [centerPosition]）；
  /// - medium / expanded 直接返回 [Scaffold]，不再包 ClipPath；转场由外层
  ///   route 兜底（Material/Cupertino）。
  /// [centerPosition] 在 medium/expanded 分档下 SearchPage 内部会忽略。
  static Future goSearchPage(BuildContext context, Offset centerPosition) {
    return _openDetailOrRouter(
      context,
      routeName: 'search',
      pageBuilder: (_) => SearchPage(centerPosition),
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
      routeName: 'push/$userName/$reposName/$sha',
      pageBuilder: (_) => PushDetailPage(
        sha,
        userName,
        reposName,
        needHomeIcon: needHomeIcon,
      ),
    );
  }

  ///PR 变更文件页
  static Future goPullRequestFiles(BuildContext context, String userName,
      String reposName, int number) {
    // P2 §2 Master-Detail：PR files 属于 PR 详情下的子 detail，expanded 下走右列。
    return _openDetailOrRouter(
      context,
      routeName: 'pr-files/$userName/$reposName/$number',
      pageBuilder: (_) => PullRequestFilesPage(userName, reposName, number),
    );
  }

  ///全屏Web页面
  ///
  /// RouteLevel: rootFullscreen —— 通过 [NavigatorRouter] push 到根 Navigator，
  /// 全屏 WebView 观感与 shell 无关。归属规则详见
  /// [docs/01-architecture/route-topology.md §4](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md)。
  /// 内部禁止调 [_openDetailOrRouter] / [goPerson] / [goReposDetail] / [goIssueDetail]
  /// 一类 shellDetail caller：本页盖在 shell 上，若再 push detail 到右列，用户不可见。
  static Future goGSYWebView(BuildContext context, String url, String? title) {
    return NavigatorRouter(context, GSYWebView(url, title));
  }

  ///登陆Web页面
  ///
  /// RouteLevel: rootFullscreen —— OAuth 授权 WebView，登录流程一次性全屏，与 shell 无关。
  /// 归属规则详见 [docs/01-architecture/route-topology.md §4](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md)。
  /// 内部禁止调 [_openDetailOrRouter] / shellDetail caller：登录时 shell 尚未装配，
  /// detailNavigatorKey 未挂载，push 会走 delegate 兜底 talker.warning 静默丢弃。
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
      routeName: 'code-detail/$userName/$reposName/$path',
      pageBuilder: (_) => CodeDetailPageWeb(
        title: title,
        userName: userName,
        reposName: reposName,
        path: path,
        data: data,
        lang: lang,
        branch: branch,
        htmlUrl: htmlUrl,
      ),
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
    _openDetailOrRouter(context,
        routeName: 'user-profile-info',
        pageBuilder: (_) => const UserProfileInfo());
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
  ///
  /// **签名订正（route-topology v0.2.2）**：改成接受 `pageBuilder: WidgetBuilder`
  /// 而非已构造 `Widget page`。原因：断点跨越（compact↔expanded）时需要把
  /// shellDetail 路由在源/目标 Navigator 之间迁移，Route 一旦 push 就绑定
  /// Navigator 无法直接搬移，必须靠 builder 在目标 Navigator 上重放同一批
  /// entry。builder 闭包天然捕获 caller 侧的业务参数（userName/reposName/
  /// centerPosition/...），所以重放后业务上下文保住；一次性 UI 状态（scroll
  /// offset / TextEditingController 里未提交草稿）会随 State 重建丢失，这是
  /// A 方案（跨断点迁移保状态）的合理近似解，符合 AGENTS.md "改动尽量限制
  /// 在当前功能域"（不上探 Riverpod 提状态）。
  static Future<T?> _openDetailOrRouter<T extends Object?>(
    BuildContext context, {
    required String routeName,
    required WidgetBuilder pageBuilder,
  }) {
    // caller 通常拼 `'release/$userName/$reposName'`，其中一些参数在 Dart
    // 类型层是 `String?`。null 会被 `$` 插值成字面量字符串 `'null'`，
    // 写成 route settings.name 会得到 `'release/null/null'` 这种脏 key，
    // 反过来污染 talker / observer / 埋点。这里做一次基线兜底，把 `/null`
    // 段替换成 `/-`，caller 无需改签名（reviewer N3，2026-09-03）。
    final sanitizedRouteName = routeName.replaceAll('/null', '/-');
    final adaptiveNav = GSYAdaptiveNavigation.instance;
    // 统一包一层 pageContainer（禁字体缩放 + 抑制 overscroll），保持与旧签名
    // 语义一致。builder 每次被 route 触发都会重新执行，因此断点迁移重放时
    // 也会走这层容器。
    WidgetBuilder wrapped = (ctx) => pageContainer(pageBuilder(ctx), ctx);
    // 把 entry 登记到 shell 记账栈，供 [GSYAdaptiveNavigation.migrateShellDetailStack]
    // 断点迁移时重放。**不论 push 到 root 还是 detail 都要记账**：
    // - compact 分档下 push 到 root，用户拉屏到 expanded 后需要迁到 detail；
    // - expanded 分档下 push 到 detail，用户折叠回 compact 后需要迁到 root。
    adaptiveNav.trackShellDetailEntry(GSYShellDetailEntry(
      routeName: sanitizedRouteName,
      builder: wrapped,
    ));
    if (adaptiveNav.canShowTwoPane(context)) {
      // 走 delegate.openDetail 的 widget 版签名（历史兼容），但 route settings.name
      // 使用同一个 sanitizedRouteName，让 observer 能识别；delegate 内部构造
      // MaterialPageRoute。
      return adaptiveNav.openDetail<T>(
        context,
        Builder(builder: wrapped),
        routeName: sanitizedRouteName,
      );
    }
    // compact / forceFullScreenDetail 分档：走根 Navigator 全屏 push，
    // observer 通过 [MaterialApp.navigatorObservers] 挂载后能识别 pop。
    return Navigator.push<T>(
      context,
      CupertinoPageRoute<T>(
        settings: RouteSettings(name: sanitizedRouteName),
        builder: wrapped,
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
