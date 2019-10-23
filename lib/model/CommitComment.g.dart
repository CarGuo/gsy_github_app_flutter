// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitComment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitComment _$CommitCommentFromJson(Map<String, dynamic> json) {
  return CommitComment(
      json['id'] as int,
      json['body'] as String,
      json['path'] as String,
      json['position'] as int,
      json['line'] as int,
      json['commit_id'] as String,
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      json['html_url'] as String,
      json['url'] as String,
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>));
}

Map<String, dynamic> _$CommitCommentToJson(CommitComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'path': instance.path,
      'position': instance.position,
      'line': instance.line,
      'commit_id': instance.commitId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'html_url': instance.htmlUrl,
      'url': instance.url,
      'user': instance.user
    };
