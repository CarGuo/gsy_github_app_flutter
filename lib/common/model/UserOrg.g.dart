// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserOrg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserOrg _$UserOrgFromJson(Map<String, dynamic> json) {
  return UserOrg(
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
}

Map<String, dynamic> _$UserOrgToJson(UserOrg instance) => <String, dynamic>{
      'login': instance.login,
      'id': instance.id,
      'url': instance.url,
      'description': instance.description,
      'node_id': instance.nodeId,
      'repos_url': instance.reposUrl,
      'events_url': instance.eventsUrl,
      'hooks_url': instance.hooksUrl,
      'issues_url': instance.issuesUrl,
      'members_url': instance.membersUrl,
      'public_members_url': instance.publicMembersUrl,
      'avatar_url': instance.avatarUrl
    };
