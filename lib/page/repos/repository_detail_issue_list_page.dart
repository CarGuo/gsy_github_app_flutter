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

  ///GitHub REST /repos/:o/:r/issues 支持 sort=created|updated|comments
  ///默认 created（与官方一致），仅通过筛选 dialog 调整
  String _sort = 'created';

  ///GitHub REST 排序方向 asc|desc，默认 desc
  String _direction = 'desc';

  ///多选 label 名（AND 匹配），空 set 等价于不加 label 过滤
  final Set<String> _selectedLabels = <String>{};

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
      final labelsParam =
          _selectedLabels.isEmpty ? null : _selectedLabels.join(',');
      return await context
          .read<ReposDetailProvider>()
          .getRepositoryIssueRequest(issueState,
              sort: _sort,
              direction: _direction,
              labels: labelsParam,
              page: page,
              needDb: page <= 1);
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
                  child: Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 8),
                      _buildFilterButton(context),
                    ],
                  ),
                ),
              );
            }),
      ),
    ];
  }

  ///筛选按钮（漏斗图标），当有活跃筛选时叠加小红点
  Widget _buildFilterButton(BuildContext context) {
    final hasActiveFilter = _sort != 'created' ||
        _direction != 'desc' ||
        _selectedLabels.isNotEmpty;
    return Material(
      color: Theme.of(context).primaryColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: Tooltip(
        message: context.l10n.repos_issue_filter,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _openFilterSheet,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list,
                    color: GSYColors.white, size: 22),
                if (hasActiveFilter)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///弹出筛选与排序面板，让用户配置 sort / direction / labels 三维筛选。
  ///面板本身用 StatefulBuilder 承载临时选择，Apply 后一次性写回外层 state
  ///并触发一次刷新；Clear 快捷回到默认。
  ///labels 通过 Consumer 订阅 provider，异步加载完成后自动 rebuild chips。
  void _openFilterSheet() {
    final provider = context.read<ReposDetailProvider>();
    // 触发一次懒加载 labels（不阻塞打开，dialog 内部按缓存渲染）
    provider.getRepositoryLabels();

    String tempSort = _sort;
    String tempDirection = _direction;
    final Set<String> tempLabels = Set<String>.from(_selectedLabels);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GSYColors.mainBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollCtl) {
                return SingleChildScrollView(
                  controller: scrollCtl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.repos_issue_filter_title,
                              style: GSYConstant.largeText,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempSort = 'created';
                                tempDirection = 'desc';
                                tempLabels.clear();
                              });
                            },
                            child: Text(context.l10n.repos_issue_filter_clear),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _sectionLabel(context.l10n.repos_issue_filter_sort),
                      _sortRow(setSheetState, tempSort, (v) => tempSort = v),
                      const SizedBox(height: 12),
                      _sectionLabel(context.l10n.repos_issue_filter_direction),
                      _directionRow(setSheetState, tempDirection,
                          (v) => tempDirection = v),
                      const SizedBox(height: 12),
                      _sectionLabel(context.l10n.repos_issue_filter_labels),
                      // provider 在 ReposDetailPage 路由内，sheet 通过 root
                      // Navigator overlay 打开时拿不到 InheritedWidget。
                      // 这里直接 AnimatedBuilder 订阅 ChangeNotifier。
                      AnimatedBuilder(
                        animation: provider,
                        builder: (_, __) =>
                            _labelChips(provider, setSheetState, tempLabels),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            _sort = tempSort;
                            _direction = tempDirection;
                            _selectedLabels
                              ..clear()
                              ..addAll(tempLabels);
                            Navigator.of(sheetContext).pop();
                            clearData();
                            showRefreshLoading();
                          },
                          child: Text(context.l10n.repos_issue_filter_apply),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GSYConstant.middleTextBold),
    );
  }

  Widget _sortRow(
      StateSetter setSheetState, String current, ValueChanged<String> onPick) {
    final options = <String, String>{
      'created': context.l10n.repos_issue_filter_sort_created,
      'updated': context.l10n.repos_issue_filter_sort_updated,
      'comments': context.l10n.repos_issue_filter_sort_comments,
    };
    return Wrap(
      spacing: 8,
      children: options.entries
          .map((e) => ChoiceChip(
                label: Text(e.value),
                selected: current == e.key,
                onSelected: (_) {
                  setSheetState(() => onPick(e.key));
                },
              ))
          .toList(),
    );
  }

  Widget _directionRow(
      StateSetter setSheetState, String current, ValueChanged<String> onPick) {
    final options = <String, String>{
      'desc': context.l10n.repos_issue_filter_direction_desc,
      'asc': context.l10n.repos_issue_filter_direction_asc,
    };
    return Wrap(
      spacing: 8,
      children: options.entries
          .map((e) => ChoiceChip(
                label: Text(e.value),
                selected: current == e.key,
                onSelected: (_) {
                  setSheetState(() => onPick(e.key));
                },
              ))
          .toList(),
    );
  }

  Widget _labelChips(ReposDetailProvider provider, StateSetter setSheetState,
      Set<String> tempLabels) {
    final labels = provider.labelsCache;
    if (labels == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(context.l10n.repos_issue_filter_labels_loading),
          ],
        ),
      );
    }
    if (labels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(context.l10n.repos_issue_filter_labels_empty),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: labels
          .map((name) => FilterChip(
                label: Text(name),
                selected: tempLabels.contains(name),
                onSelected: (selected) {
                  setSheetState(() {
                    if (selected) {
                      tempLabels.add(name);
                    } else {
                      tempLabels.remove(name);
                    }
                  });
                },
              ))
          .toList(),
    );
  }
}
