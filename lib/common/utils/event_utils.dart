import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/model/push_event_commit.dart';
import 'package:gsy_github_app_flutter/model/repo_commit.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 事件逻辑
/// Created by guoshuyu
/// Date: 2018-07-16
///
/// 动态页 (dynamic / person / repos events tab) 的事件文案生成器。
/// 与 [issue_timeline_item.dart] 完全平行：一个处理 GitHub Events API
/// (动态页 feed)，一个处理 GitHub Timeline API (issue/pr 事件流)，二者
/// event 命名和 payload 形态**完全不同**，不要混用。
///
/// 事件识别原则：
/// - 已识别的 26 种事件走 [AppLocalizations] 生成多语言整句
/// - 未识别的事件走 default 分支返回空 actionStr（widget 侧会显示空 tile
///   而不是英文 raw 事件类型名），并在 debug 构建下将事件类型登记到
///   [loggedUnknownEventTypes]，用 [Talker] 打 warning 提醒开发者补 case
/// - `event.payload.action` 是 GitHub API 传回的英文枚举（如 `opened` /
///   `synchronize`），走 [_translateAction] 集中翻译；未命中的 action 值
///   登记到 [loggedUnknownActions]，UI 层原样透传英文而不是空白
/// - release 构建下遥测入口首行 kDebugMode 早退，零运行时开销
///
/// 已知偏差（未修，跟踪 issue TODO）：
/// - ForkEvent 用 `event.repo.name` 作为源仓库、并假设新 fork 的名字与源
///   相同（99% 场景成立）。极少数"改名 fork / fork 到 org 时改名"场景
///   显示的 forkee 名会略有偏差，需要在 [EventPayload] 里补 `forkee`
///   字段后再修，属于扩数据模型任务
/// - `_translateAction` 采取"通用词典 × 模板槽位"策略，中文可读性优先；
///   英语侧部分动词 + 名词组合语法不完美（如 `submitted pull request
///   review`）。修法是按事件类型定制模板，代价大，暂延后
class EventUtils {
  /// 已登记的未知事件类型集合。**debug-only**，release 下永远为空。
  /// 只用于测试断言与开发期主动发现新事件。
  @visibleForTesting
  static final Set<String> loggedUnknownEventTypes = <String>{};

  /// 已登记的未知 action 值集合。**debug-only**，与
  /// [loggedUnknownEventTypes] 拆开是为了：
  /// 1. 语义清晰：一个是"事件类型未识别"（可能整条卡片无法渲染），
  ///    一个是"事件已识别但 action 值是新的"（卡片能出，动词是英文）
  /// 2. 未来接不同 sink 时不用再解析前缀
  /// 3. 避免测试断言 length 时相互干扰
  @visibleForTesting
  static final Set<String> loggedUnknownActions = <String>{};

  /// 已登记的未知 notification reason 集合。**debug-only**。
  /// 与前两张表继续分开：Events / Timeline 的 action 和 Notifications 的
  /// reason 是 GitHub 上完全不同的两条 API 命名空间，混在一起会让"新事件"
  /// 遥测告警的可读性下降。
  @visibleForTesting
  static final Set<String> loggedUnknownNotifyReasons = <String>{};

  /// 测试专用：重置三张遥测表。
  @visibleForTesting
  static void resetUnknownEventLogForTest() {
    loggedUnknownEventTypes.clear();
    loggedUnknownActions.clear();
    loggedUnknownNotifyReasons.clear();
  }

  static void _logUnknownEventTypeOnce(String? type) {
    if (!kDebugMode) return;
    if (type == null || type.isEmpty) return;
    if (loggedUnknownEventTypes.contains(type)) return;
    loggedUnknownEventTypes.add(type);
    _talkerWarn(
      '[EventUtils] Unknown Events API type="$type". '
      'Consider adding a case in event_utils.dart and l10n arb.',
    );
  }

  static void _logUnknownActionOnce(String? action) {
    if (!kDebugMode) return;
    if (action == null || action.isEmpty) return;
    if (loggedUnknownActions.contains(action)) return;
    loggedUnknownActions.add(action);
    _talkerWarn(
      '[EventUtils] Unknown action value="$action". '
      'Consider adding a case in _translateAction and event_action_* arb.',
    );
  }

  static void _talkerWarn(String msg) {
    try {
      Talker().warning(msg);
    } catch (e, s) {
      // talker 未初始化（如纯 dart 单测环境）不影响业务，但 debug 下把
      // 异常本身打出来，避免真正的 talker bug 被静默吞掉
      // ignore: avoid_print
      print('[EventUtils] talker warn fallback: $msg | err=$e\n$s');
    }
  }

  static bool _isInvalidCompareBase(String? sha) {
    if (sha == null || sha.isEmpty) {
      return true;
    }
    return RegExp(r'^0+$').hasMatch(sha);
  }

  static String _shortSha(String? sha, [int length = 7]) {
    if (sha == null || sha.isEmpty) {
      return "";
    }
    if (sha.length <= length) {
      return sha;
    }
    return sha.substring(0, length);
  }

  /// 把 GitHub API 原始英文 action 值翻译为当前语言。
  ///
  /// 背景：`event.payload.action` 由 GitHub Events API 决定，永远是英文
  /// 枚举值（如 `opened` / `closed` / `synchronize`）。如果直接把它塞进
  /// `"在 {repo} {action} PR"` 模板，中文用户看到的仍是 "在 xx opened PR"，
  /// 违反规则 4。这里做集中翻译：
  /// - 命中已知词典 → 返回本地化文案
  /// - 未命中 → 记录到未知事件遥测集合（借用同一张表，用 `action:` 前缀
  ///   区分事件类型），并原样返回英文，保证 UI 不空白
  static String _translateAction(AppLocalizations l, String? rawAction) {
    if (rawAction == null || rawAction.isEmpty) {
      return "";
    }
    switch (rawAction) {
      case 'started':
        return l.event_action_started;
      case 'opened':
        return l.event_action_opened;
      case 'edited':
        return l.event_action_edited;
      case 'closed':
        return l.event_action_closed;
      case 'reopened':
        return l.event_action_reopened;
      case 'assigned':
        return l.event_action_assigned;
      case 'unassigned':
        return l.event_action_unassigned;
      case 'labeled':
        return l.event_action_labeled;
      case 'unlabeled':
        return l.event_action_unlabeled;
      case 'created':
        return l.event_action_created;
      case 'deleted':
        return l.event_action_deleted;
      case 'review_requested':
        return l.event_action_review_requested;
      case 'review_request_removed':
        return l.event_action_review_request_removed;
      case 'synchronize':
        return l.event_action_synchronize;
      case 'ready_for_review':
        return l.event_action_ready_for_review;
      case 'dismissed':
        return l.event_action_dismissed;
      case 'submitted':
        return l.event_action_submitted;
      case 'published':
        return l.event_action_published;
      case 'prereleased':
        return l.event_action_prereleased;
      case 'released':
        return l.event_action_released;
      case 'added':
        return l.event_action_added;
      case 'removed':
        return l.event_action_removed;
      case 'suspend':
        return l.event_action_suspend;
      case 'unsuspend':
        return l.event_action_unsuspend;
      case 'new_permissions_accepted':
        return l.event_action_new_permissions_accepted;
      case 'purchased':
        return l.event_action_purchased;
      case 'cancelled':
        return l.event_action_cancelled;
      case 'pending_change':
        return l.event_action_pending_change;
      case 'pending_change_cancelled':
        return l.event_action_pending_change_cancelled;
      case 'changed':
        return l.event_action_changed;
      case 'moved':
        return l.event_action_moved;
      case 'blocked':
        return l.event_action_blocked;
      case 'unblocked':
        return l.event_action_unblocked;
      case 'merged':
        return l.event_action_merged;
      case 'converted_to_draft':
        return l.event_action_converted_to_draft;
      case 'locked':
        return l.event_action_locked;
      case 'unlocked':
        return l.event_action_unlocked;
      case 'pinned':
        return l.event_action_pinned;
      case 'unpinned':
        return l.event_action_unpinned;
      case 'transferred':
        return l.event_action_transferred;
      case 'milestoned':
        return l.event_action_milestoned;
      case 'demilestoned':
        return l.event_action_demilestoned;
      case 'answered':
        return l.event_action_answered;
      case 'unanswered':
        return l.event_action_unanswered;
      case 'category_changed':
        return l.event_action_category_changed;
      case 'resolved':
        return l.event_action_resolved;
      case 'unresolved':
        return l.event_action_unresolved;
      default:
        _logUnknownActionOnce(rawAction);
        return rawAction;
    }
  }

  ///事件描述与动作
  ///
  /// [context] 用于取多语言。传入的 context 生命周期由调用方保证，
  /// 本方法只在同步阶段读取一次 l10n 后立即返回，不持有 context。
  static ({String? actionStr, String? des}) getActionAndDes(
    BuildContext context,
    Event event,
  ) {
    final AppLocalizations l = context.l10n;
    String? actionStr;
    String? des;
    switch (event.type) {
      case "CommitCommentEvent":
        actionStr = l.event_dynamic_commit_comment(event.repo!.name!);
        break;
      case "CreateEvent":
        if (event.payload!.refType == "repository") {
          actionStr = l.event_dynamic_create_repository(event.repo!.name!);
        } else {
          actionStr = l.event_dynamic_create_ref(
            event.payload!.refType!,
            event.payload!.ref!,
            event.repo!.name!,
          );
        }
        break;
      case "DeleteEvent":
        actionStr = l.event_dynamic_delete_ref(
          event.payload!.refType!,
          event.payload!.ref!,
          event.repo!.name!,
        );
        break;
      case "ForkEvent":
        // Fork event 的 repo/actor 字段在部分历史 payload 里可能缺失
        // （已 fork 到私仓/账号删除/GitHub API 变更），这里做 null-safe，
        // 避免整个 dynamic tile 崩掉。
        final String? oriRepo = event.repo?.name;
        final String? forker = event.actor?.login;
        if (oriRepo != null && forker != null) {
          actionStr = l.event_dynamic_fork_full(oriRepo, forker);
        } else if (oriRepo != null) {
          actionStr = l.event_dynamic_fork_repo(oriRepo);
        } else {
          actionStr = l.event_dynamic_fork_generic;
        }
        break;
      case "GollumEvent":
        actionStr = l.event_dynamic_gollum(event.actor!.login!);
        break;
      case "InstallationEvent":
        actionStr = l.event_dynamic_installation(_translateAction(l, event.payload?.action));
        break;
      case "InstallationRepositoriesEvent":
        actionStr = l.event_dynamic_installation_repos(_translateAction(l, event.payload?.action));
        break;
      case "IssueCommentEvent":
        actionStr = l.event_dynamic_issue_comment(
          _translateAction(l, event.payload?.action),
          event.payload!.issue!.number.toString(),
          event.repo!.name!,
        );
        des = event.payload!.comment!.body;
        break;
      case "IssuesEvent":
        actionStr = l.event_dynamic_issue(
          _translateAction(l, event.payload?.action),
          event.payload!.issue!.number.toString(),
          event.repo!.name!,
        );
        des = event.payload!.issue!.title;
        break;
      case "MarketplacePurchaseEvent":
        actionStr = l.event_dynamic_marketplace(_translateAction(l, event.payload?.action));
        break;
      case "MemberEvent":
        actionStr = l.event_dynamic_member(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "OrgBlockEvent":
        actionStr = l.event_dynamic_org_block(_translateAction(l, event.payload?.action));
        break;
      case "ProjectCardEvent":
        actionStr = l.event_dynamic_project_card(_translateAction(l, event.payload?.action));
        break;
      case "ProjectColumnEvent":
        actionStr = l.event_dynamic_project_column(_translateAction(l, event.payload?.action));
        break;
      case "ProjectEvent":
        actionStr = l.event_dynamic_project(_translateAction(l, event.payload?.action));
        break;
      case "PublicEvent":
        actionStr = l.event_dynamic_public(event.repo!.name!);
        break;
      case "PullRequestEvent":
        actionStr = l.event_dynamic_pull_request(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "PullRequestReviewEvent":
        actionStr = l.event_dynamic_pull_request_review(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "PullRequestReviewCommentEvent":
        actionStr = l.event_dynamic_pull_request_review_comment(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "PullRequestReviewThreadEvent":
        // GitHub 官方补录事件：PR 里 review 讨论串被标记 resolved/unresolved。
        // action 值：resolved / unresolved（都走通用词典兜底 → 目前显示原文）
        actionStr = l.event_dynamic_pull_request_review_thread(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "DiscussionEvent":
        // GitHub Discussions（issue/PR 之外的第三种讨论区）。webhook 已长期
        // 存在，但直到 2026 仍未收录到 Events API 官方 event-types 文档，属于
        // "文档滞后于实现"。真实 payload 里 action 常见值：created / edited /
        // deleted / pinned / unpinned / locked / unlocked / transferred /
        // category_changed / answered / unanswered / labeled / unlabeled
        actionStr = l.event_dynamic_discussion(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "DiscussionCommentEvent":
        // Discussion 里的评论，action 值：created / edited / deleted
        actionStr = l.event_dynamic_discussion_comment(
          _translateAction(l, event.payload?.action),
          event.repo!.name!,
        );
        break;
      case "SponsorshipEvent":
        // GitHub Sponsors 订阅生命周期，action 值：created / edited /
        // cancelled / tier_changed / pending_cancellation /
        // pending_tier_change。绝大多数已在通用词典覆盖，未命中的走英文兜底
        actionStr = l.event_dynamic_sponsorship(
          _translateAction(l, event.payload?.action),
        );
        break;
      case "PushEvent":
        if (event.payload != null && event.payload?.ref != null) {
          String ref = event.payload!.ref!;
          ref = ref.substring(ref.lastIndexOf("/") + 1);
          actionStr = l.event_dynamic_push(ref, event.repo!.name!);

          String descSpan = "";
          List<PushEventCommit> commits = event.payload?.commits ?? [];
          int count = commits.length;
          int maxLines = 4;
          int max = count > maxLines ? maxLines - 1 : count;

          final String commitFallback = l.event_dynamic_push_commit_fallback;
          for (int i = 0; i < max; i++) {
            PushEventCommit commit = commits[i];
            if (i != 0) {
              descSpan += ("\n");
            }
            String sha = _shortSha(commit.sha);
            descSpan += sha;
            descSpan += " ";
            descSpan += (commit.message ?? commitFallback);
          }
          if (count > maxLines) {
            descSpan = "$descSpan\n...";
          }
          if (descSpan.trim().isNotEmpty) {
            des = descSpan;
          } else if (event.payload?.description != null &&
              event.payload!.description!.trim().isNotEmpty) {
            des = event.payload!.description;
          } else if (event.payload?.head != null &&
              event.payload!.head!.trim().isNotEmpty) {
            String head = _shortSha(event.payload!.head);
            des = l.event_dynamic_push_head(head);
          } else {
            des = "";
          }
        } else {
          actionStr = "";
        }
        break;
      case "ReleaseEvent":
        actionStr = l.event_dynamic_release(
          _translateAction(l, event.payload?.action),
          event.payload!.release!.tagName!,
          event.repo!.name!,
        );
        break;
      case "WatchEvent":
        // WatchEvent 目前 GitHub 只发 action=started（=点 star）。用独立整句
        // 而不是通用词典，避免英语侧读成 `started xxx` 不通顺
        final rawAction = event.payload?.action;
        if (rawAction == 'started' || rawAction == null || rawAction.isEmpty) {
          actionStr = l.event_dynamic_watch_started(event.repo!.name!);
        } else {
          // 未来 GitHub 若扩了新 action，走通用词典兜底
          actionStr = l.event_dynamic_watch(
            _translateAction(l, rawAction),
            event.repo!.name!,
          );
        }
        break;
      default:
        _logUnknownEventTypeOnce(event.type);
        actionStr = "";
    }

    return (actionStr: actionStr, des: des ?? "");
  }

  ///跳转
  static Future<void> ActionUtils(
    BuildContext context,
    Event event,
    currentRepository,
  ) async {
    if (event.repo == null) {
      NavigatorUtils.goPerson(context, event.actor!.login);
      return;
    }
    var [owner, repositoryName] = event.repo!.name!.split("/");
    String fullName = '$owner/$repositoryName';
    switch (event.type) {
      case 'ForkEvent':
        String forkName = "${event.actor!.login!}/$repositoryName";
        if (forkName.toLowerCase() == currentRepository.toLowerCase()) {
          return;
        }
        NavigatorUtils.goReposDetail(
          context,
          event.actor!.login!,
          repositoryName,
        );
        break;
      case 'PushEvent':
        List<PushEventCommit> commits = event.payload?.commits ?? [];
        String? beforeSha = event.payload?.before;
        String? headSha = event.payload?.head;
        List<RepoCommit> compareCommits = [];

        if (!_isInvalidCompareBase(beforeSha) &&
            headSha != null &&
            headSha.isNotEmpty &&
            beforeSha != headSha) {
          CommonUtils.showLoadingDialog(context);
          try {
            var compareRes = await ReposRepository.getReposCompareRequest(
              owner,
              repositoryName,
              beforeSha!,
              headSha,
            );
            if (compareRes != null &&
                compareRes.result &&
                compareRes.data != null) {
              compareCommits = compareRes.data.commits ?? [];
            }
          } finally {
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        }
        if (!context.mounted) {
          return;
        }

        if (compareCommits.length == 1 && compareCommits.first.sha != null) {
          NavigatorUtils.goPushDetailPage(
            context,
            owner,
            repositoryName,
            compareCommits.first.sha,
            true,
          );
          return;
        }

        if (compareCommits.length > 1) {
          StringList list = [];
          for (int i = 0; i < compareCommits.length; i++) {
            RepoCommit commit = compareCommits[i];
            String message =
                commit.commit?.message?.split('\n').first.trim() ?? "Commit";
            if (message.isEmpty) {
              message = "Commit";
            }
            list.add("$message ${_shortSha(commit.sha, 4)}");
          }
          CommonUtils.showCommitOptionDialog(context, list, (index) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              compareCommits[index].sha,
              true,
            );
          });
          return;
        }

        if (commits.isEmpty) {
          if (headSha != null && headSha.isNotEmpty) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              headSha,
              true,
            );
            return;
          }
          if (fullName.toLowerCase() == currentRepository.toLowerCase()) {
            return;
          }
          NavigatorUtils.goReposDetail(context, owner, repositoryName);
        } else if (commits.length == 1 && commits.first.sha != null) {
          NavigatorUtils.goPushDetailPage(
            context,
            owner,
            repositoryName,
            commits.first.sha,
            true,
          );
        } else {
          List<PushEventCommit> validCommits = commits
              .where((item) => item.sha != null && item.sha!.isNotEmpty)
              .toList();
          if (validCommits.isEmpty) {
            if (headSha != null && headSha.isNotEmpty) {
              NavigatorUtils.goPushDetailPage(
                context,
                owner,
                repositoryName,
                headSha,
                true,
              );
            } else {
              NavigatorUtils.goReposDetail(context, owner, repositoryName);
            }
            return;
          }
          if (validCommits.length == 1) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              validCommits.first.sha,
              true,
            );
            return;
          }
          StringList list = [];
          for (int i = 0; i < validCommits.length; i++) {
            PushEventCommit commit = validCommits[i];
            String shaShort = _shortSha(commit.sha, 4);
            String message = (commit.message == null || commit.message!.isEmpty)
                ? "Commit"
                : commit.message!;
            list.add("$message $shaShort");
          }
          CommonUtils.showCommitOptionDialog(context, list, (index) {
            NavigatorUtils.goPushDetailPage(
              context,
              owner,
              repositoryName,
              validCommits[index].sha,
              true,
            );
          });
        }
        break;
      case 'ReleaseEvent':
        String url = event.payload!.release!.tarballUrl!;
        CommonUtils.launchWebView(context, repositoryName, url);
        break;
      case 'IssueCommentEvent':
      case 'IssuesEvent':
        NavigatorUtils.goIssueDetail(
          context,
          owner,
          repositoryName,
          event.payload!.issue!.number.toString(),
          needRightLocalIcon: true,
        );
        break;
      default:
        if (fullName.toLowerCase() == currentRepository.toLowerCase()) {
          return;
        }
        NavigatorUtils.goReposDetail(context, owner, repositoryName);
        break;
    }
  }

  /// 把 GitHub Notifications API 的 reason 枚举翻译为当前语言。
  ///
  /// reason 是 GitHub 通知 API 独有的字段（不是 Events 也不是 Timeline），
  /// 官方文档列出 15 个已知值：approval_requested / assign / author /
  /// ci_activity / comment / invitation / manual / member_feature_requested /
  /// mention / review_requested / security_advisory_credit / security_alert /
  /// state_change / subscribed / team_mention。
  ///
  /// - 命中已知词典 → 返回本地化短语（"@提及你" / "请求你审阅" 等）
  /// - 未命中 → 记录到 [loggedUnknownNotifyReasons]（debug 遥测），
  ///   同时返回原始英文，保证 UI 不空白，也让开发者一眼看到新 reason
  static String translateNotifyReason(AppLocalizations l, String? rawReason) {
    if (rawReason == null || rawReason.isEmpty) {
      return "";
    }
    switch (rawReason) {
      case 'approval_requested':
        return l.notify_reason_approval_requested;
      case 'assign':
        return l.notify_reason_assign;
      case 'author':
        return l.notify_reason_author;
      case 'ci_activity':
        return l.notify_reason_ci_activity;
      case 'comment':
        return l.notify_reason_comment;
      case 'invitation':
        return l.notify_reason_invitation;
      case 'manual':
        return l.notify_reason_manual;
      case 'member_feature_requested':
        return l.notify_reason_member_feature_requested;
      case 'mention':
        return l.notify_reason_mention;
      case 'review_requested':
        return l.notify_reason_review_requested;
      case 'security_advisory_credit':
        return l.notify_reason_security_advisory_credit;
      case 'security_alert':
        return l.notify_reason_security_alert;
      case 'state_change':
        return l.notify_reason_state_change;
      case 'subscribed':
        return l.notify_reason_subscribed;
      case 'team_mention':
        return l.notify_reason_team_mention;
      default:
        _logUnknownNotifyReasonOnce(rawReason);
        return rawReason;
    }
  }

  static void _logUnknownNotifyReasonOnce(String? reason) {
    if (!kDebugMode) return;
    if (reason == null || reason.isEmpty) return;
    if (loggedUnknownNotifyReasons.contains(reason)) return;
    loggedUnknownNotifyReasons.add(reason);
    _talkerWarn(
      '[EventUtils] Unknown notification reason="$reason". '
      'Consider adding a case in translateNotifyReason and notify_reason_* arb.',
    );
  }
}
