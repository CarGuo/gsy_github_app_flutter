// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Template _$TemplateFromJson(Map<String, dynamic> json) => Template(
      json['name'] as String?,
      (json['id'] as num?)?.toInt(),
      (json['push_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TemplateToJson(Template instance) => <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'push_id': instance.pushId,
    };
