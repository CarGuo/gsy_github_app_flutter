import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/commitFile.dart';
import 'package:gsy_github_app_flutter/model/pull_request_review_thread.dart';
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
/// **行级 review comment 挂载（双通路）**：
/// initState 时并发拉 `/pulls/:n/comments`（一次拉全，按 [PullReviewComment.path]
/// 聚合到 [_commentsByPath]）。
///
/// - **A/2 折叠区**（App 层）：文件卡片下方追加"N 条评审评论"折叠区，
///   展开后显示每条评论：作者头像 + 行号 + markdown body，
///   长按走 resolveReviewThread mutation。用于**扫读 + 交互**。
/// - **A/3 webview 内联**（webview 层）：点击文件卡片打开 diff webview 时，
///   评论按行号内联到对应 diff 行下方，实现"评论跟在源码行下方"的沉浸阅读。
///   见 [_buildAddLineExtras] 与 [HtmlUtils.parseDiffSource] 的 `addLineExtras` 参数。
///
/// 两条路径**并存不互斥**：折叠区管交互，webview 管沉浸；outdated 评论
/// （line=null）只在 A/2 折叠区里以"该评论已过时"呈现，不进 webview 内联
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

  /// review comment id → 该 comment 所属 thread 是否已 resolved
  ///
  /// 与 [_commentsByPath] 同步刷新：拉 REST comments + GraphQL threads 后，
  /// 用 [PullRequestReviewThread.commentDatabaseIds] 与 [PullReviewComment.id]
  /// join 得到本 map。UI 侧色带 / badge 直接消费 `_resolvedMap[c.id]`：
  /// - true  → resolved（灰绿色带 + "已解决" badge）
  /// - false → unresolved（橙红色带 + "未解决" badge）
  /// - null  → thread 信息拉取失败或该 comment 未挂 thread，回退默认样式
  Map<int, bool> _resolvedMap = const {};

  /// review comment id → thread GraphQL node id（形如 `PRRT_kw...`）
  ///
  /// 长按触发 resolve / unresolve mutation 时需要 thread node id，而 REST
  /// comment 侧只有 databaseId。这个 map 让"点在 comment 上"能反查到"要操作
  /// 哪条 thread"，避免 mutation 时再多拉一次 threads。
  Map<int, String> _threadIdByComment = const {};

  /// 展开状态：filename -> 是否展开评论列表。默认全部收起，避免长 PR
  /// 一进来就把长评论全铺出来影响滚动性能。
  final Map<String, bool> _expanded = {};

  @override
  requestRefresh() async {
    // 首页 files / review comments / review threads 三路并发；files 结果作为
    // DataResult 返回给父 mixin 驱动列表填充，comments + threads 结果 join 后
    // 异步 setState 到 [_commentsByPath] / [_resolvedMap] / [_threadIdByComment]
    final results = await Future.wait<DataResult>([
      IssueRepository.getPullRequestFilesRequest(
          widget.userName, widget.reposName, widget.number,
          page: 1),
      IssueRepository.getPullReviewCommentsRequest(
          widget.userName, widget.reposName, widget.number),
      IssueRepository.getPullRequestReviewThreadsRequest(
          widget.userName, widget.reposName, widget.number),
    ]);
    final DataResult filesRes = results[0];
    final DataResult commentsRes = results[1];
    final DataResult threadsRes = results[2];
    if (commentsRes.result && commentsRes.data is List<PullReviewComment>) {
      final grouped = <String, List<PullReviewComment>>{};
      for (final c in commentsRes.data as List<PullReviewComment>) {
        final key = c.path;
        if (key == null || key.isEmpty) continue;
        grouped.putIfAbsent(key, () => []).add(c);
      }
      // threads 拉取失败不阻塞 comments 展示；此时 _resolvedMap 保持空，
      // UI 层看到 null 会回退到默认样式，与 A/1 之前的行为一致
      final resolved = <int, bool>{};
      final threadIdBy = <int, String>{};
      if (threadsRes.result &&
          threadsRes.data is List<PullRequestReviewThread>) {
        for (final t
            in threadsRes.data as List<PullRequestReviewThread>) {
          final bool r = t.isResolved ?? false;
          for (final int dbId in t.commentDatabaseIds) {
            resolved[dbId] = r;
            if (t.id != null) threadIdBy[dbId] = t.id!;
          }
        }
      }
      if (mounted) {
        setState(() {
          _commentsByPath = grouped;
          _resolvedMap = resolved;
          _threadIdByComment = threadIdBy;
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
          // A/3：把 review comment 按 head 分支行号分组，喂给 parseDiffSource
          // 让 webview 里 diff 行下方直接内联 comment。App 层折叠区（A/2）
          // 保留不动，形成"扫读用折叠区 + 沉浸阅读用 webview 内联"双通路
          final extras = _buildAddLineExtras(comments);
          final html = HtmlUtils.generateCode2HTml(
              HtmlUtils.parseDiffSource(vm.patch, false,
                  addLineExtras: extras),
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

  /// A/3：把当前文件的 review comment 折叠成 {addLine: html片段}。
  ///
  /// 关键点：
  /// - key 采用 [PullReviewComment.line]（**新版本 blob 行号**，非
  ///   [PullReviewComment.displayLine]）。原因见下方 outdated 规则
  /// - 同一行可能有多条评论（review 多轮 / 多人），value 里拼接**多个**
  ///   `<div class="gsy-review-comment">` 兄弟节点
  /// - body 走**极简 escape**：`< > & " '` 五字符 + `\n→<br>`。
  ///   不接 markdown 解析（会引入前端 md 库或本地 markdown 依赖，成本大）；
  ///   对 fixture #938 的短英文段落足够
  /// - **outdated / removed-side 评论**（`line == null` 但 `originalLine != null`）
  ///   **不进 webview 内联**：那种评论指向已被后续 push 冲掉的旧 blob 行号，
  ///   若拿 `originalLine` 与 `curAddNumber`（新 blob 行号）比较会**位置错乱**
  ///   （旧号可能在新 diff 里没同号或误命中不相关行）。这类 comment 完全
  ///   降级到 A/2 折叠区（已用"该评论已过时"文案兜底）
  static Map<int, String>? _buildAddLineExtras(List<PullReviewComment> comments) {
    if (comments.isEmpty) return null;
    final Map<int, StringBuffer> buckets = {};
    for (final c in comments) {
      // 严格要求 line 非 null：只对 head 侧有明确锚点的 comment 做内联。
      // 这与 [_buildCommentTile] 用 displayLine 展示"已过时"是刻意分工的：
      // 折叠区能容忍 outdated（展示文案即可），webview 内联不能容忍（会错位）
      final int? line = c.line;
      if (line == null) continue;
      final buf = buckets.putIfAbsent(line, () => StringBuffer());
      final String author = _htmlEscape(c.user?.login ?? '');
      final String body = _htmlEscape((c.body ?? '').trim())
          .replaceAll('\n', '<br>');
      // 内联样式而非全靠 class，防某些 webview 平台丢失 <style>（保险起见）
      buf.write('<div class="gsy-review-comment" '
          'style="background:#fff8e1;color:#222;border-left:3px solid #d97706;'
          'padding:6px 10px;margin:2px 0;font-family:sans-serif;'
          'font-size:12px;white-space:normal;">');
      buf.write('<div style="font-weight:bold;color:#0366d6;'
          'margin-bottom:4px;">@$author</div>');
      buf.write('<div>$body</div>');
      buf.write('</div>');
    }
    if (buckets.isEmpty) return null;
    return buckets.map((k, v) => MapEntry(k, v.toString()));
  }

  /// 极简 HTML escape。覆盖 5 个 HTML 特殊字符（`& < > " '`）。
  /// - 覆盖 `'` 是为了将来该函数被复用到属性上下文（如 `title='...'`）时
  ///   也不留 XSS 缺口；当前 A/3 只把结果放在 text node 里，`'` 不必转义，
  ///   但工具函数应默认按最保守语义处理
  /// - 不引入 dart:convert / html 包，保持零依赖单一函数
  static String _htmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
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

    // resolve 状态三态：
    // - true  → 属于 resolved thread，灰绿色带 + "已解决" badge
    // - false → 属于 unresolved thread，橙红色带 + "未解决" badge
    // - null  → threads GraphQL 拉取失败 / 该 comment 未挂 thread（罕见），
    //           保持 A/1 原样式，不误导用户
    final bool? resolved = _resolvedMap[c.id];
    // 色带：resolved 灰绿 (#8b949e-ish) / unresolved 橙红 (#f97316) / 未知回退
    final Color barColor = resolved == null
        ? GSYColors.subLightTextColor
        : (resolved ? const Color(0xff6e7681) : const Color(0xffd97706));
    // badge 文案 + 底色配色沿用色带同色系，浅底 + 深字，避免深色文字看不清
    // 注意：badge 展示的是**状态**（已解决/未解决），不是**动作**（标记/撤销）；
    // 后者归长按 BottomSheet 里的 ListTile 使用
    final String? badgeText = resolved == null
        ? null
        : (resolved
            ? context.l10n.pr_files_review_thread_resolved
            : context.l10n.pr_files_review_thread_unresolved);
    final Color? badgeBg = resolved == null
        ? null
        : (resolved ? const Color(0xffe6efe9) : const Color(0xfffdecd4));
    final Color? badgeFg = resolved == null
        ? null
        : (resolved ? const Color(0xff116329) : const Color(0xff9a3412));

    return InkWell(
      onTap: () {
        if (c.htmlUrl != null && c.htmlUrl!.isNotEmpty) {
          CommonUtils.launchOutURL(c.htmlUrl, context);
        }
      },
      onLongPress: () => _onCommentLongPress(context, c),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: barColor, width: 2),
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
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 10, color: badgeFg),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
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

  /// review comment 长按 → 弹 BottomSheet 提供 resolve / unresolve 操作
  ///
  /// - 若该 comment 未挂 thread（罕见：threads 拉取失败），直接不响应，
  ///   避免用户看到无意义的空 sheet
  /// - resolved 状态下 sheet 显示"撤销已解决"（unresolve action）
  /// - unresolved 状态下 sheet 显示"标记已解决"（resolve action）
  /// - 权限来自 AGENTS.md §4.1「PR review thread mark as resolved / unresolved」
  ///   2026-07-06 转正的允许写清单，不越界
  void _onCommentLongPress(BuildContext context, PullReviewComment c) {
    final String? threadId = _threadIdByComment[c.id];
    if (threadId == null) return;
    final bool resolved = _resolvedMap[c.id] ?? false;
    final String actionText = resolved
        ? context.l10n.event_action_unresolved
        : context.l10n.event_action_resolved;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  resolved ? Icons.replay : Icons.check_circle_outline,
                  color: resolved
                      ? const Color(0xffd97706)
                      : const Color(0xff116329),
                ),
                title: Text(actionText),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toggleReviewThreadResolved(threadId, resolved);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 执行 mutation + 就地 patch _resolvedMap
  ///
  /// - 走 [IssueRepository.resolveReviewThreadRequest] /
  ///   [IssueRepository.unresolveReviewThreadRequest]，成功后返回最新
  ///   `isResolved` 布尔值
  /// - **只 patch 触发操作的这条 comment 所属 thread 相关的所有 comment**：
  ///   遍历 [_threadIdByComment] 找到相同 threadId 的所有 commentId 一起改，
  ///   避免"一条 thread 里 5 条 comment 只有 1 条色带更新"的错乱
  /// - 失败弹 toast，不改状态
  Future<void> _toggleReviewThreadResolved(
      String threadId, bool currentResolved) async {
    final DataResult res = currentResolved
        ? await IssueRepository.unresolveReviewThreadRequest(threadId)
        : await IssueRepository.resolveReviewThreadRequest(threadId);
    if (!mounted) return;
    if (!res.result || res.data is! bool) {
      showToast(context.l10n.network_error);
      return;
    }
    final bool newResolved = res.data as bool;
    setState(() {
      final Map<int, bool> next = Map<int, bool>.from(_resolvedMap);
      _threadIdByComment.forEach((int dbId, String tid) {
        if (tid == threadId) next[dbId] = newResolved;
      });
      _resolvedMap = next;
    });
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
