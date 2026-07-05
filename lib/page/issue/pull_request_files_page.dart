import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/commitFile.dart';
import 'package:gsy_github_app_flutter/model/pull_review_comment.dart';
import 'package:gsy_github_app_flutter/page/push/widget/push_coed_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';

/// PR 变更文件页
///
/// 复用 push detail 里已经跑成熟的 [PushCodeItem]，因为 GitHub
/// `/repos/:o/:r/pulls/:n/files` 与 commit files payload 是同一个 schema
/// （filename/status/additions/deletions/patch/blob_url），
/// 我们把响应体映射成 [CommitFile]，再交给 [PushCodeItem] 渲染 patch，
/// 点击后走 `HtmlUtils.parseDiffSource` + `NavigatorUtils.gotoCodeDetailPlatform`
/// 打开 web view 高亮 diff。
///
/// **行级 review comment 挂载**：
/// initState 时并发拉 `/pulls/:n/comments`（一次拉全，按 [PullReviewComment.path]
/// 聚合到 [_commentsByPath]）。文件卡片下方追加"N 条评审评论"折叠区，展开后
/// 显示每条评论：作者头像 + 行号 + markdown body，点击整条跳 GitHub html_url。
///
/// 为什么不 inline 到 diff webview 行下：
/// 1. patch 走 webview 生成 HTML，注入 comment DOM 与 [HtmlUtils.generateCode2HTml]
///    的生成逻辑深度耦合，改动大且易错
/// 2. 90% 的 review 场景只需要"知道哪一行有评论，评论是什么"，卡片下方展开
///    已足够表达。真要跳到具体行，每条 comment 还带 GitHub html_url 兜底
class PullRequestFilesPage extends StatefulWidget {
  final String userName;
  final String reposName;
  final int number;

  const PullRequestFilesPage(this.userName, this.reposName, this.number,
      {super.key});

  @override
  State<PullRequestFilesPage> createState() => _PullRequestFilesPageState();
}

class _PullRequestFilesPageState extends State<PullRequestFilesPage>
    with
        AutomaticKeepAliveClientMixin<PullRequestFilesPage>,
        GSYListState<PullRequestFilesPage> {
  /// 按文件路径聚合的行级 review comment。initState 一次拉全，
  /// 后续 file 分页翻页时**不重拉**，因为 PR 打开期间 comment 变动概率很低，
  /// 强一致由手动下拉刷新触发（下面 requestRefresh 会重拉）。
  Map<String, List<PullReviewComment>> _commentsByPath = const {};

  /// 展开状态：filename -> 是否展开评论列表。默认全部收起，避免长 PR
  /// 一进来就把长评论全铺出来影响滚动性能。
  final Map<String, bool> _expanded = {};

  @override
  requestRefresh() async {
    // 首页 files 与 review comments 并发拉；files 结果作为 DataResult 返回给
    // 父 mixin 驱动列表填充，comments 结果异步 setState 到 [_commentsByPath]
    final results = await Future.wait<DataResult>([
      IssueRepository.getPullRequestFilesRequest(
          widget.userName, widget.reposName, widget.number,
          page: 1),
      IssueRepository.getPullReviewCommentsRequest(
          widget.userName, widget.reposName, widget.number),
    ]);
    final DataResult filesRes = results[0];
    final DataResult commentsRes = results[1];
    if (commentsRes.result && commentsRes.data is List<PullReviewComment>) {
      final grouped = <String, List<PullReviewComment>>{};
      for (final c in commentsRes.data as List<PullReviewComment>) {
        final key = c.path;
        if (key == null || key.isEmpty) continue;
        grouped.putIfAbsent(key, () => []).add(c);
      }
      if (mounted) {
        setState(() {
          _commentsByPath = grouped;
        });
      }
    }
    return filesRes;
  }

  @override
  requestLoadMore() async {
    // 翻更多 files 页时不重拉 comments（避免带宽浪费）
    return await IssueRepository.getPullRequestFilesRequest(
        widget.userName, widget.reposName, widget.number,
        page: page);
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  Widget _renderItem(BuildContext context, int index) {
    final CommitFile file = pullLoadWidgetControl.dataList[index] as CommitFile;
    final vm = PushCodeItemViewModel.fromMap(file);
    final comments = _commentsByPath[file.fileName] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PushCodeItem(vm, () {
          final html = HtmlUtils.generateCode2HTml(
              HtmlUtils.parseDiffSource(vm.patch, false),
              backgroundColor: GSYColors.webDraculaBackgroundColorString,
              lang: '',
              userBR: false);
          NavigatorUtils.gotoCodeDetailPlatform(
            context,
            title: vm.name,
            reposName: widget.reposName,
            userName: widget.userName,
            path: vm.patch,
            data: html,
            branch: '',
          );
        }),
        if (comments.isNotEmpty) _buildCommentSection(context, file, comments),
      ],
    );
  }

  Widget _buildCommentSection(BuildContext context, CommitFile file,
      List<PullReviewComment> comments) {
    final expanded = _expanded[file.fileName] ?? false;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded[file.fileName ?? ''] = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 14,
                    color: GSYColors.subTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n
                        .pr_files_review_comments_count(comments.length),
                    style: GSYConstant.smallSubText,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: GSYColors.subTextColor,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            ...comments.map((c) => _buildCommentTile(context, c)),
        ],
      ),
    );
  }

  Widget _buildCommentTile(BuildContext context, PullReviewComment c) {
    // outdated：line 与 position 都缺，说明这条 comment 挂在了已被后续 push
    // 冲掉的 hunk 上，走"该评论已过时"文案兜底
    final int? line = c.displayLine;
    final String lineLabel = (line != null)
        ? context.l10n.pr_files_review_line(line)
        : context.l10n.pr_files_review_outdated;

    return InkWell(
      onTap: () {
        if (c.htmlUrl != null && c.htmlUrl!.isNotEmpty) {
          CommonUtils.launchOutURL(c.htmlUrl, context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: GSYColors.subLightTextColor, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GSYUserIconWidget(
                  image: c.user?.avatar_url,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.user?.login ?? '',
                    style: GSYConstant.smallSubText,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(lineLabel, style: GSYConstant.smallSubLightText),
              ],
            ),
            const SizedBox(height: 4),
            if ((c.body ?? '').trim().isNotEmpty)
              GSYMarkdownWidget(
                markdownData: c.body!.trim(),
                baseUrl: "",
                shrinkWrap: true,
                scroll: false,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pr_files_title(widget.number)),
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        _renderItem,
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
