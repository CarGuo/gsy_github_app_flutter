// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NotificationSubject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSubject _$NotificationSubjectFromJson(Map<String, dynamic> json) {
  return NotificationSubject(
      json['title'] as String, json['url'] as String, json['type'] as String);
}

Map<String, dynamic> _$NotificationSubjectToJson(
        NotificationSubject instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'type': instance.type
    };
