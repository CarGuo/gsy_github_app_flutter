import 'package:gsy_github_app_flutter/model/label.dart';
import 'package:gsy_github_app_flutter/model/user.dart';

/// GitHub Issue Timeline Event
///
/// 参考：https://docs.github.com/en/rest/issues/timeline
///
/// 由于 timeline 端点会针对不同 `event` 返回不同形状的 payload，
/// 这里用一个融合模型承接常用事件的字段：
/// - labeled / unlabeled -> [label]
/// - assigned / unassigned -> [assignee]
/// - milestoned / demilestoned -> [milestoneTitle]
/// - renamed -> [renameFrom] / [renameTo]
/// - closed / reopened / locked / unlocked / merged / pinned / unpinned
/// - referenced / cross-referenced / mentioned
/// - reviewed（PR 场景。GitHub timeline 会以 `event=reviewed`
///   下发，`state` 表示 approved / changes_requested / commented / dismissed）
/// - review_requested / review_request_removed（PR，含 requested_reviewer 或
///   requested_team，见 [reviewerName]）
/// - ready_for_review / convert_to_draft（PR 草稿态切换）
/// - head_ref_force_pushed / head_ref_deleted / head_ref_restored
/// - base_ref_changed / base_ref_force_pushed
/// - auto_merge_enabled / auto_merge_disabled
/// - commented（timeline 会同时下发 comment，含 body/reactions/id）
/// - committed（PR 里的提交事件。GitHub 返回的顶层字段是 sha/message/author，
///   而不是常规的 event/actor；本模型把 sha/message/author.name 解析成
///   [commitSha]/[commitMessage]/[commitAuthorName]，并把 [sourceUrl] 指到
///   commit 的 html_url，便于点击整行跳到 commit 详情页）
/// - copilot_work_started / copilot_work_finished（Copilot coding agent 相关。
///   目前**未见于**官方 REST timeline 文档，是从真实 PR 响应里观察到的事件名；
///   若 GitHub 未来更名或撤销，需要同步 [issue_timeline_item.dart] 的 case 分支
///   和 4 份 arb 里的 pr_timeline_copilot_work_* 文案。）
/// - added_to_merge_queue / removed_from_merge_queue（PR merge queue 特性，
///   官方 timeline 事件）
/// - added_to_project_v2 / project_v2_item_status_changed（Projects V2 事件，
///   issue 和 PR 都可能出现）
/// - issue_type_added（GitHub Issue Types Beta 特性，仅 issue 出现）
class IssueTimelineEvent {
  final int? id;
  final String? event;
  final User? actor;
  final DateTime? createdAt;

  final Label? label;
  final User? assignee;
  final String? milestoneTitle;
  final String? renameFrom;
  final String? renameTo;

  /// referenced/cross-referenced 时相关联的 issue/PR html_url 与标题；
  /// 对 committed 事件复用为 commit 的 html_url
  final String? sourceUrl;
  final String? sourceTitle;
  final String? sourceState;

  /// commented 事件专属
  final int? commentId;
  final String? body;
  final String? bodyHtml;
  final String? authorAssociation;
  final DateTime? updatedAt;

  /// `reviewed` 事件的 review 状态。GitHub 官方取值：
  /// `approved` / `changes_requested` / `commented` / `dismissed`。
  final String? reviewState;

  /// `review_requested` / `review_request_removed` 场景下的被请求评审者名字。
  /// 优先取 `requested_reviewer.login`，否则回退到 `requested_team.name`。
  final String? reviewerName;

  /// `committed` 事件专属：commit 的完整 40 位 sha
  final String? commitSha;

  /// `committed` 事件专属：commit message。首行是标题，`\n\n` 后是正文。
  /// 渲染时只取首行以避免污染 timeline 事件行。
  final String? commitMessage;

  /// `committed` 事件专属：commit 的 author.name（不是 login，因为 GitHub
  /// 在这里只给了姓名/邮箱，不给 GitHub 用户名）。用于 actor 缺失时的兜底显示。
  final String? commitAuthorName;

  /// 原始 JSON，用于兜底展示
  final Map<String, dynamic> raw;

  IssueTimelineEvent({
    this.id,
    this.event,
    this.actor,
    this.createdAt,
    this.label,
    this.assignee,
    this.milestoneTitle,
    this.renameFrom,
    this.renameTo,
    this.sourceUrl,
    this.sourceTitle,
    this.sourceState,
    this.commentId,
    this.body,
    this.bodyHtml,
    this.authorAssociation,
    this.updatedAt,
    this.reviewState,
    this.reviewerName,
    this.commitSha,
    this.commitMessage,
    this.commitAuthorName,
    this.raw = const <String, dynamic>{},
  });

  /// commit 短哈希最短长度，用于同时判定：
  /// 1. 顶层缺 event 但带 sha 时是否推断为 committed
  /// 2. [commitShortSha] getter 是否能返回有效值
  /// 两处必须共享同一阈值，避免推断成 committed 却拿不到短哈希的错位。
  static const int _kMinShaLen = 7;

  factory IssueTimelineEvent.fromJson(Map<String, dynamic> json) {
    // committed 事件 GitHub 顶层不总带 event 字段（历史兼容），但一定带 sha
    final rawEvent = json['event'] as String?;
    final rawSha = json['sha'] as String?;
    final event = rawEvent ??
        ((rawSha != null && rawSha.length >= _kMinShaLen) ? 'committed' : null);

    User? parseUser(dynamic v) => (v is Map<String, dynamic>)
        ? User.fromJson(Map<String, dynamic>.from(v))
        : null;

    DateTime? parseDate(dynamic v) =>
        (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;

    Label? label;
    if (json['label'] is Map<String, dynamic>) {
      label = Label.fromJson(Map<String, dynamic>.from(json['label'] as Map));
    }
    User? assignee = parseUser(json['assignee']);

    String? milestoneTitle;
    if (json['milestone'] is Map<String, dynamic>) {
      milestoneTitle = (json['milestone'] as Map)['title'] as String?;
    }

    String? renameFrom;
    String? renameTo;
    if (json['rename'] is Map<String, dynamic>) {
      final rename = json['rename'] as Map<String, dynamic>;
      renameFrom = rename['from'] as String?;
      renameTo = rename['to'] as String?;
    }

    String? sourceUrl;
    String? sourceTitle;
    String? sourceState;
    if (json['source'] is Map<String, dynamic>) {
      final source = json['source'] as Map<String, dynamic>;
      final issue = source['issue'];
      if (issue is Map<String, dynamic>) {
        sourceUrl = issue['html_url'] as String?;
        sourceTitle = issue['title'] as String?;
        sourceState = issue['state'] as String?;
      }
    }

    // commented 事件的 actor 位于 user 字段
    User? actor = parseUser(json['actor']) ?? parseUser(json['user']);

    // reviewed / review_requested 相关
    String? reviewState;
    if (event == 'reviewed') {
      reviewState = json['state'] as String?;
    }
    String? reviewerName;
    if (event == 'review_requested' || event == 'review_request_removed') {
      final reviewer = json['requested_reviewer'];
      if (reviewer is Map && reviewer['login'] is String) {
        reviewerName = reviewer['login'] as String;
      } else {
        final team = json['requested_team'];
        if (team is Map && team['name'] is String) {
          reviewerName = team['name'] as String;
        }
      }
    }

    // committed 事件专属字段：sha / message 首行 / author.name / html_url
    String? commitSha;
    String? commitMessage;
    String? commitAuthorName;
    DateTime? commitDate;
    if (event == 'committed') {
      commitSha = rawSha;
      final rawMessage = json['message'];
      if (rawMessage is String && rawMessage.isNotEmpty) {
        // commit message 首行是标题，`\n\n` 分正文；只保留首行避免污染 UI
        final firstLine = rawMessage.split('\n').first.trim();
        commitMessage = firstLine.isEmpty ? null : firstLine;
      }
      final authorMap = json['author'];
      if (authorMap is Map && authorMap['name'] is String) {
        // GitHub 罕见但合法地会返回空 name 字符串；不接受空串，让 UI 走 actor 兜底
        final name = authorMap['name'] as String;
        commitAuthorName = name.isNotEmpty ? name : null;
        final authorDate = authorMap['date'];
        if (authorDate is String && authorDate.isNotEmpty) {
          commitDate = DateTime.tryParse(authorDate);
        }
      }
      // 把 commit 的 html_url 复用到 sourceUrl，让整行 InkWell 能跳转
      final htmlUrl = json['html_url'];
      if (htmlUrl is String && htmlUrl.isNotEmpty) {
        sourceUrl = htmlUrl;
      }
    }

    return IssueTimelineEvent(
      id: (json['id'] as num?)?.toInt(),
      event: event,
      actor: actor,
      createdAt: parseDate(json['created_at']) ??
          parseDate(json['submitted_at']) ??
          commitDate,
      label: label,
      assignee: assignee,
      milestoneTitle: milestoneTitle,
      renameFrom: renameFrom,
      renameTo: renameTo,
      sourceUrl: sourceUrl,
      sourceTitle: sourceTitle,
      sourceState: sourceState,
      commentId: event == 'commented' ? (json['id'] as num?)?.toInt() : null,
      body: (event == 'commented' || event == 'reviewed')
          ? json['body'] as String?
          : null,
      bodyHtml: (event == 'commented' || event == 'reviewed')
          ? json['body_html'] as String?
          : null,
      authorAssociation: (event == 'commented' || event == 'reviewed')
          ? json['author_association'] as String?
          : null,
      updatedAt: parseDate(json['updated_at']),
      reviewState: reviewState,
      reviewerName: reviewerName,
      commitSha: commitSha,
      commitMessage: commitMessage,
      commitAuthorName: commitAuthorName,
      raw: Map<String, dynamic>.from(json),
    );
  }

  bool get isCommented => event == 'commented';

  /// committed 事件短哈希（前 [_kMinShaLen] 位），API 未返回 sha 时返回 null
  String? get commitShortSha {
    final s = commitSha;
    if (s == null || s.length < _kMinShaLen) return null;
    return s.substring(0, _kMinShaLen);
  }
}
