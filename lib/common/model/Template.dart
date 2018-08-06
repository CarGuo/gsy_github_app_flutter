import 'package:json_annotation/json_annotation.dart';

///关联文件、允许Template访问 Template.g.dart 中的私有方法
///Template.g.dart 是通过命令生成的文件。名称为 xx.g.dart，其中 xx 为当前 dart 文件名称
///Template.g.dart中创建了抽象类_$TemplateSerializerMixin，实现了_$TemplateFromJson方法
part 'Template.g.dart';

///标志class需要实现json序列化功能
@JsonSerializable()

///'xx.g.dart'文件中，默认会根据当前类名如 AA 生成 _$AASerializerMixin
///所以当前类名为Template，生成的抽象类为 _$TemplateSerializerMixin
class Template extends Object with _$TemplateSerializerMixin {

  String name;

  int id;

  ///通过JsonKey重新定义参数名
  @JsonKey(name: "push_id")
  int pushId;

  Template(this.name, this.id, this.pushId);

  ///'xx.g.dart'文件中，默认会根据当前类名如 AA 生成 _$AAeFromJson方法
  ///所以当前类名为Template，生成的抽象类为 _$TemplateFromJson
  factory Template.fromJson(Map<String, dynamic> json) => _$TemplateFromJson(json);
}
