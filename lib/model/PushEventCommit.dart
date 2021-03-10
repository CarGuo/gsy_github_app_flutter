import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'PushEventCommit.g.dart';

@JsonSerializable()
class PushEventCommit {
  String? sha;
  User? author;
  String? message;
  bool? distinct;
  String? url;

  PushEventCommit(
    this.sha,
    this.author,
    this.message,
    this.distinct,
    this.url,
  );

  factory PushEventCommit.fromJson(Map<String, dynamic> json) => _$PushEventCommitFromJson(json);

  Map<String, dynamic> toJson() => _$PushEventCommitToJson(this);
}
