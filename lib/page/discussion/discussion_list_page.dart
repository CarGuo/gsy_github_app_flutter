import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart' as gql;
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';
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
  const new({super.key});

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

  /// 仓库 GraphQL node id（形如 `R_kw...`），是 [createDiscussion] mutation 的
  /// 必填参数。[RepositoryQL] 目前没存这个字段，惰性从
  /// [gql.getRepoDiscussionCategories] 的返回里取一次并缓存到本 State。
  String? _repositoryNodeId;

  /// 仓库当前可用的 discussion category 列表，惰性加载。
  /// 每个元素形如 `{id, name, emoji, description, isAnswerable}`。
  /// null 表示还没拉过；`const []` 表示已拉过但仓库确实没启用 discussion / 没配置
  /// category（后者理论上不发生，GitHub 默认 6 个 category）。
  List<Map<String, dynamic>>? _categories;

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
        talker.warning(
            'DiscussionListPage fetch error owner=$owner repo=$name after=$after '
            'exception=${res?.exception}');
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
    } catch (e, s) {
      talker.warning(
          'DiscussionListPage fetch exception owner=$owner repo=$name '
          'after=$after isRefresh=$isRefresh: $e',
          e,
          s);
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

    // 注意：这里**不**再挂内部 `floatingActionButton`。
    // 历史坑：曾经在这里挂过一个"新建 discussion" FAB，但父页
    // [RepositoryDetailPage] 的 Scaffold 已经在 `endDocked` 位置挂了一个"新建
    // issue" FAB（都是 endDocked + primaryColor + Icons.add），两者会**视觉重叠**
    // 成一个大黑圆，Material 规范里同一 `Scaffold` 树上不允许出现两个 FAB。
    // 现在改由父页根据 `provider.currentIndex` 命中的 tab 分派：
    // Issue tab → 原有 `_createIssue`；Discussion tab → 通过 GlobalKey 调本 State
    // 暴露出去的 [startCreateDiscussion]。
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

  /// 外部（父页 [RepositoryDetailPage]）通过 [GlobalKey] 触发的"新建 discussion"
  /// 入口。逻辑与原本内部 FAB 的 `onPressed` 完全一致——只是把访问方式从
  /// "自持 FAB" 改成 "父页 FAB 分派"，以解决两个 FAB 视觉重叠。
  Future<void> startCreateDiscussion() => _startCreateDiscussion(context);

  /// 触发"新建 discussion"完整流程：
  ///
  /// 1. 惰性加载仓库 category 列表 + 仓库 node id（[createDiscussion] mutation 强
  ///    要求 `repositoryId` + `categoryId`；两者都从
  ///    [gql.getRepoDiscussionCategories] 一次拿）
  /// 2. 弹分类选择底表让用户选一个 category（GitHub Web 也是先选分类再进入
  ///    title/body 输入页，语义对齐）
  /// 3. 弹通用 [showEditDialog]（复用 issue 的输入框视觉）让用户填 title/body
  /// 4. 提交 mutation，成功后 pop 并触发 [showRefreshLoading] 刷新列表让新条目
  ///    从服务器回来（不做乐观本地插入，避免服务端排序 / trailing linebreak 归
  ///    一化差异导致的抖动）
  ///
  /// 任一步骤失败或用户取消都直接返回，不留半成品 state。
  /// 权限说明：见 [AGENTS.md](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L193-L215)
  /// §允许 / 禁止的写操作清单——本入口对应"用户对**有权限**仓库发 discussion"
  /// 这一产品能力；AI/开发者做冒烟时禁止指向 `CarGuo/*` 主仓。
  Future<void> _startCreateDiscussion(BuildContext context) async {
    final provider = context.read<ReposDetailProvider>();
    // 仓库若未启用 discussion（理论上被 tab 层拦住，但同 build 里的兜底一致再判一次）
    if (provider.repository?.hasDiscussionsEnabled == false) {
      showToast(context.l10n.discussion_list_disabled);
      return;
    }

    final categories = await _ensureCategoriesLoaded(context);
    if (categories == null) {
      // _ensureCategoriesLoaded 内部已经 toast + talker.warning 过，这里静默返回
      return;
    }
    if (categories.isEmpty) {
      // 空分类会被缓存，后续每次点 FAB 都走到这里；必须每次都给反馈，否则只有
      // 第一次（fetch 路径）弹 toast、之后按钮看起来"死了"（reviewer 2026-09-09）。
      if (mounted) showToast(context.l10n.discussion_create_no_category);
      return;
    }

    if (!mounted) return;
    final Map<String, dynamic>? chosen =
        await _showCategoryPicker(context, categories);
    if (chosen == null) return; // 用户取消
    final categoryId = chosen['id'] as String?;
    final categoryName = chosen['name'] as String?;
    final repositoryId = _repositoryNodeId;
    if (categoryId == null || repositoryId == null) {
      talker.warning(
          'DiscussionListPage create precondition missing categoryId=$categoryId '
          'repositoryId=$repositoryId owner=${provider.userName} repo=${provider.reposName}');
      showToast(context.l10n.discussion_create_failed);
      return;
    }

    if (!mounted) return;
    // 复用 issue 的 dialog；hintText 走 discussion 语义
    String title = '';
    String body = '';
    // 正文必须给 controller：[IssueEditDialog] 的 Markdown 快捷输入条对
    // valueController! 强解，不传一点工具栏就抛空指针（reviewer 2026-09-08）。
    final valueController = TextEditingController();
    // dialogTitle 里带上 category 名，让用户明确"在哪个分类下发"
    final dialogTitle = categoryName == null || categoryName.isEmpty
        ? context.l10n.discussion_create
        : '${context.l10n.discussion_create} · $categoryName';
    await CommonUtils.showEditDialog(
      context,
      dialogTitle,
      (v) => title = v,
      (v) => body = v,
      () => _submitCreateDiscussion(
        context,
        repositoryId: repositoryId,
        categoryId: categoryId,
        title: title,
        body: body,
      ),
      needTitle: true,
      valueController: valueController,
      hintText: context.l10n.discussion_body_tip,
    ).whenComplete(valueController.dispose);
  }

  /// 从 GraphQL 拉一次 category 列表 + repository.id，缓存到 State。已缓存则直接返回。
  ///
  /// 失败路径：`res == null` / `hasException` / repository 为空 / discussionCategories
  /// 为空——任意一个都视为不可创建，toast 提示 + `talker.warning`，返回 null。
  /// 与 [_fetchPage] 一样只走 [talker.warning]（非 error），避免污染 error 面板；
  /// 但 message 里带上足够上下文（owner/repo/exception）便于 reviewer 复核。
  Future<List<Map<String, dynamic>>?> _ensureCategoriesLoaded(
      BuildContext context) async {
    if (_categories != null && _repositoryNodeId != null) {
      return _categories;
    }
    final provider = context.read<ReposDetailProvider>();
    final owner = provider.userName;
    final name = provider.reposName;
    try {
      final QueryResult? res =
          await gql.getRepoDiscussionCategories(owner, name);
      if (res == null || res.hasException) {
        talker.warning(
            'DiscussionListPage load categories error owner=$owner repo=$name '
            'exception=${res?.exception}');
        if (mounted) showToast(context.l10n.discussion_create_failed);
        return null;
      }
      final repo = res.data?['repository'] as Map<String, dynamic>?;
      if (repo == null) {
        talker.warning(
            'DiscussionListPage load categories: null repository owner=$owner repo=$name');
        if (mounted) showToast(context.l10n.discussion_create_failed);
        return null;
      }
      _repositoryNodeId = repo['id'] as String?;
      final cats = repo['discussionCategories'] as Map<String, dynamic>?;
      final nodes = (cats?['nodes'] as List<dynamic>?) ?? const <dynamic>[];
      _categories = nodes
          .whereType<Map<String, dynamic>>()
          .map((n) => Map<String, dynamic>.from(n))
          .toList(growable: false);
      if (_categories!.isEmpty) {
        // 只记日志不 toast：空分类的用户反馈统一在 [_startCreateDiscussion]
        // 触发点弹（否则缓存命中时这里不会走到，用户点了没反应）。
        talker.warning(
            'DiscussionListPage load categories: empty owner=$owner repo=$name');
      }
      return _categories;
    } catch (e, s) {
      talker.warning(
          'DiscussionListPage load categories exception owner=$owner repo=$name: $e',
          e,
          s);
      if (mounted) showToast(context.l10n.discussion_create_failed);
      return null;
    }
  }

  /// 分类选择底表：一个 modal bottom sheet，列出所有可用 category。
  ///
  /// 用 bottom sheet 而不是 popup dialog：GitHub Web 用整页选，Flutter 端保守
  /// 一点用 bottom sheet 与既有 comment 输入 / issue filter 视觉族群一致，避免
  /// 引入新的 dialog 变种。
  Future<Map<String, dynamic>?> _showCategoryPicker(
      BuildContext context, List<Map<String, dynamic>> categories) {
    // 与 issue 列表页过滤底表同一约定（repository_detail_issue_list_page.dart）：
    // expanded 双栏下底表应贴到右列 detail navigator，不能盖满整屏 root。
    final expanded = GSYAdaptiveNavigation.instance.canShowTwoPane(context);
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: !expanded,
      backgroundColor: GSYColors.mainBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    context.l10n.discussion_category,
                    style: GSYConstant.normalTextBold,
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext itemContext, int index) {
                      final c = categories[index];
                      // GraphQL 返回的 category.emoji 是 :mega: / :bulb: 这类
                      // shortcode，必须走 resolveEmojiShortcode 转 unicode
                      // （与 discussion_item.dart 的列表项一致）；否则底表里
                      // 直接显示 ":mega: Announcements" 原文。未命中 fallback 原文。
                      final rawEmoji = c['emoji'] as String?;
                      final emoji = (rawEmoji == null || rawEmoji.isEmpty)
                          ? null
                          : resolveEmojiShortcode(rawEmoji);
                      final name = (c['name'] as String?) ?? '';
                      final desc = (c['description'] as String?) ?? '';
                      return ListTile(
                        leading: (emoji == null || emoji.isEmpty)
                            ? null
                            : Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                        title: Text(name, style: GSYConstant.normalText),
                        subtitle: desc.isEmpty
                            ? null
                            : Text(desc, style: GSYConstant.smallSubText),
                        onTap: () => Navigator.of(sheetContext).pop(c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 走 [gql.createDiscussion] 提交 mutation。
  ///
  /// - title / body 空校验直接 toast 返回，不发网络（GitHub 服务端会 400，我们
  ///   本地先拦一层给出更贴合语境的提示）
  /// - 成功：先 pop loading + pop dialog，再触发 [showRefreshLoading] 让列表从
  ///   服务器重拉，保持排序一致
  /// - 失败：只 pop loading（保留 dialog 让用户改文案 retry），toast 报错
  Future<void> _submitCreateDiscussion(
    BuildContext context, {
    required String repositoryId,
    required String categoryId,
    required String title,
    required String body,
  }) async {
    final owner = context.read<ReposDetailProvider>().userName;
    final repo = context.read<ReposDetailProvider>().reposName;
    if (title.trim().isEmpty) {
      showToast(context.l10n.issue_edit_issue_title_not_be_null);
      return;
    }
    if (body.trim().isEmpty) {
      showToast(context.l10n.issue_edit_issue_content_not_be_null);
      return;
    }
    // 双栏（expanded）下 loading 在 root navigator、edit dialog 在本页所在的
    // 嵌套 detail navigator；await 前先抓两个 Navigator 句柄，关闭时各弹各的，
    // 不能用 Navigator.pop(context) 一刀切（会弹不到 root loading 而卡死）。
    final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);
    final NavigatorState localNav = Navigator.of(context);
    CommonUtils.showLoadingDialog(context);
    try {
      final QueryResult? res = await gql.createDiscussion(
        repositoryId: repositoryId,
        categoryId: categoryId,
        title: title.trim(),
        body: body.trim(),
      );
      if (!mounted) {
        // loading 在 root navigator 上，不随本页路由销毁；页面已退出也要 pop，
        // 否则 PopScope(canPop:false) 的转圈遮罩永久挡住整个 app。
        if (rootNav.mounted) rootNav.pop();
        return;
      }
      if (res == null || res.hasException) {
        talker.warning(
            'DiscussionListPage create error owner=$owner repo=$repo '
            'categoryId=$categoryId exception=${res?.exception}');
        rootNav.pop(); // 只关 loading；edit dialog 保留在嵌套 navigator 上让用户改完重试
        showToast(context.l10n.discussion_create_failed);
        return;
      }
      rootNav.pop(); // 关 loading（root）
      localNav.pop(); // 关 edit dialog（本页最近 navigator）
      showToast(context.l10n.discussion_create_success);
      // 让列表从服务器重拉第一页。**不**在这里提前把 _endCursor/_hasNextPage
      // 置空：_fetchPage 成功分支会用新首页的 pageInfo 覆盖游标；若刷新失败，
      // 保留旧游标，loadMore 仍可用（提前置空会在刷新失败后永久翻不了页）。
      showRefreshLoading();
    } catch (e, s) {
      talker.warning(
          'DiscussionListPage create exception owner=$owner repo=$repo '
          'categoryId=$categoryId: $e',
          e,
          s);
      // loading 在 root navigator 上，不随本页路由销毁；无论本 State 是否
      // 还活着都要把它 pop 掉，否则 PopScope(canPop:false) 的转圈遮罩永久
      // 挡住整个 app。toast 只在页面还在时给（页面退出时用户看不到）。
      if (rootNav.mounted) rootNav.pop();
      if (mounted) {
        showToast(context.l10n.discussion_create_failed);
      }
    }
  }
}
