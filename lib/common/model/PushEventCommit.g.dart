// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PushEventCommit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushEventCommit _$PushEventCommitFromJson(Map<String, dynamic> json) {
  return PushEventCommit(
      json['sha'] as String,
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
      json['message'] as String,
      json['distinct'] as bool,
      json['url'] as String);
}

Map<String, dynamic> _$PushEventCommitToJson(PushEventCommit instance) =>
    <String, dynamic>{
      'sha': instance.sha,
      'author': instance.author,
      'message': instance.message,
      'distinct': instance.distinct,
      'url': instance.url
    };
