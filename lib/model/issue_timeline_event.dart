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
/// - reviewed（PR 场景，issue 侧一般不出现，但保留兜底）
/// - commented（timeline 会同时下发 comment，含 body/reactions/id）
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

  /// referenced/cross-referenced 时相关联的 issue/PR html_url 与标题
  final String? sourceUrl;
  final String? sourceTitle;
  final String? sourceState;

  /// commented 事件专属
  final int? commentId;
  final String? body;
  final String? bodyHtml;
  final String? authorAssociation;
  final DateTime? updatedAt;

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
    this.raw = const <String, dynamic>{},
  });

  factory IssueTimelineEvent.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as String?;

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

    return IssueTimelineEvent(
      id: (json['id'] as num?)?.toInt(),
      event: event,
      actor: actor,
      createdAt: parseDate(json['created_at']),
      label: label,
      assignee: assignee,
      milestoneTitle: milestoneTitle,
      renameFrom: renameFrom,
      renameTo: renameTo,
      sourceUrl: sourceUrl,
      sourceTitle: sourceTitle,
      sourceState: sourceState,
      commentId: event == 'commented' ? (json['id'] as num?)?.toInt() : null,
      body: json['body'] as String?,
      bodyHtml: json['body_html'] as String?,
      authorAssociation: json['author_association'] as String?,
      updatedAt: parseDate(json['updated_at']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  bool get isCommented => event == 'commented';
}
