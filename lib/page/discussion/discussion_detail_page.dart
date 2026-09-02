import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart' as gql;
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/discussion/discussion_comments_paging.dart';
import 'package:gsy_github_app_flutter/page/discussion/reaction_groups.dart';
import 'package:gsy_github_app_flutter/page/discussion/release_footer.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:gsy_github_app_flutter/widget/markdown/markdown_html_transformer.dart';

/// GitHub Discussions 阅读页（骨架）
///
/// 对齐 roadmap §3.1 第一项："Discussion 事件已经识别，动态流里能看到
/// '在 xxx 创建 讨论'，但点进去没页面"。
///
/// **当前阶段（骨架）**：
/// - 顶部标题 + 返回
/// - 拉一次 GraphQL [gql.getDiscussion]，成功后展示 title/author/bodyHTML 摘要
/// - 失败或未登录时展示 fallback 文案，不崩、不阻塞
///
/// **尚未做的下一阶段**（在 roadmap §3.1 anchor 里跟踪）：
/// - bodyHTML → 用 GSYMarkdownWidget 或 flutter_html 完整渲染
/// - comments/replies 展开、分页加载
/// - answer 徽标、reactions bar、投票交互
/// - 复用 [issue_timeline_item.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/issue/widget/issue_timeline_item.dart) 的事件行骨架
///   把 category_changed / answered 等 discussion 事件穿插进正文流
class DiscussionDetailPage extends StatefulWidget {
  final String owner;
  final String reposName;
  final int number;
  final bool needHomeIcon;

  const new(
    this.owner,
    this.reposName,
    this.number, {
    super.key,
    this.needHomeIcon = false,
  });

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  bool _loading = true;
  String? _errorText;
  Map<String, dynamic>? _discussion;

  /// comments 分页状态。首屏 [_load] 成功后填充；[_loadMore] 尾部追加。
  DiscussionCommentsPage _commentsPage = DiscussionCommentsPage.empty;

  /// 是否正在加载下一页；用于底部按钮转 loading 态、避免重复触发
  bool _loadingMore = false;

  /// 上一次 loadMore 的错误文案（用户可点击按钮重试）；成功后清空
  String? _loadMoreError;

  /// Discussion body 主体的 reactions 快照（规范化后，按 [kReactionContents]
  /// 固定顺序；未 react 且 count=0 的分组会被 [pickReactionGroups] 直接省略）。
  ///
  /// 与 [_discussion] 是"派生 vs 原始"的关系：每次首屏 [_load] 完成或
  /// mutation 返回后重算；点击 chip 时先经 [applyLocalReactionToggle]
  /// 乐观推进，再由 mutation 结果覆盖。
  List<ReactionSummary> _bodyReactions = const <ReactionSummary>[];

  /// 各 comment 的 reactions 快照，key = GraphQL node id（`DiscussionComment.id`，
  /// 就是 mutation 需要的 `subjectId`）。
  ///
  /// 分页 [_loadMore] 追加评论时会 merge 增量；已有 key 若被服务端再度返回
  /// 会被后一次覆盖（分页去重逻辑上 [_commentsPage] 已保证 id 唯一，这里也
  /// 依赖同一约束）。
  final Map<String, List<ReactionSummary>> _commentReactions =
      <String, List<ReactionSummary>>{};

  /// 正在处理中的 reaction subject id，用于避免同一个 subject 在网络返回
  /// 前被连点多次；同时也让 chip 显示 loading 视觉（本轮先不加 spinner，
  /// 只做 guard）。
  final Set<String> _reactionInflight = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final QueryResult? res = await gql.getDiscussion(
          widget.owner, widget.reposName, widget.number);
      if (!mounted) return;
      if (res == null || res.hasException) {
        setState(() {
          _loading = false;
          _errorText = res?.exception?.toString() ?? 'null result';
        });
        return;
      }
      final Map<String, dynamic>? repo =
          res.data?['repository'] as Map<String, dynamic>?;
      final Map<String, dynamic>? disc =
          repo?['discussion'] as Map<String, dynamic>?;
      setState(() {
        _loading = false;
        _discussion = disc;
        _commentsPage = pickCommentsPage(disc);
        _loadMoreError = null;
        _bodyReactions = pickReactionGroups(disc?['reactionGroups']);
        _commentReactions
          ..clear()
          ..addAll(_extractCommentReactions(_commentsPage.nodes));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  /// 拉取下一页评论。前置条件：`_commentsPage.hasNextPage == true` 且有游标。
  /// UI 侧的按钮已经根据这两个状态显隐，这里再做一次守卫防止竞态。
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (!_commentsPage.hasNextPage) return;
    final cursor = _commentsPage.endCursor;
    if (cursor == null || cursor.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final QueryResult? res = await gql.getDiscussionCommentsPage(
          widget.owner, widget.reposName, widget.number,
          after: cursor);
      if (!mounted) return;
      if (res == null || res.hasException) {
        setState(() {
          _loadingMore = false;
          _loadMoreError = res?.exception?.toString() ?? 'null result';
        });
        return;
      }
      final Map<String, dynamic>? repo =
          res.data?['repository'] as Map<String, dynamic>?;
      final Map<String, dynamic>? disc =
          repo?['discussion'] as Map<String, dynamic>?;
      final nextPage = pickCommentsPage(disc);
      setState(() {
        _loadingMore = false;
        _commentsPage = mergeCommentsPage(_commentsPage, nextPage);
        _commentReactions.addAll(_extractCommentReactions(nextPage.nodes));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadMoreError = e.toString();
      });
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            Text(context.l10n.loading_text),
          ],
        ),
      );
    }
    if (_errorText != null) {
      return _buildFallback(context.l10n.discussion_load_failed, _errorText);
    }
    if (_discussion == null) {
      return _buildFallback(context.l10n.discussion_not_found, null);
    }
    return _buildContent(_discussion!);
  }

  Widget _buildFallback(String main, String? detail) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              main,
              style: GSYConstant.middleTextBold,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GSYConstant.smallText,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              child: Text(context.l10n.discussion_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> disc) {
    final String title = (disc['title'] as String?) ?? '';
    final Map<String, dynamic>? author =
        disc['author'] as Map<String, dynamic>?;
    final String? authorLogin = author?['login'] as String?;
    final String? authorAvatar = author?['avatarUrl'] as String?;
    final Map<String, dynamic>? category =
        disc['category'] as Map<String, dynamic>?;
    final String? categoryName = category?['name'] as String?;
    final String? categoryEmojiRaw = category?['emoji'] as String?;
    final String? categoryEmoji =
        (categoryEmojiRaw == null || categoryEmojiRaw.isEmpty)
            ? null
            : resolveEmojiShortcode(categoryEmojiRaw);
    final int upvote = (disc['upvoteCount'] as int?) ?? 0;
    final bool answered = disc['answerChosenAt'] != null;
    final Map<String, dynamic>? answerNode =
        disc['answer'] as Map<String, dynamic>?;
    final Map<String, dynamic>? answerAuthor =
        answerNode?['author'] as Map<String, dynamic>?;
    final String? answerAuthorLogin = answerAuthor?['login'] as String?;
    // "作者自答"：answered=true 且 discussion.author.login == answer.author.login。
    // 任一 login 为 null（已注销）就不算 self-answer，避免 ghost 误命中。
    final bool selfAnswered = answered &&
        authorLogin != null &&
        answerAuthorLogin != null &&
        authorLogin == answerAuthorLogin;
    final bool locked = (disc['locked'] as bool?) ?? false;
    final int commentCount =
        ((disc['comments'] as Map<String, dynamic>?)?['totalCount'] as int?) ??
            0;
    final String? bodyHTML = disc['bodyHTML'] as String?;
    final String? url = disc['url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(
            context,
            title: title,
            authorLogin: authorLogin,
            authorAvatar: authorAvatar,
            categoryName: categoryName,
            categoryEmoji: categoryEmoji,
            upvote: upvote,
            commentCount: commentCount,
            answered: answered,
            selfAnswered: selfAnswered,
            locked: locked,
            url: url,
          ),
          _buildBodyCard(context, bodyHTML: bodyHTML),
          _buildCommentsSection(context),
        ],
      ),
    );
  }

  /// 顶部信息卡：primaryColor 深色底 + 白字（对齐 IssueHeaderItem）
  Widget _buildHeaderCard(
    BuildContext context, {
    required String title,
    required String? authorLogin,
    required String? authorAvatar,
    required String? categoryName,
    required String? categoryEmoji,
    required int upvote,
    required int commentCount,
    required bool answered,
    required bool selfAnswered,
    required bool locked,
    required String? url,
  }) {
    final safeAuthor = authorLogin ?? context.l10n.discussion_author_ghost;
    return GSYCardItem(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GSYUserIconWidget(
                  width: 40,
                  height: 40,
                  minTapTargetSize: null,
                  image: authorAvatar,
                  onPressed: (authorLogin == null || authorLogin.isEmpty)
                      ? null
                      : () {
                          NavigatorUtils.goPerson(context, authorLogin);
                        },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeAuthor,
                        style: GSYConstant.normalTextWhite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 标题（大号白粗体）
                      Text(
                        title,
                        style: GSYConstant.largeTextWhiteBold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // meta chips 行：category / answered / locked
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (categoryName != null && categoryName.isNotEmpty)
                  _headerChip(
                    icon: null,
                    emoji: categoryEmoji,
                    label: categoryName,
                    color: Colors.white.withValues(alpha: 0.18),
                    textColor: Colors.white,
                  ),
                if (answered)
                  _headerChip(
                    icon: Icons.check_circle,
                    emoji: null,
                    label: selfAnswered
                        ? context.l10n.discussion_answered_by_author_badge
                        : context.l10n.discussion_answered_badge,
                    color: Colors.greenAccent.shade400.withValues(alpha: 0.28),
                    textColor: Colors.white,
                  ),
                if (locked)
                  _headerChip(
                    icon: Icons.lock_outline,
                    emoji: null,
                    label: null,
                    color: Colors.white.withValues(alpha: 0.14),
                    textColor: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // 底栏：upvote / comments / 打开原链接
            Row(
              children: [
                GSYIConText(
                  Icons.arrow_upward,
                  '$upvote',
                  GSYConstant.smallSubLightText.copyWith(color: Colors.white),
                  Colors.white70,
                  16,
                  padding: 2.0,
                ),
                const SizedBox(width: 14),
                GSYIConText(
                  GSYICons.ISSUE_ITEM_COMMENT,
                  context.l10n.discussion_comments_count(commentCount),
                  GSYConstant.smallSubLightText.copyWith(color: Colors.white),
                  Colors.white70,
                  16,
                  padding: 2.0,
                ),
                const Spacer(),
                Text(
                  '#${widget.number}',
                  style: GSYConstant.smallSubLightText.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (url != null && url.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      NavigatorUtils.goGSYWebView(context, url, title);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.open_in_new,
                          size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 白色 chip（含 icon 或 emoji + 可选文字）
  Widget _headerChip({
    required IconData? icon,
    required String? emoji,
    required String? label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            if (label != null) const SizedBox(width: 4),
          ],
          if (emoji != null && emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 12)),
            if (label != null) const SizedBox(width: 4),
          ],
          if (label != null)
            Text(
              label,
              style: TextStyle(
                fontSize: GSYConstant.smallTextSize,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// 正文卡：走既有 markdown pipeline（inline HTML → markdown → 渲染）。
  ///
  /// 若 [bodyHTML] 尾部有 GitHub 自动生成的 "linked to a release" footer
  /// （`<hr><em>This discussion was created from the release <a href=".../releases/tag/{tag}">...</a>.</em>`），
  /// 走 [extractReleaseFooter] 把这段剥离，剩余 body 交给 markdown，footer
  /// 单独渲染成独立卡片（见 [_buildReleaseFooterCard]），语义比原地渲染成
  /// "分割线 + 斜体链接" 更强，也便于用户一眼看到关联的 release。
  Widget _buildBodyCard(BuildContext context, {String? bodyHTML}) {
    final rawHasBody = bodyHTML != null && bodyHTML.isNotEmpty;
    final extracted = rawHasBody
        ? extractReleaseFooter(bodyHTML)
        : (strippedBody: '', info: null);
    final String strippedBody = extracted.strippedBody;
    final ReleaseFooterInfo? footerInfo = extracted.info;
    final bool hasBody = strippedBody.isNotEmpty;
    final markdownData =
        hasBody ? transformInlineHtmlToMarkdown(strippedBody) : '';
    final String? subjectId = _discussion?['id'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GSYCardItem(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasBody)
                  GSYMarkdownWidget(
                    markdownData: markdownData,
                    baseUrl: '',
                    shrinkWrap: true,
                    scroll: false,
                  )
                else
                  Text(
                    context.l10n.discussion_empty_body,
                    style: GSYConstant.smallSubText
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                if (subjectId != null && subjectId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReactionsBar(context, subjectId, _bodyReactions,
                      isBody: true),
                ],
              ],
            ),
          ),
        ),
        if (footerInfo != null) _buildReleaseFooterCard(context, footerInfo),
      ],
    );
  }

  /// "linked to a release" 独立卡片：tag chip + 提示文案 + release 标题，
  /// 整卡点击走 [NavigatorUtils.goGSYWebView] 打开 release 网页（复用 header
  /// "查看 GitHub" 一致的入口，不引入新导航栈）。
  Widget _buildReleaseFooterCard(
      BuildContext context, ReleaseFooterInfo info) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return GSYCardItem(
      color: theme.cardColor,
      child: InkWell(
        onTap: () => NavigatorUtils.goGSYWebView(
            context, info.releaseUrl, info.title),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 20, color: theme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.discussion_release_footer_title,
                      style: GSYConstant.smallSubLightText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.title,
                      style: GSYConstant.middleTextBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        info.tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }

  /// 评论区：空态 / 非空 / loadMore 三段。
  ///
  /// - 用 `_commentsPage.nodes` 的当前长度和服务端 `totalCount` 分别渲染：
  ///   nodes 空 → 只显示 "暂无评论"（不显示 loadMore 按钮，避免 hasNextPage 状态诡异）
  ///   nodes 非空 → 逐个 [_buildCommentCard]，最后走 [_buildLoadMoreFooter]
  /// - 每条评论用独立 [GSYCardItem]，视觉与 Discussion body 卡对齐但缩进 8px 左右
  ///   以便在滚动时视觉上能"归组"到主体讨论内
  Widget _buildCommentsSection(BuildContext context) {
    final l = context.l10n;
    if (_commentsPage.nodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Text(
          l.discussion_comments_empty,
          style: GSYConstant.smallSubLightText,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in _commentsPage.nodes) _buildCommentCard(context, c),
        _buildLoadMoreFooter(context),
      ],
    );
  }

  /// 一级 comment 卡片：author + createdAt + isAnswer 徽标 + bodyHTML(markdown) + replies
  Widget _buildCommentCard(BuildContext context, Map<String, dynamic> comment) {
    final l = context.l10n;
    final Map<String, dynamic>? author =
        comment['author'] as Map<String, dynamic>?;
    final String? authorLogin = author?['login'] as String?;
    final String? authorAvatar = author?['avatarUrl'] as String?;
    final bool authorDeleted = author == null;
    final bool authorIsBot = _isBotAuthor(author);
    final String safeAuthor = authorLogin ?? l.discussion_author_ghost;
    final String? bodyHTML = comment['bodyHTML'] as String?;
    final bool hasBody = bodyHTML != null && bodyHTML.isNotEmpty;
    final String markdownData =
        hasBody ? transformInlineHtmlToMarkdown(bodyHTML) : '';
    final bool isAnswer = comment['isAnswer'] == true;
    final int upvote = (comment['upvoteCount'] as int?) ?? 0;
    final String? createdAtRaw = comment['createdAt'] as String?;
    final String createdAtText = _formatCreatedAt(createdAtRaw);

    // replies 嵌套：本轮只显示服务端已回带的前 10 条（不做 replies 分页）
    final Map<String, dynamic>? repliesRaw =
        comment['replies'] as Map<String, dynamic>?;
    final List repliesList =
        (repliesRaw?['nodes'] as List?) ?? const <dynamic>[];
    final int repliesTotal = (repliesRaw?['totalCount'] as int?) ?? 0;

    return GSYCardItem(
      color: isAnswer
          ? Colors.green.withValues(alpha: 0.06)
          : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GSYUserIconWidget(
                  width: 28,
                  height: 28,
                  minTapTargetSize: null,
                  image: authorAvatar,
                  onPressed: (authorLogin == null || authorLogin.isEmpty)
                      ? null
                      : () => NavigatorUtils.goPerson(context, authorLogin),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    safeAuthor,
                    style: GSYConstant.smallTextBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (authorIsBot) ...[
                  const SizedBox(width: 6),
                  _buildBotBadge(context),
                ],
                if (isAnswer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 12, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          l.discussion_comment_answer_badge,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                if (createdAtText.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(createdAtText, style: GSYConstant.smallSubLightText),
                ],
              ],
            ),
            const SizedBox(height: 6),
            if (hasBody)
              GSYMarkdownWidget(
                markdownData: markdownData,
                baseUrl: '',
                shrinkWrap: true,
                scroll: false,
              )
            else
              Text(
                authorDeleted
                    ? l.discussion_comment_deleted_body
                    : l.discussion_empty_body,
                style: GSYConstant.smallSubText
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            if (upvote > 0) ...[
              const SizedBox(height: 6),
              GSYIConText(
                Icons.arrow_upward,
                '$upvote',
                GSYConstant.smallSubLightText,
                GSYColors.subLightTextColor,
                14,
                padding: 2.0,
              ),
            ],
            if (comment['id'] is String && (comment['id'] as String).isNotEmpty)
              ...[
              const SizedBox(height: 6),
              _buildReactionsBar(
                context,
                comment['id'] as String,
                _commentReactions[comment['id'] as String] ??
                    const <ReactionSummary>[],
                isBody: false,
              ),
            ],
            if (repliesList.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Text(
                l.discussion_comment_replies_count(repliesTotal),
                style: GSYConstant.smallSubLightText,
              ),
              const SizedBox(height: 4),
              for (final r in repliesList)
                if (r is Map<String, dynamic>) _buildReplyRow(context, r),
            ],
          ],
        ),
      ),
    );
  }

  /// 一条 reply（嵌套在 comment 卡内部，左侧留缩进）
  Widget _buildReplyRow(BuildContext context, Map<String, dynamic> reply) {
    final l = context.l10n;
    final Map<String, dynamic>? author =
        reply['author'] as Map<String, dynamic>?;
    final String? authorLogin = author?['login'] as String?;
    final String? authorAvatar = author?['avatarUrl'] as String?;
    final bool authorDeleted = author == null;
    final bool authorIsBot = _isBotAuthor(author);
    final String safeAuthor = authorLogin ?? l.discussion_author_ghost;
    final String? bodyHTML = reply['bodyHTML'] as String?;
    final bool hasBody = bodyHTML != null && bodyHTML.isNotEmpty;
    final String markdownData =
        hasBody ? transformInlineHtmlToMarkdown(bodyHTML) : '';
    final String? createdAtRaw = reply['createdAt'] as String?;
    final String createdAtText = _formatCreatedAt(createdAtRaw);

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GSYUserIconWidget(
                width: 20,
                height: 20,
                minTapTargetSize: null,
                image: authorAvatar,
                onPressed: (authorLogin == null || authorLogin.isEmpty)
                    ? null
                    : () => NavigatorUtils.goPerson(context, authorLogin),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  safeAuthor,
                  style: GSYConstant.smallTextBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (authorIsBot) ...[
                const SizedBox(width: 4),
                _buildBotBadge(context),
              ],
              if (createdAtText.isNotEmpty)
                Text(createdAtText, style: GSYConstant.smallSubLightText),
            ],
          ),
          const SizedBox(height: 4),
          if (hasBody)
            GSYMarkdownWidget(
              markdownData: markdownData,
              baseUrl: '',
              shrinkWrap: true,
              scroll: false,
            )
          else
            Text(
              authorDeleted
                  ? l.discussion_comment_deleted_body
                  : l.discussion_empty_body,
              style: GSYConstant.smallSubText
                  .copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  /// 尾部 loadMore 区：4 态
  /// - hasNextPage=false 且 nodes 非空 → "没有更多评论了"
  /// - _loadingMore=true → 转圈 + "加载中"
  /// - _loadMoreError != null → 红字 + "加载失败，点击重试"
  /// - 其余 → "加载更多评论" 按钮
  Widget _buildLoadMoreFooter(BuildContext context) {
    final l = context.l10n;
    Widget child;
    if (_loadingMore) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l.discussion_comments_loading_more,
              style: GSYConstant.smallSubLightText),
        ],
      );
    } else if (_loadMoreError != null) {
      child = InkWell(
        onTap: _loadMore,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            l.discussion_comments_load_more_failed,
            style: GSYConstant.smallText.copyWith(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (!_commentsPage.hasNextPage) {
      child = Text(
        l.discussion_comments_no_more,
        style: GSYConstant.smallSubLightText,
        textAlign: TextAlign.center,
      );
    } else {
      child = OutlinedButton(
        onPressed: _loadMore,
        child: Text(l.discussion_comments_load_more),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(child: child),
    );
  }

  /// createdAt (ISO8601) → 相对时间字符串；解析失败返回空串
  static String _formatCreatedAt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return CommonUtils.getNewsTimeStr(dt.toLocal());
  }

  /// 判定 author 是否是 GitHub Bot（`__typename == 'Bot'`）。
  ///
  /// - 兼容大小写与去除首尾空格；GitHub GraphQL 目前一定返回 `Bot` / `User` /
  ///   `Organization` / `Mannequin`，但保守处理不给自己下套
  /// - author 为 null（已注销）直接返回 false，让 [_buildCommentCard] 走 deleted 分支
  static bool _isBotAuthor(Map<String, dynamic>? author) {
    if (author == null) return false;
    final t = author['__typename'];
    if (t is! String) return false;
    return t.trim().toLowerCase() == 'bot';
  }

  /// Bot 徽标 chip（小号，用户名旁挂）：橙色描边 + 橙色文字，与 answer 徽标
  /// 视觉区隔开（answer 是绿色）。i18n 走 `discussion_comment_bot_badge`。
  Widget _buildBotBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        context.l10n.discussion_comment_bot_badge,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 从服务端返回的 comment nodes 中抽出 `id → reactionGroups` 映射。
  ///
  /// 单独抽成方法：首屏 [_load] 与分页 [_loadMore] 均调用，避免两处各写一遍
  /// forEach。id 为空的 node 跳过（理论上 GraphQL 一定返回 id，但守一手）。
  Map<String, List<ReactionSummary>> _extractCommentReactions(
      List<Map<String, dynamic>> nodes) {
    final Map<String, List<ReactionSummary>> map =
        <String, List<ReactionSummary>>{};
    for (final c in nodes) {
      final id = c['id'];
      if (id is! String || id.isEmpty) continue;
      map[id] = pickReactionGroups(c['reactionGroups']);
    }
    return map;
  }

  /// 读取指定 subject 当前的 reactions 快照（body 优先）。
  ///
  /// 用于 [_toggleReaction] 里既做 body 也做 comment 时的分支写；也用于
  /// 长按弹窗展示当前选中态。
  List<ReactionSummary> _reactionsForSubject(String subjectId,
      {required bool isBody}) {
    if (isBody) return _bodyReactions;
    return _commentReactions[subjectId] ?? const <ReactionSummary>[];
  }

  /// 写回指定 subject 的 reactions（乐观更新 / 服务端 payload 覆盖时共用）。
  void _writeReactionsForSubject(
      String subjectId, List<ReactionSummary> next,
      {required bool isBody}) {
    if (isBody) {
      _bodyReactions = next;
    } else {
      _commentReactions[subjectId] = next;
    }
  }

  /// 处理一次 reaction 点击：
  ///
  /// 1. 若同一 subjectId 已有 inflight 请求，直接忽略（防连点）。
  /// 2. 依据 [add] 用 [applyLocalReactionToggle] 计算乐观快照，setState 先渲染。
  /// 3. 走 mutation；成功用返回的 `reactionGroups` 覆盖本地（吸收服务端合并 /
  ///    并发写入的差异），失败则回滚到调用前快照并给出 SnackBar 提示。
  /// 4. 401 / 403 之类"未登录 / 无权限"错误统一走 [_showSnack]。
  Future<void> _toggleReaction(
    String subjectId,
    String content, {
    required bool add,
    required bool isBody,
  }) async {
    if (_reactionInflight.contains(subjectId)) return;
    final l = context.l10n;
    final List<ReactionSummary> before =
        _reactionsForSubject(subjectId, isBody: isBody);
    final List<ReactionSummary> optimistic =
        applyLocalReactionToggle(before, content, add: add);
    if (identical(before, optimistic)) return;

    setState(() {
      _reactionInflight.add(subjectId);
      _writeReactionsForSubject(subjectId, optimistic, isBody: isBody);
    });

    try {
      final QueryResult? res = add
          ? await gql.addReactionToSubject(subjectId, content)
          : await gql.removeReactionFromSubject(subjectId, content);
      if (!mounted) return;
      if (res == null || res.hasException) {
        setState(() {
          _writeReactionsForSubject(subjectId, before, isBody: isBody);
          _reactionInflight.remove(subjectId);
        });
        _showSnack(l.discussion_reaction_failed(
            res?.exception?.toString() ?? 'null result'));
        return;
      }
      final Map<String, dynamic>? mutationRoot = res.data?[
          add ? 'addReaction' : 'removeReaction'] as Map<String, dynamic>?;
      final Map<String, dynamic>? subject =
          mutationRoot?['subject'] as Map<String, dynamic>?;
      final serverGroups = pickReactionGroups(subject?['reactionGroups']);
      setState(() {
        _writeReactionsForSubject(
            subjectId,
            serverGroups.isEmpty && optimistic.isNotEmpty
                ? optimistic
                : serverGroups,
            isBody: isBody);
        _reactionInflight.remove(subjectId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _writeReactionsForSubject(subjectId, before, isBody: isBody);
        _reactionInflight.remove(subjectId);
      });
      _showSnack(l.discussion_reaction_failed(e.toString()));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  /// GraphQL `ReactionContent` → 对应 l10n a11y label（tooltip / semantic）
  String _reactionA11yLabel(BuildContext context, String content) {
    final l = context.l10n;
    switch (content) {
      case 'THUMBS_UP':
        return l.reaction_thumbs_up;
      case 'THUMBS_DOWN':
        return l.reaction_thumbs_down;
      case 'LAUGH':
        return l.reaction_laugh;
      case 'HOORAY':
        return l.reaction_hooray;
      case 'CONFUSED':
        return l.reaction_confused;
      case 'HEART':
        return l.reaction_heart;
      case 'ROCKET':
        return l.reaction_rocket;
      case 'EYES':
        return l.reaction_eyes;
    }
    return content;
  }

  /// 底部 reactions bar：
  ///
  /// - 只渲染 `count>0` 的分组；数量为 0 的分组一律折进"添加反应" 弹窗
  /// - `viewerHasReacted=true` 的 chip 用 primaryColor 描边 + 淡背景高亮
  /// - 尾部固定一个 "+" 按钮，点击 / 长按 bar 都触发 [_openReactionPicker]
  /// - 若整条 bar 无任何有 count 的分组，退化为一个 hint chip："添加反应"
  Widget _buildReactionsBar(
    BuildContext context,
    String subjectId,
    List<ReactionSummary> groups, {
    required bool isBody,
  }) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final List<ReactionSummary> visible =
        groups.where((r) => r.count > 0).toList(growable: false);
    final Widget addBtn = _buildAddReactionButton(context, subjectId,
        isBody: isBody, groups: groups);

    if (visible.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => _openReactionPicker(subjectId, groups, isBody: isBody),
          onLongPress: () =>
              _openReactionPicker(subjectId, groups, isBody: isBody),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_reaction_outlined,
                    size: 16, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(l.discussion_reaction_add,
                    style: GSYConstant.smallSubLightText),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () =>
          _openReactionPicker(subjectId, groups, isBody: isBody),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final r in visible)
            _buildReactionChip(context, subjectId, r, isBody: isBody),
          addBtn,
        ],
      ),
    );
  }

  Widget _buildAddReactionButton(BuildContext context, String subjectId,
      {required bool isBody, required List<ReactionSummary> groups}) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Tooltip(
      message: l.discussion_reaction_add,
      child: InkWell(
        onTap: () => _openReactionPicker(subjectId, groups, isBody: isBody),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.6), width: 0.5),
          ),
          child: Icon(Icons.add_reaction_outlined,
              size: 16, color: theme.hintColor),
        ),
      ),
    );
  }

  Widget _buildReactionChip(
    BuildContext context,
    String subjectId,
    ReactionSummary r, {
    required bool isBody,
  }) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final bool selected = r.viewerHasReacted;
    final Color borderColor = selected
        ? theme.primaryColor
        : theme.dividerColor.withValues(alpha: 0.6);
    final Color background = selected
        ? theme.primaryColor.withValues(alpha: 0.08)
        : Colors.transparent;
    return Semantics(
      button: true,
      selected: selected,
      label: l.discussion_reaction_a11y(_reactionA11yLabel(context, r.content),
          r.count),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleReaction(subjectId, r.content,
            add: !selected, isBody: isBody),
        onLongPress: () => _openReactionPicker(
            subjectId, _reactionsForSubject(subjectId, isBody: isBody),
            isBody: isBody),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(r.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('${r.count}',
                  style: GSYConstant.smallSubLightText.copyWith(
                    color: selected
                        ? theme.primaryColor
                        : theme.textTheme.bodySmall?.color,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// 长按 / 点 "+" 弹出：底部 sheet 里展示 8 类 chip，用户点选一次即 toggle 并关闭
  void _openReactionPicker(
    String subjectId,
    List<ReactionSummary> current, {
    required bool isBody,
  }) {
    final Map<String, ReactionSummary> byContent = <String, ReactionSummary>{
      for (final r in current) r.content: r,
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final l = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.discussion_reaction_add,
                    style: GSYConstant.middleTextBold),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final c in kReactionContents)
                      _buildPickerCell(
                        ctx,
                        content: c,
                        emoji: kReactionEmoji[c]!,
                        selected: byContent[c]?.viewerHasReacted ?? false,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          final bool selected =
                              byContent[c]?.viewerHasReacted ?? false;
                          _toggleReaction(subjectId, c,
                              add: !selected, isBody: isBody);
                        },
                        theme: theme,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerCell(
    BuildContext context, {
    required String content,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final Color borderColor = selected
        ? theme.primaryColor
        : theme.dividerColor.withValues(alpha: 0.6);
    return Semantics(
      button: true,
      selected: selected,
      label: _reactionA11yLabel(context, content),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 0.8),
            color: selected
                ? theme.primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GSYTitleBar(
          '${widget.reposName} · #${widget.number}',
          iconData: GSYICons.HOME,
          needRightLocalIcon: widget.needHomeIcon,
        ),
      ),
      body: _buildBody(),
    );
  }
}
