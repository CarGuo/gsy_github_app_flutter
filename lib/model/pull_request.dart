import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pull_request.g.dart';

/// GitHub Pull Request 详情模型
///
/// 对应 REST API：GET /repos/:owner/:repo/pulls/:number
///
/// 说明：
/// - 仓库中 issue 详情复用 [Issue] 模型，`issue.pullRequest` 只是一个
///   带 url/html_url 的轻量指针（[PullRequestRef]）。真正想拿到
///   merged/mergeable/draft/base/head/additions 等 PR 独有信息，需要
///   再打一次 /pulls/:n。这里的 [PullRequest] 就是那份返回体的映射。
/// - 只挑 UI 会用到的字段，避免把整个 4KB payload 全打进模型。
@JsonSerializable(explicitToJson: true)
class PullRequest {
  int? id;
  int? number;
  String? state;
  bool? draft;
  bool? merged;

  /// GitHub 官方语义：
  /// * `null` 表示还在计算
  /// * `true` / `false` 表示是否可 merge
  bool? mergeable;

  /// 官方 mergeable_state：clean / dirty / blocked / behind / unstable / draft / unknown
  @JsonKey(name: "mergeable_state")
  String? mergeableState;

  int? additions;
  int? deletions;

  @JsonKey(name: "changed_files")
  int? changedFiles;

  int? commits;

  @JsonKey(name: "comments")
  int? commentNum;

  @JsonKey(name: "review_comments")
  int? reviewComments;

  @JsonKey(name: "merged_by")
  User? mergedBy;

  @JsonKey(name: "requested_reviewers")
  List<User>? requestedReviewers;

  PullRequestBranchRef? head;
  PullRequestBranchRef? base;

  @JsonKey(name: "html_url")
  String? htmlUrl;

  PullRequest({
    this.id,
    this.number,
    this.state,
    this.draft,
    this.merged,
    this.mergeable,
    this.mergeableState,
    this.additions,
    this.deletions,
    this.changedFiles,
    this.commits,
    this.commentNum,
    this.reviewComments,
    this.mergedBy,
    this.requestedReviewers,
    this.head,
    this.base,
    this.htmlUrl,
  });

  factory PullRequest.fromJson(Map<String, dynamic> json) =>
      _$PullRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestToJson(this);
}

/// PR 的 head / base 分支引用（label 通常是 `owner:branch`，ref 是纯分支名）。
@JsonSerializable()
class PullRequestBranchRef {
  String? label;
  String? ref;
  String? sha;

  PullRequestBranchRef({this.label, this.ref, this.sha});

  factory PullRequestBranchRef.fromJson(Map<String, dynamic> json) =>
      _$PullRequestBranchRefFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestBranchRefToJson(this);
}

/// issue 详情里 `pull_request` 字段的轻量指针。
///
/// 命中即代表当前 issue 其实是 PR；此时可以拿 `url` 去打 pulls 详情。
class PullRequestRef {
  final String? url;
  final String? htmlUrl;
  final String? diffUrl;
  final String? patchUrl;
  final DateTime? mergedAt;

  PullRequestRef({
    this.url,
    this.htmlUrl,
    this.diffUrl,
    this.patchUrl,
    this.mergedAt,
  });

  factory PullRequestRef.fromJson(Map<String, dynamic> json) => PullRequestRef(
        url: json['url'] as String?,
        htmlUrl: json['html_url'] as String?,
        diffUrl: json['diff_url'] as String?,
        patchUrl: json['patch_url'] as String?,
        mergedAt: json['merged_at'] == null
            ? null
            : DateTime.tryParse(json['merged_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'html_url': htmlUrl,
        'diff_url': diffUrl,
        'patch_url': patchUrl,
        if (mergedAt != null) 'merged_at': mergedAt!.toIso8601String(),
      };
}
