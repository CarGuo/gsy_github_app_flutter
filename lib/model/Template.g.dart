// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Template _$TemplateFromJson(Map<String, dynamic> json) {
  return Template(
      json['name'] as String, json['id'] as int, json['push_id'] as int);
}

Map<String, dynamic> _$TemplateToJson(Template instance) => <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'push_id': instance.pushId
    };
