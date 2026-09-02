import 'package:json_annotation/json_annotation.dart';


part 'template.g.dart';

@JsonSerializable()
class Template {

  String? name;

  int? id;


  @JsonKey(name: "push_id")
  int? pushId;

  new(this.name, this.id, this.pushId);


  factory fromJson(Map<String, dynamic> json) => _$TemplateFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateToJson(this);
}
