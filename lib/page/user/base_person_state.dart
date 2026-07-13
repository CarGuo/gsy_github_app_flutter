import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/model/user_org.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/user/base_person_provider.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/only_share_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_header.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_pinned.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_sponsors.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_status.dart';

/// Created by guoshuyu
/// Date: 2018-08-30

abstract class BasePersonState<T extends StatefulWidget> extends State<T>
    with
        AutomaticKeepAliveClientMixin<T>,
        GSYListState<T>,
        SingleTickerProviderStateMixin {
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIKey =
      GlobalKey<NestedScrollViewRefreshIndicatorState>();

  final List<UserOrg> orgList = [];

  @override
  showRefreshLoading() {
    Future.delayed(const Duration(seconds: 0), () {
      refreshIKey.currentState!.show().then((e) {});
      return true;
    });
  }

  @protected
  renderItem(index, User userInfo, String beStaredCount, Color? notifyColor,
      VoidCallback? refreshCallBack, List<UserOrg> orgList) {
    if (userInfo.type == "Organization") {
      return UserItem(
          UserItemViewModel.fromMap(pullLoadWidgetControl.dataList[index]),
          onPressed: () {
        NavigatorUtils.goPerson(
            context,
            UserItemViewModel.fromMap(pullLoadWidgetControl.dataList[index])
                .userName);
      });
    } else {
      Event event = pullLoadWidgetControl.dataList[index];
      return GSYEventItem(EventViewModel.fromEventMap(context, event), onPressed: () {
        EventUtils.ActionUtils(context, event, "");
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => true;

  @protected
  FetchHonorDataProvider get headerProvider;

  @protected
  Widget buildContainer(BuildContext context);

  @protected
  getUserOrg(String? userName) {
    if (page <= 1 && userName != null) {
      UserRepository.getUserOrgsRequest(userName, page, needDb: true)
          .then((res) {
        if (res != null && res.result) {
          setState(() {
            orgList.clear();
            orgList.addAll(res.data);
          });
          return res.next?.call();
        }
        return Future.value(null);
      }).then((res) {
        if (res != null && res.result) {
          setState(() {
            orgList.clear();
            orgList.addAll(res.data);
          });
        }
      });
    }
  }

  @protected
  List<Widget> sliverBuilder(
      BuildContext context,
      bool innerBoxIsScrolled,
      User userInfo,
      Color? notifyColor,
      String beStaredCount,
      refreshCallBack) {
    double headerSize = 210;
    double bottomSize = 70;
    double chartSize =
        (userInfo.login != null && userInfo.type == "Organization") ? 70 : 215;

    return <Widget>[
      ///头部信息
      SliverPersistentHeader(
        pinned: true,
        delegate: GSYSliverHeaderDelegate(
            maxHeight: headerSize,
            minHeight: headerSize,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              return Transform.translate(
                offset: Offset(0, -shrinkOffset),
                child: SizedBox.expand(
                  child: UserHeaderItem(
                      userInfo, beStaredCount, Theme.of(context).primaryColor,
                      notifyColor: notifyColor,
                      refreshCallBack: refreshCallBack,
                      orgList: orgList),
                ),
              );
            }),
      ),

      ///悬停的item
      SliverPersistentHeader(
        pinned: true,
        floating: true,
        delegate: GSYSliverHeaderDelegate(
            maxHeight: bottomSize,
            minHeight: bottomSize,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              var radius = Radius.circular(10 - shrinkOffset / bottomSize * 10);
              return SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 0, right: 0),
                  child: OnlyShareInstanceWidget(
                    value: headerProvider,
                    child: UserHeaderBottom(userInfo, radius),
                  ),
                ),
              );
            }),
      ),

      ///提交图表
      SliverPersistentHeader(
        delegate: GSYSliverHeaderDelegate(
            maxHeight: chartSize,
            minHeight: chartSize,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              return SizedBox.expand(
                child: SizedBox(
                  height: chartSize,
                  child: UserHeaderChart(userInfo),
                ),
              );
            }),
      ),

      ///Status chip（贡献图之后、Pinned 之前）
      ///
      /// - 只在 login 就位 + 非 Organization 时挂载：组织没有 status 字段，
      ///   provider 层虽然也会兜底 null，但这里前置短路可以直接省一次 GraphQL 请求
      /// - 与 Pinned 一致用 [SliverToBoxAdapter]，未设置 status 时 [UserStatusSection]
      ///   返回 [SizedBox.shrink]，官方"没状态就没这块"的行为
      if (userInfo.login != null &&
          userInfo.login!.isNotEmpty &&
          userInfo.type != "Organization")
        SliverToBoxAdapter(
          child: UserStatusSection(userName: userInfo.login!),
        ),

      ///Pinned Repositories（贡献图之后、事件流之前）
      ///
      /// 用 [SliverToBoxAdapter] 而不是 [SliverPersistentHeader]：
      /// - pinned 数据空时 [UserPinnedSection] 会返回 [SizedBox.shrink]，Adapter
      ///   随之不占高度，官方就是"没 pinned 就没这块"的行为
      /// - 用户名有可能为 null（拉取失败时）→ 只在 login 就位时挂载 provider
      if (userInfo.login != null && userInfo.login!.isNotEmpty)
        SliverToBoxAdapter(
          child: UserPinnedSection(userName: userInfo.login!),
        ),

      ///Sponsors（Pinned 之后、事件流之前）
      ///
      /// GitHub Sponsors 一等公民能力，官方 profile 页 pinned 附近展示"Supporters"栏。
      /// 与 Pinned/Status 一致用 [SliverToBoxAdapter]：未启用 sponsors 或
      /// totalCount==0 时 [UserSponsorsSection] 返回 [SizedBox.shrink]，Adapter
      /// 不占高度。User 与 Organization 都可能是 sponsor 目标账号（GitHub Sponsors
      /// 对 Org 开放），所以此处不加 `type != Organization` 短路。
      if (userInfo.login != null && userInfo.login!.isNotEmpty)
        SliverToBoxAdapter(
          child: UserSponsorsSection(userName: userInfo.login!),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);// See AutomaticKeepAliveClientMixin.
    ///局部 scoped 的 riverpod provider 方案
    ///配合 @Riverpod(dependencies: [])
    return ProviderScope(
      /// 必要时还可以覆盖
      //overrides: [],
      child: buildContainer(context),
    );
  }

  ///获取用户仓库前100个star统计数据
  getHonor() async {
    var _ = globalContainer.refresh(headerProvider);
  }
}
