import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-08-10
 */
part 'UserOrg.g.dart';

@JsonSerializable()
class UserOrg extends Object with _$UserOrgSerializerMixin {
  String login;
  int id;
  String url;
  String description;
  @JsonKey(name: "node_id")
  String nodeId;
  @JsonKey(name: "repos_url")
  String reposUrl;
  @JsonKey(name: "events_url")
  String eventsUrl;
  @JsonKey(name: "hooks_url")
  String hooksUrl;
  @JsonKey(name: "issues_url")
  String issuesUrl;
  @JsonKey(name: "members_url")
  String membersUrl;
  @JsonKey(name: "public_members_url")
  String publicMembersUrl;
  @JsonKey(name: "avatar_url")
  String avatarUrl;

  UserOrg(
    this.login,
    this.id,
    this.url,
    this.description,
    this.nodeId,
    this.reposUrl,
    this.eventsUrl,
    this.hooksUrl,
    this.issuesUrl,
    this.membersUrl,
    this.publicMembersUrl,
    this.avatarUrl,
  );

  /// A necessary factory constructor for creating a new User instance
  /// from a map. We pass the map to the generated _$UserFromJson constructor.
  /// The constructor is named after the source class, in this case User.
  factory UserOrg.fromJson(Map<String, dynamic> json) => _$UserOrgFromJson(json);

  // 命名构造函数
  UserOrg.empty();
}
