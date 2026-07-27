import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart' as gql;
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/discussion/discussion_comments_paging.dart';
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

  const DiscussionDetailPage(
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
                    label: context.l10n.discussion_answered_badge,
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

  /// 正文卡：走既有 markdown pipeline（inline HTML → markdown → 渲染）
  Widget _buildBodyCard(BuildContext context, {String? bodyHTML}) {
    final hasBody = bodyHTML != null && bodyHTML.isNotEmpty;
    final markdownData =
        hasBody ? transformInlineHtmlToMarkdown(bodyHTML) : '';
    return GSYCardItem(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: hasBody
            ? GSYMarkdownWidget(
                markdownData: markdownData,
                baseUrl: '',
                shrinkWrap: true,
                scroll: false,
              )
            : Text(
                context.l10n.discussion_empty_body,
                style: GSYConstant.smallSubText
                    .copyWith(fontStyle: FontStyle.italic),
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
                l.discussion_empty_body,
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
              l.discussion_empty_body,
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
