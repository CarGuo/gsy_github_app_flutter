import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/label_chip.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';

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
  /// 未知事件遥测：进程内已登记的未知事件名。
  ///
  /// 背景：GitHub timeline event 类型是**动态扩展**的（copilot_work_started
  /// 之类的事件官方 REST 文档里根本没提，是从真实响应里发现的），我们不可能
  /// 靠穷举 case 覆盖所有历史/未来事件。传统做法是靠人肉扫 UI 发现
  /// `--- xxx` 丑显示再补一次，链路又慢又漏。
  ///
  /// 改成主动发现：命中 [_buildContent] 的 default 分支时，把事件名 + 上下文
  /// 打到 [talker]，开发者 debug 时用 `logcat` 或 talker history 一抓就能看到
  /// 所有未识别事件，用来指导下一轮补 case。
  ///
  /// 假设与边界：
  /// - 只在 [kDebugMode] 打，release 构建下集合**永不写入**（0 运行时开销）
  /// - 用 static Set 去重，同一事件名一个进程只登记一次，避免 build 刷屏
  /// - 只本地日志，不上报网络；talker 若未来被接入线上诊断/上报后台，
  ///   需要重审这里的 `actor` / `sourceUrl` 是否要脱敏
  /// - **仅在 UI isolate 使用**；跨 isolate 复用需自行加锁或换线程安全结构
  @visibleForTesting
  static final Set<String> loggedUnknownEvents = <String>{};

  /// 仅供测试重置去重表用，业务代码勿调。
  @visibleForTesting
  static void resetUnknownEventLogForTest() {
    loggedUnknownEvents.clear();
  }

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
      case 'reviewed':
        switch (event.reviewState) {
          case 'approved':
            return Icons.check_circle_outline;
          case 'changes_requested':
            return Icons.report_gmailerrorred_outlined;
          case 'dismissed':
            return Icons.remove_circle_outline;
          default:
            return Icons.rate_review_outlined;
        }
      case 'review_requested':
        return Icons.person_add_alt_outlined;
      case 'review_request_removed':
        return Icons.person_remove_alt_1_outlined;
      case 'ready_for_review':
        return Icons.play_circle_outline;
      case 'convert_to_draft':
        return Icons.edit_note_outlined;
      case 'head_ref_force_pushed':
      case 'base_ref_force_pushed':
        return Icons.publish_outlined;
      case 'head_ref_deleted':
        return Icons.delete_outline;
      case 'head_ref_restored':
        return Icons.restore_outlined;
      case 'base_ref_changed':
        return Icons.swap_horiz_outlined;
      case 'auto_merge_enabled':
      case 'auto_merge_disabled':
        return Icons.merge_type;
      case 'committed':
        return Icons.commit;
      case 'copilot_work_started':
      case 'copilot_work_finished':
        return Icons.smart_toy_outlined;
      case 'added_to_merge_queue':
        return Icons.playlist_add_check_outlined;
      case 'removed_from_merge_queue':
        return Icons.playlist_remove_outlined;
      case 'added_to_project_v2':
      case 'project_v2_item_status_changed':
        return Icons.dashboard_outlined;
      case 'issue_type_added':
        return Icons.category_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get _iconColor {
    switch (event.event) {
      case 'closed':
        return Colors.red.shade400;
      case 'reopened':
      case 'ready_for_review':
        return Colors.green.shade600;
      case 'merged':
        return Colors.purple.shade400;
      case 'locked':
        return Colors.orange.shade400;
      case 'reviewed':
        switch (event.reviewState) {
          case 'approved':
            return Colors.green.shade600;
          case 'changes_requested':
            return Colors.red.shade400;
          case 'dismissed':
            return Colors.orange.shade400;
          default:
            return GSYColors.subTextColor;
        }
      case 'convert_to_draft':
        return GSYColors.subLightTextColor;
      default:
        return GSYColors.subTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // committed 事件 GitHub 顶层没有 actor，作者信息在 commit.author.name
    final actorName =
        event.actor?.login ?? event.commitAuthorName ?? '---';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            if (_shouldShowReviewBody())
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 6),
                child: _reviewBodyCard(context),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowReviewBody() {
    if (event.event != 'reviewed') return false;
    final b = event.body;
    return b != null && b.trim().isNotEmpty;
  }

  Widget _reviewBodyCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
            color: GSYColors.subLightTextColor.withValues(alpha: 0.5),
            width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: GSYMarkdownWidget(
          markdownData: event.body!.trim(),
          baseUrl: "",
          shrinkWrap: true,
          scroll: false,
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
      case 'reviewed':
        switch (event.reviewState) {
          case 'approved':
            sentence = l.pr_timeline_reviewed_approved(actorName);
            break;
          case 'changes_requested':
            sentence = l.pr_timeline_reviewed_changes_requested(actorName);
            break;
          case 'dismissed':
            sentence = l.pr_timeline_reviewed_dismissed(actorName);
            break;
          default:
            sentence = l.pr_timeline_reviewed_commented(actorName);
        }
        break;
      case 'review_requested':
        final reviewer = event.reviewerName;
        sentence = (reviewer == null || reviewer.isEmpty)
            ? l.issue_timeline_generic(actorName, event.event ?? '')
            : l.pr_timeline_review_requested(actorName, reviewer);
        break;
      case 'review_request_removed':
        final reviewer = event.reviewerName;
        sentence = (reviewer == null || reviewer.isEmpty)
            ? l.issue_timeline_generic(actorName, event.event ?? '')
            : l.pr_timeline_review_request_removed(actorName, reviewer);
        break;
      case 'ready_for_review':
        sentence = l.pr_timeline_ready_for_review(actorName);
        break;
      case 'convert_to_draft':
        sentence = l.pr_timeline_convert_to_draft(actorName);
        break;
      case 'head_ref_force_pushed':
        sentence = l.pr_timeline_head_ref_force_pushed(actorName);
        break;
      case 'base_ref_force_pushed':
        sentence = l.pr_timeline_base_ref_force_pushed(actorName);
        break;
      case 'head_ref_deleted':
        sentence = l.pr_timeline_head_ref_deleted(actorName);
        break;
      case 'head_ref_restored':
        sentence = l.pr_timeline_head_ref_restored(actorName);
        break;
      case 'base_ref_changed':
        sentence = l.pr_timeline_base_ref_changed(actorName);
        break;
      case 'auto_merge_enabled':
        sentence = l.pr_timeline_auto_merge_enabled(actorName);
        break;
      case 'auto_merge_disabled':
        sentence = l.pr_timeline_auto_merge_disabled(actorName);
        break;
      case 'committed':
        // committed 事件走 sha + message 首行，缺 sha 兜到 generic
        final shortSha = event.commitShortSha;
        if (shortSha == null) {
          sentence = l.issue_timeline_generic(actorName, event.event ?? '');
        } else {
          final msg = event.commitMessage;
          sentence = (msg == null || msg.isEmpty)
              ? l.pr_timeline_committed_no_message(actorName, shortSha)
              : l.pr_timeline_committed(actorName, shortSha, msg);
        }
        break;
      case 'copilot_work_started':
        sentence = l.pr_timeline_copilot_work_started(actorName);
        break;
      case 'copilot_work_finished':
        sentence = l.pr_timeline_copilot_work_finished(actorName);
        break;
      case 'added_to_merge_queue':
        sentence = l.pr_timeline_added_to_merge_queue(actorName);
        break;
      case 'removed_from_merge_queue':
        sentence = l.pr_timeline_removed_from_merge_queue(actorName);
        break;
      case 'added_to_project_v2':
        sentence = l.issue_timeline_added_to_project(actorName);
        break;
      case 'project_v2_item_status_changed':
        sentence = l.issue_timeline_project_status_changed(actorName);
        break;
      case 'issue_type_added':
        sentence = l.issue_timeline_issue_type_added(actorName);
        break;
      default:
        _logUnknownEventOnce();
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

  /// 命中未知 timeline event 时的一次性日志。
  ///
  /// - 只在 [kDebugMode] 生效
  /// - 相同事件名整个进程只打一次，避免 build 多次刷屏
  /// - 空事件名不打（那不是"未知事件"，是数据本身缺失，另一类问题）
  void _logUnknownEventOnce() {
    if (!kDebugMode) return;
    final name = event.event;
    if (name == null || name.isEmpty) return;
    if (!loggedUnknownEvents.add(name)) return;
    talker.warning(
      '[IssueTimeline] Unknown event="$name" '
      'actor=${event.actor?.login ?? event.commitAuthorName ?? "-"} '
      'sourceUrl=${event.sourceUrl ?? "-"}. '
      'Consider adding a case in issue_timeline_item.dart and l10n arb.',
    );
  }
}
