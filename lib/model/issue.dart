import 'package:gsy_github_app_flutter/model/label.dart';
import 'package:gsy_github_app_flutter/model/milestone.dart';
import 'package:gsy_github_app_flutter/model/reactions.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'issue.g.dart';

@JsonSerializable(explicitToJson: true)
class Issue {
  int? id;
  int? number;
  String? title;
  String? state;
  bool? locked;
  @JsonKey(name: "comments")
  int? commentNum;

  @JsonKey(name: "created_at")
  DateTime? createdAt;
  @JsonKey(name: "updated_at")
  DateTime? updatedAt;
  @JsonKey(name: "closed_at")
  DateTime? closedAt;
  String? body;
  @JsonKey(name: "body_html")
  String? bodyHtml;

  User? user;
  @JsonKey(name: "repository_url")
  String? repoUrl;
  @JsonKey(name: "html_url")
  String? htmlUrl;
  @JsonKey(name: "closed_by")
  User? closeBy;

  /// 官方 issue 详情附加能力
  @JsonKey(name: "author_association")
  String? authorAssociation;

  @JsonKey(
    name: "labels",
    fromJson: _labelsFromJson,
    toJson: _labelsToJson,
  )
  List<Label>? labels;

  @JsonKey(
    name: "assignees",
    fromJson: _assigneesFromJson,
    toJson: _assigneesToJson,
  )
  List<User>? assignees;

  @JsonKey(name: "milestone")
  Milestone? milestone;

  @JsonKey(
    name: "reactions",
    fromJson: _reactionsFromJson,
    toJson: _reactionsToJson,
  )
  Reactions? reactions;


  Issue(
    this.id,
    this.number,
    this.title,
    this.state,
    this.locked,
    this.commentNum,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.body,
    this.bodyHtml,
    this.user,
    this.repoUrl,
    this.htmlUrl,
    this.closeBy, {
    this.authorAssociation,
    this.labels,
    this.assignees,
    this.milestone,
    this.reactions,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

  Map<String, dynamic> toJson() => _$IssueToJson(this);
}

List<Label>? _labelsFromJson(dynamic list) {
  if (list is! List) return null;
  return list
      .whereType<Map>()
      .map((e) => Label.fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

List<Map<String, dynamic>>? _labelsToJson(List<Label>? list) {
  if (list == null) return null;
  return list
      .map((e) => <String, dynamic>{
            'name': e.name,
            'color': e.color,
            'description': e.description,
          })
      .toList(growable: false);
}

List<User>? _assigneesFromJson(dynamic list) {
  if (list is! List) return null;
  return list
      .whereType<Map>()
      .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);
}

List<Map<String, dynamic>>? _assigneesToJson(List<User>? list) {
  if (list == null) return null;
  return list.map((e) => e.toJson()).toList(growable: false);
}

Reactions? _reactionsFromJson(dynamic v) {
  if (v is Map<String, dynamic>) return Reactions.fromJson(v);
  return null;
}

Map<String, dynamic>? _reactionsToJson(Reactions? r) {
  if (r == null) return null;
  return <String, dynamic>{
    'total_count': r.totalCount,
    '+1': r.plusOne,
    '-1': r.minusOne,
    'laugh': r.laugh,
    'hooray': r.hooray,
    'confused': r.confused,
    'heart': r.heart,
    'rocket': r.rocket,
    'eyes': r.eyes,
  };
}
