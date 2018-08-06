// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Template.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Template _$TemplateFromJson(Map<String, dynamic> json) => new Template(
    json['name'] as String, json['id'] as int, json['push_id'] as int);

abstract class _$TemplateSerializerMixin {
  String get name;
  int get id;
  int get pushId;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'name': name, 'id': id, 'push_id': pushId};
}
