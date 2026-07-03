import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/label_chip.dart';

/// Issue timeline 事件行
///
/// 参考截图 2/3：
/// - `Hixie changed the title X to Y`
/// - `Hixie removed the framework label` / `added the engine label`
/// - `victorsanni referenced this` + 关联卡片
/// - `assigned` / `milestoned` / `closed` / `reopened` / `locked` / `unlocked`
///
/// 只承担事件行渲染，评论仍走 IssueItem。
class IssueTimelineItem extends StatelessWidget {
  final IssueTimelineEvent event;

  const IssueTimelineItem(this.event, {super.key});

  IconData get _icon {
    switch (event.event) {
      case 'labeled':
      case 'unlabeled':
        return Icons.local_offer_outlined;
      case 'assigned':
      case 'unassigned':
        return Icons.person_outline;
      case 'milestoned':
      case 'demilestoned':
        return Icons.flag_outlined;
      case 'renamed':
        return Icons.edit_outlined;
      case 'closed':
        return Icons.check_circle_outline;
      case 'reopened':
        return Icons.refresh;
      case 'locked':
        return Icons.lock_outline;
      case 'unlocked':
        return Icons.lock_open_outlined;
      case 'referenced':
      case 'cross-referenced':
        return Icons.link;
      case 'mentioned':
      case 'subscribed':
      case 'unsubscribed':
        return Icons.alternate_email;
      case 'pinned':
        return Icons.push_pin_outlined;
      case 'unpinned':
        return Icons.push_pin;
      case 'merged':
        return Icons.merge_type;
      default:
        return Icons.info_outline;
    }
  }

  Color get _iconColor {
    switch (event.event) {
      case 'closed':
        return Colors.red.shade400;
      case 'reopened':
        return Colors.green.shade600;
      case 'merged':
        return Colors.purple.shade400;
      case 'locked':
        return Colors.orange.shade400;
      default:
        return GSYColors.subTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actorName = event.actor?.login ?? '---';
    final time = event.createdAt != null
        ? CommonUtils.getNewsTimeStr(event.createdAt!)
        : '';

    return InkWell(
      onTap: () {
        if (event.sourceUrl != null && event.sourceUrl!.isNotEmpty) {
          CommonUtils.launchOutURL(event.sourceUrl, context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 16, color: _iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: DefaultTextStyle(
                style: GSYConstant.smallSubText,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: _buildContent(context, actorName),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: GSYConstant.smallSubLightText),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, String actor) {
    // 采用 l10n 生成的整句翻译 + 附加 chip/reference 卡片的组合方式：
    // - 主体是一段包含 {actor} 的完整句子（便于中英日韩的语法差异）
    // - labeled/unlabeled 追加彩标 chip
    // - referenced/cross-referenced 追加引用卡片
    // - renamed 已由 l10n 完整承载 from/to 语义
    final l = context.l10n;
    final actorName = actor;
    final label = event.label?.name ?? '';
    final assigneeName = event.assignee?.login ?? '';
    final milestone = event.milestoneTitle ?? '';
    final from = event.renameFrom ?? '';
    final to = event.renameTo ?? '';

    String sentence;
    final extras = <Widget>[];
    switch (event.event) {
      case 'labeled':
        sentence = l.issue_timeline_labeled(actorName, label);
        if (event.label != null) {
          extras.add(LabelChip(label: event.label!));
        }
        break;
      case 'unlabeled':
        sentence = l.issue_timeline_unlabeled(actorName, label);
        if (event.label != null) {
          extras.add(LabelChip(label: event.label!));
        }
        break;
      case 'assigned':
        sentence = l.issue_timeline_assigned(actorName, assigneeName);
        break;
      case 'unassigned':
        sentence = l.issue_timeline_unassigned(actorName, assigneeName);
        break;
      case 'milestoned':
        sentence = l.issue_timeline_milestoned(actorName, milestone);
        break;
      case 'demilestoned':
        sentence = l.issue_timeline_demilestoned(actorName, milestone);
        break;
      case 'renamed':
        sentence = l.issue_timeline_renamed(actorName, from, to);
        break;
      case 'closed':
        sentence = l.issue_timeline_closed(actorName);
        break;
      case 'reopened':
        sentence = l.issue_timeline_reopened(actorName);
        break;
      case 'locked':
        sentence = l.issue_timeline_locked(actorName);
        break;
      case 'unlocked':
        sentence = l.issue_timeline_unlocked(actorName);
        break;
      case 'pinned':
        sentence = l.issue_timeline_pinned(actorName);
        break;
      case 'unpinned':
        sentence = l.issue_timeline_unpinned(actorName);
        break;
      case 'merged':
        sentence = l.issue_timeline_merged(actorName);
        break;
      case 'referenced':
        sentence = l.issue_timeline_referenced(actorName);
        if ((event.sourceTitle ?? '').isNotEmpty) {
          extras.add(_referenceCard(context));
        }
        break;
      case 'cross-referenced':
        sentence = l.issue_timeline_cross_referenced(actorName);
        if ((event.sourceTitle ?? '').isNotEmpty) {
          extras.add(_referenceCard(context));
        }
        break;
      case 'mentioned':
        sentence = l.issue_timeline_mentioned(actorName);
        break;
      case 'subscribed':
        sentence = l.issue_timeline_subscribed(actorName);
        break;
      case 'unsubscribed':
        sentence = l.issue_timeline_unsubscribed(actorName);
        break;
      default:
        sentence = l.issue_timeline_generic(actorName, event.event ?? '');
    }

    final isBot = event.actor?.type == 'Bot' || actorName.endsWith('[bot]');
    return <Widget>[
      // 整句 + 可点击的 actor 名字（长按 actor 无需，简化）
      InkWell(
        onTap: event.actor?.login == null
            ? null
            : () => NavigatorUtils.goPerson(context, event.actor!.login),
        child: Text(sentence, style: GSYConstant.smallSubText),
      ),
      if (isBot)
        Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: GSYColors.subLightTextColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(l.issue_badge_bot,
              style: const TextStyle(fontSize: 10)),
        ),
      ...extras,
    ];
  }

  Widget _referenceCard(BuildContext context) {
    final state = event.sourceState ?? '';
    final color = state == 'open' ? Colors.green : Colors.red;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: GSYColors.cardWhite,
        border: Border.all(
            color: GSYColors.subLightTextColor.withValues(alpha: 0.5), width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.block_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event.sourceTitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GSYConstant.smallSubText,
            ),
          ),
        ],
      ),
    );
  }
}
