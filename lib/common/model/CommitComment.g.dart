// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitComment.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

CommitComment _$CommitCommentFromJson(Map<String, dynamic> json) =>
    new CommitComment(
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
            : new User.fromJson(json['user'] as Map<String, dynamic>));

abstract class _$CommitCommentSerializerMixin {
  int get id;
  String get body;
  String get path;
  int get position;
  int get line;
  String get commitId;
  DateTime get createdAt;
  DateTime get updatedAt;
  String get htmlUrl;
  String get url;
  User get user;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'body': body,
        'path': path,
        'position': position,
        'line': line,
        'commit_id': commitId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'html_url': htmlUrl,
        'url': url,
        'user': user
      };
}
