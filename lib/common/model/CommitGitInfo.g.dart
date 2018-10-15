// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitGitInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitGitInfo _$CommitGitInfoFromJson(Map<String, dynamic> json) {
  return CommitGitInfo(
      json['message'] as String,
      json['url'] as String,
      json['comment_count'] as int,
      json['author'] == null
          ? null
          : CommitGitUser.fromJson(json['author'] as Map<String, dynamic>),
      json['committer'] == null
          ? null
          : CommitGitUser.fromJson(json['committer'] as Map<String, dynamic>));
}

Map<String, dynamic> _$CommitGitInfoToJson(CommitGitInfo instance) =>
    <String, dynamic>{
      'message': instance.message,
      'url': instance.url,
      'comment_count': instance.commentCount,
      'author': instance.author,
      'committer': instance.committer
    };
