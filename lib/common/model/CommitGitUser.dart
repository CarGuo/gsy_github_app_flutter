import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'CommitGitUser.g.dart';

@JsonSerializable()
class CommitGitUser{
  String name;
  String email;
  DateTime date;

  CommitGitUser(this.name, this.email, this.date);

  factory CommitGitUser.fromJson(Map<String, dynamic> json) => _$CommitGitUserFromJson(json);


  Map<String, dynamic> toJson() => _$CommitGitUserToJson(this);
}
