/// GitHub Issue Milestone 模型
/// 参考 REST API v3：https://docs.github.com/en/rest/issues/milestones
class Milestone {
  final int? number;
  final String? title;
  final String? state;
  final String? description;

  Milestone({this.number, this.title, this.state, this.description});

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        number: (json['number'] as num?)?.toInt(),
        title: json['title'] as String?,
        state: json['state'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'number': number,
        'title': title,
        'state': state,
        'description': description,
      };
}
