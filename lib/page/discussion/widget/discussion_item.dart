import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// Discussions 列表 item 的视觉展示。
///
/// 与 [IssueItem](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/issue/widget/issue_item.dart)
/// 视觉同源：GSYCardItem + 头像 + 标题 + 底栏（upvote / comments / answered chip）。
/// 不复用 IssueItem 是因为字段集差异较大（category emoji / answered 徽标 / 无
/// state open/closed / 无 assignees），做同层新 widget 语义更干净。
class DiscussionItem extends StatelessWidget {
  final DiscussionItemViewModel viewModel;
  final GestureTapCallback? onPressed;

  const DiscussionItem({
    super.key,
    required this.viewModel,
    this.onPressed,
  });

  Widget _renderCategoryChip(BuildContext context) {
    // GraphQL 返回的 `category.emoji` 是 `:speech_balloon:` 形式的 shortcode，
    // 需要走 [resolveEmojiShortcode] 转 unicode；未命中 fallback 原文，
    // 不做二次样式区分（GSY 现有 status emoji 场景一致处理）。
    final rawEmoji = viewModel.categoryEmoji;
    final emoji =
        (rawEmoji == null || rawEmoji.isEmpty) ? null : resolveEmojiShortcode(rawEmoji);
    final name = viewModel.categoryName;
    if ((emoji == null || emoji.isEmpty) && (name == null || name.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(right: 6.0, top: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        // GitHub 风格弱色 chip：淡蓝底 + 主色文字，避免与卡片背景撞色
        color: GSYColors.primarySwatch.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null && emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          if (name != null && name.isNotEmpty)
            Text(
              name,
              style: GSYConstant.smallSubText.copyWith(
                color: GSYColors.primarySwatch,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderAnsweredChip(BuildContext context) {
    if (!viewModel.answered) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6.0, top: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            context.l10n.discussion_answered_badge,
            style: GSYConstant.smallSubText.copyWith(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderLockedChip(BuildContext context) {
    // locked 讨论加一个 muted lock chip，与 answered 语义并列
    if (!viewModel.locked) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6.0, top: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: GSYColors.subLightTextColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(Icons.lock_outline,
          size: 12, color: GSYColors.subTextColor),
    );
  }

  Widget _renderBottom(BuildContext context) {
    return Row(
      children: <Widget>[
        // 上投数
        GSYIConText(
          Icons.arrow_upward,
          '${viewModel.upvoteCount}',
          GSYConstant.smallSubText,
          GSYColors.subTextColor,
          15.0,
          padding: 2.0,
        ),
        const SizedBox(width: 12),
        // 评论数
        GSYIConText(
          GSYICons.ISSUE_ITEM_COMMENT,
          '${viewModel.commentCount}',
          GSYConstant.smallSubText,
          GSYColors.subTextColor,
          15.0,
          padding: 2.0,
        ),
        const Spacer(),
        // #number
        Text('#${viewModel.number}',
            style: GSYConstant.smallSubText
                .copyWith(color: GSYColors.subLightTextColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GSYCardItem(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 6.0, top: 8.0, right: 12.0, bottom: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 头像列：走 GSY 官方 GSYUserIconWidget，
              // tap 跳作者主页与 IssueItem 一致
              GSYUserIconWidget(
                width: 36.0,
                height: 36.0,
                image: viewModel.authorAvatar,
                onPressed: (viewModel.authorLogin == null ||
                        viewModel.authorLogin!.isEmpty)
                    ? null
                    : () {
                        NavigatorUtils.goPerson(context, viewModel.authorLogin);
                      },
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // 作者名（bold）
                    Text(
                      viewModel.authorLogin ??
                          context.l10n.discussion_author_ghost,
                      style: GSYConstant.smallTextBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 标题（黑色主色 middleTextBold，2 行截断）
                    Text(
                      viewModel.title,
                      style: GSYConstant.middleTextBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // category / answered / locked 三档 chip
                    Wrap(
                      children: [
                        _renderCategoryChip(context),
                        _renderAnsweredChip(context),
                        _renderLockedChip(context),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _renderBottom(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Discussions 列表 item 的数据模型。
///
/// 单独抽出的目的：
/// 1. 单元测试可以脱离 UI 直接对 [fromMap] 做字段解析验证（t7 里覆盖
///    answered / bot / [deleted] / null 各种边界）
/// 2. 页面层拿到的都是强类型字段，避免每处渲染都写 as / null-check
///
/// `fromMap` 语义：接受 GraphQL 返回的一条 `discussions.nodes[i]` 原始 map；
/// 完全解析不出关键字段（number / title 都缺）时返回 null，让上层 skip 该条。
class DiscussionItemViewModel {
  final int number;
  final String title;
  final String? authorLogin;
  final String? authorAvatar;
  final String? categoryName;
  final String? categoryEmoji;
  final int upvoteCount;
  final int commentCount;
  final bool answered;
  final String? url;
  final bool locked;

  const DiscussionItemViewModel({
    required this.number,
    required this.title,
    this.authorLogin,
    this.authorAvatar,
    this.categoryName,
    this.categoryEmoji,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.answered = false,
    this.url,
    this.locked = false,
  });

  static DiscussionItemViewModel? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final number = map['number'];
    if (number is! int) return null;
    final title = (map['title'] as String?) ?? '';
    // GitHub 允许作者删号 → author == null，UI 侧显示 ghost
    final Map<String, dynamic>? author =
        map['author'] as Map<String, dynamic>?;
    final Map<String, dynamic>? category =
        map['category'] as Map<String, dynamic>?;
    final Map<String, dynamic>? comments =
        map['comments'] as Map<String, dynamic>?;
    return DiscussionItemViewModel(
      number: number,
      title: title,
      authorLogin: author?['login'] as String?,
      authorAvatar: author?['avatarUrl'] as String?,
      categoryName: category?['name'] as String?,
      categoryEmoji: category?['emoji'] as String?,
      upvoteCount: (map['upvoteCount'] as int?) ?? 0,
      commentCount: (comments?['totalCount'] as int?) ?? 0,
      // answerChosenAt 有值即视为已被标记回答（与详情页 answered 徽标同标准）
      answered: map['answerChosenAt'] != null,
      url: map['url'] as String?,
      locked: (map['locked'] as bool?) ?? false,
    );
  }
}
