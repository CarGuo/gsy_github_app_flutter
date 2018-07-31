// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Event.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => new Event(
    json['id'] as String,
    json['type'] as String,
    json['actor'] == null
        ? null
        : new User.fromJson(json['actor'] as Map<String, dynamic>),
    json['repo'] == null
        ? null
        : new Repository.fromJson(json['repo'] as Map<String, dynamic>),
    json['org'] == null
        ? null
        : new User.fromJson(json['org'] as Map<String, dynamic>),
    json['payload'] == null
        ? null
        : new EventPayload.fromJson(json['payload'] as Map<String, dynamic>),
    json['public'] as bool,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String));

abstract class _$EventSerializerMixin {
  String get id;
  String get type;
  User get actor;
  Repository get repo;
  User get org;
  EventPayload get payload;
  bool get isPublic;
  DateTime get createdAt;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'actor': actor,
        'repo': repo,
        'org': org,
        'payload': payload,
        'public': isPublic,
        'created_at': createdAt?.toIso8601String()
      };
}
