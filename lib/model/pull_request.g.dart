// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pull_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PullRequest _$PullRequestFromJson(Map<String, dynamic> json) => PullRequest(
  id: (json['id'] as num?)?.toInt(),
  number: (json['number'] as num?)?.toInt(),
  state: json['state'] as String?,
  draft: json['draft'] as bool?,
  merged: json['merged'] as bool?,
  mergeable: json['mergeable'] as bool?,
  mergeableState: json['mergeable_state'] as String?,
  additions: (json['additions'] as num?)?.toInt(),
  deletions: (json['deletions'] as num?)?.toInt(),
  changedFiles: (json['changed_files'] as num?)?.toInt(),
  commits: (json['commits'] as num?)?.toInt(),
  commentNum: (json['comments'] as num?)?.toInt(),
  reviewComments: (json['review_comments'] as num?)?.toInt(),
  mergedBy: json['merged_by'] == null
      ? null
      : User.fromJson(json['merged_by'] as Map<String, dynamic>),
  requestedReviewers: (json['requested_reviewers'] as List<dynamic>?)
      ?.map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
  head: json['head'] == null
      ? null
      : PullRequestBranchRef.fromJson(json['head'] as Map<String, dynamic>),
  base: json['base'] == null
      ? null
      : PullRequestBranchRef.fromJson(json['base'] as Map<String, dynamic>),
  htmlUrl: json['html_url'] as String?,
);

Map<String, dynamic> _$PullRequestToJson(PullRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'state': instance.state,
      'draft': instance.draft,
      'merged': instance.merged,
      'mergeable': instance.mergeable,
      'mergeable_state': instance.mergeableState,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'changed_files': instance.changedFiles,
      'commits': instance.commits,
      'comments': instance.commentNum,
      'review_comments': instance.reviewComments,
      'merged_by': instance.mergedBy?.toJson(),
      'requested_reviewers': instance.requestedReviewers
          ?.map((e) => e.toJson())
          .toList(),
      'head': instance.head?.toJson(),
      'base': instance.base?.toJson(),
      'html_url': instance.htmlUrl,
    };

PullRequestBranchRef _$PullRequestBranchRefFromJson(
  Map<String, dynamic> json,
) => PullRequestBranchRef(
  label: json['label'] as String?,
  ref: json['ref'] as String?,
  sha: json['sha'] as String?,
);

Map<String, dynamic> _$PullRequestBranchRefToJson(
  PullRequestBranchRef instance,
) => <String, dynamic>{
  'label': instance.label,
  'ref': instance.ref,
  'sha': instance.sha,
};
