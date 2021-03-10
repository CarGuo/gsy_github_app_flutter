import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'Issue.g.dart';

@JsonSerializable()
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
    this.closeBy,
  );

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

  Map<String, dynamic> toJson() => _$IssueToJson(this);
}
