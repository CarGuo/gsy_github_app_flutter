// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserOrg.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

UserOrg _$UserOrgFromJson(Map<String, dynamic> json) => new UserOrg(
    json['login'] as String,
    json['id'] as int,
    json['url'] as String,
    json['description'] as String,
    json['node_id'] as String,
    json['repos_url'] as String,
    json['events_url'] as String,
    json['hooks_url'] as String,
    json['issues_url'] as String,
    json['members_url'] as String,
    json['public_members_url'] as String,
    json['avatar_url'] as String);

abstract class _$UserOrgSerializerMixin {
  String get login;
  int get id;
  String get url;
  String get description;
  String get nodeId;
  String get reposUrl;
  String get eventsUrl;
  String get hooksUrl;
  String get issuesUrl;
  String get membersUrl;
  String get publicMembersUrl;
  String get avatarUrl;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'login': login,
        'id': id,
        'url': url,
        'description': description,
        'node_id': nodeId,
        'repos_url': reposUrl,
        'events_url': eventsUrl,
        'hooks_url': hooksUrl,
        'issues_url': issuesUrl,
        'members_url': membersUrl,
        'public_members_url': publicMembersUrl,
        'avatar_url': avatarUrl
      };
}
