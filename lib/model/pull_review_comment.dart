import 'package:gsy_github_app_flutter/model/user.dart';

/// GitHub Pull Request 行级评审评论
///
/// 参考：GET /repos/:o/:r/pulls/:number/comments
///
/// 与 issue comments（`/issues/:n/comments`）不同：
/// - issue comments 是整条 PR 的对话流，不带 path/position
/// - review comments 带 [path] + [position]/[line]，锚定到 diff 的某一行
///
/// 为什么不复用 json_annotation：本 model 只在 UI 层聚合展示，字段不多、
/// 也不入库，手写 fromJson 更直观也和 [IssueTimelineEvent] 保持同一风格。
///
/// 字段语义：
/// - [path]：文件相对路径，与 `CommitFile.fileName` 匹配用于按文件聚合
/// - [position]：hunk 内行索引（从 hunk header 后第 1 行开始，包含 +/-/context）；
///   当评论过时（outdated）时 GitHub 可能返回 null，此时优先看 [originalPosition]
/// - [line]：新版 GitHub 增补字段，指向 blob 上的行号，UI 展示用它更直观
/// - [body]：评论正文（markdown）
/// - [user]：评论作者
/// - [htmlUrl]：跳转到 github.com 上锚点行的 URL
class PullReviewComment {
  final int? id;
  final String? path;
  final int? position;
  final int? originalPosition;
  final int? line;
  final int? originalLine;
  final String? diffHunk;
  final String? body;
  final User? user;
  final String? htmlUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PullReviewComment({
    this.id,
    this.path,
    this.position,
    this.originalPosition,
    this.line,
    this.originalLine,
    this.diffHunk,
    this.body,
    this.user,
    this.htmlUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory PullReviewComment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;

    User? user;
    if (json['user'] is Map<String, dynamic>) {
      user = User.fromJson(Map<String, dynamic>.from(json['user'] as Map));
    }

    return PullReviewComment(
      id: (json['id'] as num?)?.toInt(),
      path: json['path'] as String?,
      position: (json['position'] as num?)?.toInt(),
      originalPosition: (json['original_position'] as num?)?.toInt(),
      line: (json['line'] as num?)?.toInt(),
      originalLine: (json['original_line'] as num?)?.toInt(),
      diffHunk: json['diff_hunk'] as String?,
      body: json['body'] as String?,
      user: user,
      htmlUrl: json['html_url'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// UI 展示用行号：优先 [line]（新字段，指向 blob），回退到 [originalLine]。
  /// 都没有时返回 null，UI 侧用「已过时」文案兜底。
  int? get displayLine => line ?? originalLine;
}
