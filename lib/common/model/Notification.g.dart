// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Notification.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) =>
    new Notification(
        json['id'] as String,
        json['unread'] as bool,
        json['reason'] as String,
        json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
        json['last_read_at'] == null
            ? null
            : DateTime.parse(json['last_read_at'] as String),
        json['repository'] == null
            ? null
            : new Repository.fromJson(
                json['repository'] as Map<String, dynamic>),
        json['subject'] == null
            ? null
            : new NotificationSubject.fromJson(
                json['subject'] as Map<String, dynamic>));

abstract class _$NotificationSerializerMixin {
  String get id;
  bool get unread;
  String get reason;
  DateTime get updateAt;
  DateTime get lastReadAt;
  Repository get repository;
  NotificationSubject get subject;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'unread': unread,
        'reason': reason,
        'updated_at': updateAt?.toIso8601String(),
        'last_read_at': lastReadAt?.toIso8601String(),
        'repository': repository,
        'subject': subject
      };
}
