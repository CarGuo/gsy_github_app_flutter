import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/repo_commit.dart';
import 'package:gsy_github_app_flutter/model/repository_ql.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_detail_provider.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_header_item.dart';
import 'package:provider/provider.dart';

/// 仓库详情动态信息页面
/// Created by guoshuyu
/// Date: 2018-07-18
class ReposDetailInfoPage extends StatefulWidget {
  const ReposDetailInfoPage({super.key});

  @override
  ReposDetailInfoPageState createState() => ReposDetailInfoPageState();
}

///页面 KeepAlive ，同时支持 动画Ticker
class ReposDetailInfoPageState extends State<ReposDetailInfoPage>
    with
        AutomaticKeepAliveClientMixin<ReposDetailInfoPage>,
        GSYListState<ReposDetailInfoPage>,
        TickerProviderStateMixin {
  ///滑动监听
  final ScrollController scrollController = ScrollController();

  ///当前显示tab
  int selectIndex = 0;

  ///初始化 header 默认大小，后面动态调整
  double headerSize = 270;

  /// NestedScrollView 的刷新状态 GlobalKey ，方便主动刷新使用
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIKey =
      GlobalKey<NestedScrollViewRefreshIndicatorState>();

  ///动画控制器
  AnimationController? animationController;

  @override
  showRefreshLoading() {
    Future.delayed(const Duration(seconds: 0), () {
      refreshIKey.currentState!.show().then((e) {});
      return true;
    });
  }

  ///渲染时间Item或者提交Item
  _renderEventItem(index) {
    var provider = context.read<ReposDetailProvider>();
    var item = pullLoadWidgetControl.dataList[index];
    if (selectIndex == 1 && item is RepoCommit) {
      ///提交
      return GSYEventItem(
        EventViewModel.fromCommitMap(item),
        onPressed: () {
          RepoCommit model = pullLoadWidgetControl.dataList[index];
          NavigatorUtils.goPushDetailPage(
              context, provider.userName, provider.reposName, model.sha, false);
        },
        needImage: false,
      );
    }
    return GSYEventItem(
      EventViewModel.fromEventMap(pullLoadWidgetControl.dataList[index]),
      onPressed: () {
        EventUtils.ActionUtils(context, pullLoadWidgetControl.dataList[index],
            "${provider.userName}/${provider.reposName}");
      },
    );
  }

  ///获取列表
  _getDataLogic() async {
    var provider = context.read<ReposDetailProvider>();
    if (selectIndex == 1) {
      return await provider.getReposCommitsRequest(
        page: page,
        needDb: page <= 1,
      );
    }
    return await provider.getRepositoryEventRequest(
      page: page,
      needDb: page <= 1,
    );
  }

  ///获取详情
  _getReposDetail() {
    context
        .read<ReposDetailProvider>()
        .getRepositoryDetailRequest(_getBottomWidget);
  }

  ///绘制底部状态
  List<Widget> _getBottomWidget(ReposDetailProvider provider) {
    ///根据网络返回数据，返回底部状态数据
    List<Widget> bottomWidget = (provider.bottomModel == null)
        ? []
        : <Widget>[
            /// star
            _renderBottomItem(
                provider.bottomModel!.starText, provider.bottomModel!.starIcon,
                () {
              CommonUtils.showLoadingDialog(context);
              return provider.doRepositoryStarRequest().then((result) {
                showRefreshLoading();
                var context = this.context;
                if (!context.mounted) return;
                Navigator.pop(context);
              });
            }),

            /// watch
            _renderBottomItem(provider.bottomModel!.watchText,
                provider.bottomModel!.watchIcon, () {
              CommonUtils.showLoadingDialog(context);
              return provider.doRepositoryWatchRequest().then((result) {
                showRefreshLoading();
                Navigator.pop(context);
              });
            }),

            ///fork
            _renderBottomItem("fork", GSYICons.REPOS_ITEM_FORK, () {
              CommonUtils.showLoadingDialog(context);
              return provider.createForkRequest().then((result) {
                showRefreshLoading();
                Navigator.pop(context);
              });
            }),
          ];
    return bottomWidget;
  }

  ///绘制底部状态 item
  _renderBottomItem(var text, var icon, var onPressed) {
    return TextButton(
        onPressed: onPressed,
        child: GSYIConText(
          icon,
          text,
          GSYConstant.smallText,
          GSYColors.primaryValue,
          15.0,
          padding: 5.0,
          mainAxisAlignment: MainAxisAlignment.center,
        ));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    _getReposDetail();
    return await _getDataLogic();
  }

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ///展示 select
    context.select<ReposDetailProvider, RepositoryQL?>((p) => p.repository);

    return GSYNestedPullLoadWidget(
      pullLoadWidgetControl,
      (BuildContext context, int index) => _renderEventItem(index),
      handleRefresh,
      onLoadMore,
      refreshKey: refreshIKey,
      scrollController: scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return _sliverBuilder(
            context, innerBoxIsScrolled, context.read<ReposDetailProvider>());
      },
    );
  }

  ///绘制内置Header，支持部分停靠支持
  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled,
      ReposDetailProvider provider) {
    return <Widget>[
      ///头部信息
      SliverPersistentHeader(
        delegate: GSYSliverHeaderDelegate(
          maxHeight: headerSize,
          minHeight: headerSize,
          vSyncs: this,
          snapConfig: FloatingHeaderSnapConfiguration(
            curve: Curves.bounceInOut,
            duration: const Duration(milliseconds: 10),
          ),
          child: OverflowBox(
            maxHeight: 1000,
            child: ReposHeaderItem(
              ReposHeaderViewModel.fromHttpMap(
                  provider.userName, provider.reposName, provider.repository),
              layoutListener: (size) {
                setState(() {
                  headerSize = size.height;
                });
              },
            ),
          ),
        ),
      ),

      ///动态放大缩小的tab控件
      SliverPersistentHeader(
        pinned: true,

        /// SliverPersistentHeaderDelegate 的实现
        delegate: GSYSliverHeaderDelegate(
            maxHeight: 60,
            minHeight: 60,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              ///根据数值计算偏差
              var lr = 10 - shrinkOffset / 60 * 10;
              var radius = Radius.circular(4 - shrinkOffset / 60 * 4);
              return SizedBox.expand(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10, left: lr, right: lr),
                  child: GSYSelectItemWidget(
                    [
                      context.l10n.repos_tab_activity,
                      context.l10n.repos_tab_commits,
                    ],
                    (index) {
                      ///切换时先滑动
                      scrollController
                          .animateTo(0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.bounceInOut)
                          .then((_) {
                        selectIndex = index;
                        clearData();
                        showRefreshLoading();
                      });
                    },
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(radius),
                    ),
                  ),
                ),
              );
            }),
      ),
    ];
  }
}
