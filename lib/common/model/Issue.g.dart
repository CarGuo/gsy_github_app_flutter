// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Issue _$IssueFromJson(Map<String, dynamic> json) {
  return Issue(
      json['id'] as int,
      json['number'] as int,
      json['title'] as String,
      json['state'] as String,
      json['locked'] as bool,
      json['comments'] as int,
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      json['body'] as String,
      json['body_html'] as String,
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      json['repository_url'] as String,
      json['html_url'] as String,
      json['closed_by'] == null
          ? null
          : User.fromJson(json['closed_by'] as Map<String, dynamic>));
}

Map<String, dynamic> _$IssueToJson(Issue instance) => <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'title': instance.title,
      'state': instance.state,
      'locked': instance.locked,
      'comments': instance.commentNum,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'body': instance.body,
      'body_html': instance.bodyHtml,
      'user': instance.user,
      'repository_url': instance.repoUrl,
      'html_url': instance.htmlUrl,
      'closed_by': instance.closeBy
    };
