// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return Notification(
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
          : Repository.fromJson(json['repository'] as Map<String, dynamic>),
      json['subject'] == null
          ? null
          : NotificationSubject.fromJson(
              json['subject'] as Map<String, dynamic>));
}

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unread': instance.unread,
      'reason': instance.reason,
      'updated_at': instance.updateAt?.toIso8601String(),
      'last_read_at': instance.lastReadAt?.toIso8601String(),
      'repository': instance.repository,
      'subject': instance.subject
    };
