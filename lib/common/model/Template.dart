import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'Template.g.dart';

@JsonSerializable()
class Template extends Object with _$TemplateSerializerMixin {

  Template();

  factory Template.fromJson(Map<String, dynamic> json) => _$TemplateFromJson(json);
}
