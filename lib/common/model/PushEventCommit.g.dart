// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PushEventCommit.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

PushEventCommit _$PushEventCommitFromJson(Map<String, dynamic> json) =>
    new PushEventCommit(
        json['sha'] as String,
        json['author'] == null
            ? null
            : new User.fromJson(json['author'] as Map<String, dynamic>),
        json['message'] as String,
        json['distinct'] as bool,
        json['url'] as String);

abstract class _$PushEventCommitSerializerMixin {
  String get sha;
  User get author;
  String get message;
  bool get distinct;
  String get url;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'sha': sha,
        'author': author,
        'message': message,
        'distinct': distinct,
        'url': url
      };
}
