/// GitHub Issue Label 模型
/// 参考 REST API v3：https://docs.github.com/en/rest/issues/labels
class Label {
  final String? name;
  final String? color;
  final String? description;

  Label({this.name, this.color, this.description});

  factory Label.fromJson(Map<String, dynamic> json) => Label(
        name: json['name'] as String?,
        color: json['color'] as String?,
        description: json['description'] as String?,
      );

  static List<Label> listFromJson(dynamic list) {
    if (list is! List) return const <Label>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Label.fromJson)
        .toList(growable: false);
  }
}
