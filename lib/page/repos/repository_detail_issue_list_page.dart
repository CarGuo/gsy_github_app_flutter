import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_detail_provider.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_input_widget.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:provider/provider.dart';

/// 仓库详情issue列表
/// Created by guoshuyu
/// Date: 2018-07-19
class RepositoryDetailIssuePage extends StatefulWidget {
  const RepositoryDetailIssuePage({super.key});

  @override
  RepositoryDetailIssuePageState createState() =>
      RepositoryDetailIssuePageState();
}

///页面 KeepAlive ，同时支持 动画Ticker
class RepositoryDetailIssuePageState extends State<RepositoryDetailIssuePage>
    with
        AutomaticKeepAliveClientMixin<RepositoryDetailIssuePage>,
        GSYListState<RepositoryDetailIssuePage>,
        SingleTickerProviderStateMixin {
  /// NestedScrollView 的刷新状态 GlobalKey ，方便主动刷新使用
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIKey =
      GlobalKey<NestedScrollViewRefreshIndicatorState>();

  ///搜索 issue 文本
  String? searchText;

  ///过滤 issue 状态
  String? issueState;

  ///显示 issue 状态 tag index
  int? selectIndex;

  ///滑动控制器
  final ScrollController scrollController = ScrollController();

  @override
  showRefreshLoading() {
    Future.delayed(const Duration(seconds: 0), () {
      refreshIKey.currentState?.show().then((e) {});
      return true;
    });
  }

  ///绘制issue item
  _renderIssueItem(index, ReposDetailProvider provider) {
    IssueItemViewModel issueItemViewModel =
        IssueItemViewModel.fromMap(pullLoadWidgetControl.dataList[index]);
    return IssueItem(
      issueItemViewModel,
      onPressed: () {
        NavigatorUtils.goIssueDetail(context, provider.userName,
            provider.reposName, issueItemViewModel.number);
      },
    );
  }

  ///切换显示状态
  _resolveSelectIndex() {
    clearData();
    switch (selectIndex) {
      case 0:
        issueState = null;
        break;
      case 1:
        issueState = 'open';
        break;
      case 2:
        issueState = "closed";
        break;
    }

    ///回滚到最初位置
    scrollController
        .animateTo(0,
            duration: const Duration(milliseconds: 100), curve: Curves.bounceIn)
        .then((_) {
      showRefreshLoading();
    });
  }

  ///获取数据
  _getDataLogic(String? searchString) async {
    if (searchString == null || searchString.trim().isEmpty) {
      return await context
          .read<ReposDetailProvider>()
          .getRepositoryIssueRequest(issueState, page: page, needDb: page <= 1);
    }
    return await context
        .read<ReposDetailProvider>()
        .searchRepositoryRequest(searchString, issueState, page: page);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => true;

  @override
  requestLoadMore() async {
    return await _getDataLogic(searchText);
  }

  @override
  requestRefresh() async {
    return await _getDataLogic(searchText);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    var provider = context.watch<ReposDetailProvider>();
    return Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      appBar: AppBar(
        leading: Container(),
        flexibleSpace: (provider.repository?.hasIssuesEnabled == false)
            ? Container()
            : GSYSearchInputWidget(onSubmitted: (value) {
                searchText = value;
                _resolveSelectIndex();
              }, onSubmitPressed: () {
                _resolveSelectIndex();
              }),
        elevation: 0.0,
        backgroundColor: GSYColors.mainBackgroundColor,
      ),
      body: (provider.repository?.hasIssuesEnabled == false)
          ? Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {},
                    child: const Image(
                        image: AssetImage(GSYICons.DEFAULT_USER_ICON),
                        width: 70.0,
                        height: 70.0),
                  ),
                  Text(context.l10n.repos_no_support_issue,
                      style: GSYConstant.normalText),
                ],
              ),
            )

          ///支持嵌套滚动
          : GSYNestedPullLoadWidget(
              pullLoadWidgetControl,
              (BuildContext context, int index) =>
                  _renderIssueItem(index, provider),
              handleRefresh,
              onLoadMore,
              refreshKey: refreshIKey,
              scrollController: scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return _sliverBuilder(context, innerBoxIsScrolled);
              },
            ),
    );
  }

  ///绘制内置Header，支持部分停靠支持
  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    double height = 60;
    return <Widget>[
      ///头部信息显示
      SliverPersistentHeader(
        pinned: true,

        /// SliverPersistentHeaderDelegate 的实现
        delegate: GSYSliverHeaderDelegate(
            maxHeight: height,
            minHeight: height,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              ///根据数值计算偏差
              var lr = 10 - shrinkOffset / height * 10;
              var radius = Radius.circular(4 - shrinkOffset / height * 4);
              return SizedBox.expand(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: lr, bottom: 10, left: lr, right: lr),
                  child: GSYSelectItemWidget(
                    [
                      context.l10n.repos_tab_issue_all,
                      context.l10n.repos_tab_issue_open,
                      context.l10n.repos_tab_issue_closed,
                    ],
                    (selectIndex) {
                      this.selectIndex = selectIndex;
                      _resolveSelectIndex();
                    },
                    margin: const EdgeInsets.all(0.0),
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
