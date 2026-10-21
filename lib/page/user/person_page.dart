// ignore_for_file: annotate_overrides

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/event_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/model/user_org.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/page/user/base_person_provider.dart';
import 'package:gsy_github_app_flutter/page/user/user_contribution_provider.dart';
import 'package:gsy_github_app_flutter/page/user/user_pinned_provider.dart';
import 'package:gsy_github_app_flutter/page/user/user_sponsors_provider.dart';
import 'package:gsy_github_app_flutter/page/user/user_status_provider.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/page/user/base_person_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';

/// 个人详情
/// Created by guoshuyu
/// Date: 2018-07-18
class PersonPage extends StatefulWidget {
  static const String sName = "person";

  /// 用户登录名是本页存在的前提，不允许为 null——构造契约由非空类型强制，
  /// 调用方 [NavigatorUtils.goPerson] 在入口判空。
  final String userName;

  const new(this.userName, {super.key});

  @override
  PersonState createState() => PersonState();
}

class PersonState extends BasePersonState<PersonPage> {
  String beStaredCount = "---";

  bool focusStatus = false;

  String focus = "";

  User? userInfo = User.empty();

  // ignore: overridden_fields
  final List<UserOrg> orgList = [];

  new();

  ///处理用户信息显示
  _resolveUserInfo(res) {
    if (isShow) {
      setState(() {
        userInfo = res.data;
      });
    }
  }

  @override
  Future<void> handleRefresh() async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    page = 1;

    ///获取网络用户数据
    var userResult =
        await UserRepository.getUserInfo(widget.userName, needDb: true);
    if (userResult != null && userResult.result) {
      // 2026-10-21: 一次资料加载只在发布首份有效资料前失效一次辅助数据。
      // 首次挂载由 watch 发起请求；主动刷新/缓存重进使现有 provider 失效。
      // 放在列表加载末尾会把本轮已经挂载的五类 provider 再请求一次；
      // cache.next 只更新资料，不能为同一个加载周期重复失效。
      _invalidateProfileData(userResult.data);
      _resolveUserInfo(userResult);
      if (userResult.next != null) {
        userResult.next().then((resNext) {
          _resolveUserInfo(resNext);
        });
      }
    } else {
      return;
    }

    ///获取用户动态或者组织成员
    var res = await _getDataLogic();
    resolveRefreshResult(res);
    resolveDataResult(res);
    if (res.next != null) {
      var resNext = await res.next();
      resolveRefreshResult(resNext);
      resolveDataResult(resNext);
    }
    isLoading = false;

    ///获取当前用户的关注状态
    _getFocusStatus();

    return;
  }

  void _invalidateProfileData(User profile) {
    final login = profile.login;
    if (login == null || login.isEmpty) {
      return;
    }
    // invalidate 不会创建尚未订阅的 family；首次挂载仍由各 section watch 加载。
    globalContainer.invalidate(fetchHonorDataProvider(login));
    globalContainer.invalidate(fetchUserPinnedItemsProvider(login));
    globalContainer.invalidate(fetchUserSponsorsProvider(login));
    // 与 section 的挂载规则一致：组织没有 status 与贡献日历。
    if (profile.type == "Organization") {
      return;
    }
    globalContainer.invalidate(fetchUserStatusProvider(login));
    globalContainer.invalidate(fetchUserContributionCalendarProvider(login));
  }

  ///获取当前用户的关注状态
  _getFocusStatus() async {
    var focusRes = await UserRepository.checkFollowRequest(widget.userName);
    if (isShow) {
      setState(() {
        focus = (focusRes != null && focusRes.result)
            ? context.l10n.user_focus
            : context.l10n.user_un_focus;
        focusStatus = (focusRes != null && focusRes.result);
      });
    }
  }

  ///获取用户信息里的用户名。
  ///
  /// 首帧（用户资料尚未从网络/缓存返回）时 [userInfo] 仍是 [User.empty]，
  /// login 为 null，此时退用页面入参 [widget.userName]——它是非空构造参数，
  /// 本页存在的前提。
  ///
  /// 必须显式声明返回 String：历史上这里无返回类型（等价 dynamic），且 null
  /// 分支误返回 User.empty() 对象、另一分支返回 String?，调用方
  /// fetchHonorDataProvider(需要 String) 的静态检查被 dynamic 绕过，
  /// 运行时 Riverpod 生成代码里 `argument as String` 才抛
  /// "Null is not a subtype of String"。
  String _getUserName() {
    return userInfo?.login ?? widget.userName;
  }

  ///获取用户动态或者组织成员
  _getDataLogic() async {
    if (userInfo!.type == "Organization") {
      return await UserRepository.getMemberRequest(_getUserName(), page);
    }
    getUserOrg(_getUserName());
    return await EventRepository.getEventRequest(_getUserName(),
        page: page, needDb: page <= 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {}

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  @override
  Widget buildContainer(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: GSYTitleBar(
          (userInfo != null && userInfo!.login != null) ? userInfo!.login : "",
          rightWidget: GSYCommonOptionWidget(
            url: userInfo?.html_url,
          ),
        )),
        floatingActionButton: FloatingActionButton(
            child: AutoSizeText(
              focus,
              minFontSize: 8,
              maxLines: 1,
            ),
            onPressed: () async {
              ///非组织成员可以关注
              if (focus == '') {
                return;
              }
              if (userInfo!.type == "Organization") {
                showToast(context.l10n.user_focus_no_support);
                return;
              }
              await CommonUtils.runWithLoading(
                context,
                () => UserRepository.doFollowRequest(
                    widget.userName, focusStatus),
              );
              if (mounted) {
                _getFocusStatus();
              }
            }),
        body: GSYNestedPullLoadWidget(
          pullLoadWidgetControl,
          (BuildContext context, int index) =>
              renderItem(index, userInfo!, beStaredCount, null, null, orgList),
          handleRefresh,
          onLoadMore,
          refreshKey: refreshIKey,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return sliverBuilder(context, innerBoxIsScrolled, userInfo!, null,
                beStaredCount, null);
          },
        ));
  }

  @override
  FetchHonorDataProvider get headerProvider {
    return fetchHonorDataProvider(_getUserName());
  }
}
