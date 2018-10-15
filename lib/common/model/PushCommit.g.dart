// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PushCommit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushCommit _$PushCommitFromJson(Map<String, dynamic> json) {
  return PushCommit(
      (json['files'] as List)
          ?.map((e) =>
              e == null ? null : CommitFile.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      json['stats'] == null
          ? null
          : CommitStats.fromJson(json['stats'] as Map<String, dynamic>),
      json['sha'] as String,
      json['url'] as String,
      json['html_url'] as String,
      json['comments_url'] as String,
      json['commit'] == null
          ? null
          : CommitGitInfo.fromJson(json['commit'] as Map<String, dynamic>),
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
      json['committer'] == null
          ? null
          : User.fromJson(json['committer'] as Map<String, dynamic>),
      (json['parents'] as List)
          ?.map((e) =>
              e == null ? null : RepoCommit.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$PushCommitToJson(PushCommit instance) =>
    <String, dynamic>{
      'files': instance.files,
      'stats': instance.stats,
      'sha': instance.sha,
      'url': instance.url,
      'html_url': instance.htmlUrl,
      'comments_url': instance.commentsUrl,
      'commit': instance.commit,
      'author': instance.author,
      'committer': instance.committer,
      'parents': instance.parents
    };
