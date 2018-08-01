// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Issue.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Issue _$IssueFromJson(Map<String, dynamic> json) => new Issue(
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
        : new User.fromJson(json['user'] as Map<String, dynamic>),
    json['repository_url'] as String,
    json['html_url'] as String,
    json['closed_by'] == null
        ? null
        : new User.fromJson(json['closed_by'] as Map<String, dynamic>));

abstract class _$IssueSerializerMixin {
  int get id;
  int get number;
  String get title;
  String get state;
  bool get locked;
  int get commentNum;
  DateTime get createdAt;
  DateTime get updatedAt;
  DateTime get closedAt;
  String get body;
  String get bodyHtml;
  User get user;
  String get repoUrl;
  String get htmlUrl;
  User get closeBy;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'number': number,
        'title': title,
        'state': state,
        'locked': locked,
        'comments': commentNum,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'closed_at': closedAt?.toIso8601String(),
        'body': body,
        'body_html': bodyHtml,
        'user': user,
        'repository_url': repoUrl,
        'html_url': htmlUrl,
        'closed_by': closeBy
      };
}
