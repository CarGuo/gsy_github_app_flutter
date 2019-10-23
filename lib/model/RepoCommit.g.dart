// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RepoCommit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepoCommit _$RepoCommitFromJson(Map<String, dynamic> json) {
  return RepoCommit(
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

Map<String, dynamic> _$RepoCommitToJson(RepoCommit instance) =>
    <String, dynamic>{
      'sha': instance.sha,
      'url': instance.url,
      'html_url': instance.htmlUrl,
      'comments_url': instance.commentsUrl,
      'commit': instance.commit,
      'author': instance.author,
      'committer': instance.committer,
      'parents': instance.parents
    };
