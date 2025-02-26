// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitsComparison.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitsComparison _$CommitsComparisonFromJson(Map<String, dynamic> json) =>
    CommitsComparison(
      json['url'] as String?,
      json['html_url'] as String?,
      json['base_commit'] == null
          ? null
          : RepoCommit.fromJson(json['base_commit'] as Map<String, dynamic>),
      json['merge_base_commit'] == null
          ? null
          : RepoCommit.fromJson(
              json['merge_base_commit'] as Map<String, dynamic>),
      json['status'] as String?,
      (json['total_commits'] as num?)?.toInt(),
      (json['commits'] as List<dynamic>?)
          ?.map((e) => RepoCommit.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['files'] as List<dynamic>?)
          ?.map((e) => CommitFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CommitsComparisonToJson(CommitsComparison instance) =>
    <String, dynamic>{
      'url': instance.url,
      'html_url': instance.htmlUrl,
      'base_commit': instance.baseCommit,
      'merge_base_commit': instance.mergeBaseCommit,
      'status': instance.status,
      'total_commits': instance.totalCommits,
      'commits': instance.commits,
      'files': instance.files,
    };
