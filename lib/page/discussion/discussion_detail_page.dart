import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart' as gql;
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
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
      final QueryResult? res =
          await gql.getDiscussion(widget.owner, widget.reposName, widget.number);
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString();
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Text(
              context.l10n.discussion_skeleton_notice,
              style: GSYConstant.smallSubLightText,
              textAlign: TextAlign.center,
            ),
          ),
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
