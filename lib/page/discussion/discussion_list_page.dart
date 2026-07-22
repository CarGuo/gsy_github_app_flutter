import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart' as gql;
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/discussion/widget/discussion_item.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_detail_provider.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:provider/provider.dart';

/// 仓库详情页下的 Discussions 列表 tab。
///
/// roadmap §3.1 "内容渲染阶段 + 仓库详情 tab" 的第 3 个子任务：
/// - 由 [RepositoryDetailPage] 在 `hasDiscussionsEnabled == true` 时才装配
/// - 不做过滤 / 搜索（本 commit 只保证"列表 → 详情"最小闭环），排序钉死
///   `UPDATED_AT DESC`，与 GitHub Web `/discussions` 默认视图对齐
/// - 分页语义：GraphQL 走 cursor 而非 page int，通过内部 `_endCursor` 记录，
///   [GSYListState.handleRefresh] 里的 `res.next` 我们不复用（不做"顺带拉第二页"），
///   避免与 §2.5 已经踩过的"闭包捕获 page=1 导致重复拉第一页"同款坑
class DiscussionListPage extends StatefulWidget {
  const DiscussionListPage({super.key});

  @override
  DiscussionListPageState createState() => DiscussionListPageState();
}

class DiscussionListPageState extends State<DiscussionListPage>
    with
        AutomaticKeepAliveClientMixin<DiscussionListPage>,
        GSYListState<DiscussionListPage> {
  /// GraphQL 光标：null 表示还没拉过 / 或是首页 refresh；有值代表可继续 loadMore
  String? _endCursor;

  /// GraphQL 侧标记，避免上拉到没有更多时还继续发请求
  bool _hasNextPage = true;

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  @override
  bool get wantKeepAlive => true;

  @override
  showRefreshLoading() {
    Future.delayed(const Duration(seconds: 0), () {
      refreshIndicatorKey.currentState?.show().then((e) {});
      return true;
    });
  }

  @override
  requestRefresh() async {
    // 注意：不在这里提前把 _endCursor / _hasNextPage 置空。
    // 曾经的写法 "_endCursor = null; _hasNextPage = true;" 会在网络异常时
    // 让 refresh 静默丢掉可用游标，之后再上拉直接命中 requestLoadMore
    // "_endCursor == null → 返回空" 分支，用户表现是"再也翻不到下一页"。
    // 现在把游标更新推迟到 _fetchPage 内部的**成功分支**里，异常路径不改状态。
    return _fetchPage(after: null, isRefresh: true);
  }

  @override
  requestLoadMore() async {
    if (!_hasNextPage || _endCursor == null) {
      // 已经拉完 / 没有 cursor 时不再打网络，直接返回空结果让 GSYListState 收敛
      return DataResult(<Map<String, dynamic>>[], true);
    }
    return _fetchPage(after: _endCursor, isRefresh: false);
  }

  /// 覆盖 GSYListState 默认的 needLoadMore 判定，把"是否还有下一页"从
  /// `res.data.length >= Config.PAGE_SIZE` 切换到 GraphQL `pageInfo.hasNextPage`。
  /// 默认实现与 cursor 分页语义脱节：
  ///   - 最后一页正好返回满 20 条 → 默认判定"还有下一页"，
  ///     用户上拉 → requestLoadMore 内部走空返回 → UI 卡在"加载中"
  ///   - 首页 <20 条但 hasNextPage=true → 默认判定"没有下一页"，
  ///     用户永远看不到下一页数据
  /// override 后与 requestLoadMore 里的短路条件 `(!_hasNextPage)` 共享同一事实来源。
  @override
  resolveDataResult(res) {
    if (isShow) {
      setState(() {
        pullLoadWidgetControl.needLoadMore.value =
            (res != null && res.result == true) ? _hasNextPage : false;
      });
    }
  }

  /// 拉一页 discussions，把 GraphQL 响应压成 List<Map> 交给 GSYListState 的
  /// `pullLoadWidgetControl.dataList` 累加。返回值遵循 [DataResult] 契约：
  /// - `data` = 本页 node 列表
  /// - `result` = true/false（用于外层触发 setState + needLoadMore 计算）
  /// - `next` 一律为 null：**不**利用 handleRefresh 里"顺带拉第二页"的机制，
  ///   由用户显式上拉触发 loadMore，行为更可预测
  ///
  /// [isRefresh] 用于在**成功分支**判定是要不要 reset 游标：refresh 成功时
  /// endCursor/hasNextPage 来自服务器新的第一页；loadMore 成功时同样更新。
  /// 失败分支一律不动 _endCursor / _hasNextPage，保证下次上拉还能从旧游标续拉。
  Future<DataResult> _fetchPage(
      {String? after, required bool isRefresh}) async {
    final provider = context.read<ReposDetailProvider>();
    final owner = provider.userName;
    final name = provider.reposName;
    try {
      final QueryResult? res =
          await gql.getRepositoryDiscussions(owner, name, after: after);
      if (res == null || res.hasException) {
        printLog('DiscussionListPage fetch error: ${res?.exception}');
        return DataResult(<Map<String, dynamic>>[], false);
      }
      final Map<String, dynamic>? repo =
          res.data?['repository'] as Map<String, dynamic>?;
      final Map<String, dynamic>? discussions =
          repo?['discussions'] as Map<String, dynamic>?;
      final Map<String, dynamic>? pageInfo =
          discussions?['pageInfo'] as Map<String, dynamic>?;
      final List<dynamic> nodes =
          (discussions?['nodes'] as List<dynamic>?) ?? const <dynamic>[];
      // 只有成功拿到响应才更新游标状态；失败 / 网络异常时保留旧值
      _endCursor = pageInfo?['endCursor'] as String?;
      _hasNextPage = (pageInfo?['hasNextPage'] as bool?) ?? false;
      // 说明：真正的 needLoadMore 覆盖发生在 [resolveDataResult] override 里。
      // 在 _fetchPage 内部提前设置会被 GSYListState.handleRefresh / onLoadMore
      // 后续调用的默认 resolveDataResult 抹掉（默认走 PAGE_SIZE 判定），
      // 所以只有 override resolveDataResult 这一条钩子能真正生效。
      final List<Map<String, dynamic>> mapped = nodes
          .whereType<Map<String, dynamic>>()
          .map((n) => Map<String, dynamic>.from(n))
          .toList(growable: false);
      return DataResult(mapped, true);
    } catch (e) {
      printLog('DiscussionListPage fetch exception: $e');
      return DataResult(<Map<String, dynamic>>[], false);
    }
  }

  /// 渲染列表 item：从 GSYListState 的 dataList 取一条，喂给 [DiscussionItem]。
  /// 点击回调用 [NavigatorUtils.goDiscussionDetail]，与既有 discussion 事件
  /// 从动态流跳转的入口保持完全一致（同一个详情页、同签名）。
  Widget _renderItem(int index) {
    final raw = pullLoadWidgetControl.dataList[index];
    if (raw is! Map<String, dynamic>) {
      // 类型守卫兜底：与 §942 搜索页崩溃修复同源思路，避免 tab 快速切换 /
      // 异步竞态时给列表回填了不该有的类型
      return const SizedBox.shrink();
    }
    final vm = DiscussionItemViewModel.fromMap(raw);
    if (vm == null) return const SizedBox.shrink();
    final provider = context.read<ReposDetailProvider>();
    return DiscussionItem(
      viewModel: vm,
      onPressed: () {
        NavigatorUtils.goDiscussionDetail(
          context,
          provider.userName,
          provider.reposName,
          vm.number,
        );
      },
    );
  }

  Widget _buildDisabledPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.discussion_list_disabled,
          style: GSYConstant.normalText,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<ReposDetailProvider>();
    final enabled = provider.repository?.hasDiscussionsEnabled;

    // 兜底：即使外层 tab 显示条件已经把关，这里再拦一层。避免 tab 装配时机与
    // 首次 build 之间的短暂窗口拉了个无效请求。
    if (enabled == false) {
      return Scaffold(
        backgroundColor: GSYColors.mainBackgroundColor,
        body: _buildDisabledPlaceholder(context),
      );
    }

    return Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
