// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'User.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => new User(
    json['login'] as String,
    json['id'] as int,
    json['node_id'] as String,
    json['avatar_url'] as String,
    json['gravatar_id'] as String,
    json['url'] as String,
    json['html_url'] as String,
    json['followers_url'] as String,
    json['following_url'] as String,
    json['gists_url'] as String,
    json['starred_url'] as String,
    json['subscriptions_url'] as String,
    json['organizations_url'] as String,
    json['repos_url'] as String,
    json['events_url'] as String,
    json['received_events_url'] as String,
    json['type'] as String,
    json['site_admin'] as bool,
    json['name'] as String,
    json['company'] as String,
    json['blog'] as String,
    json['location'] as String,
    json['email'] as String,
    json['starred'] as String,
    json['bio'] as String,
    json['public_repos'] as int,
    json['public_gists'] as int,
    json['followers'] as int,
    json['following'] as int,
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
    json['private_gists'] as int,
    json['total_private_repos'] as int,
    json['owned_private_repos'] as int,
    json['disk_usage'] as int,
    json['collaborators'] as int,
    json['two_factor_authentication'] as bool);

abstract class _$UserSerializerMixin {
  String get login;
  int get id;
  String get node_id;
  String get avatar_url;
  String get gravatar_id;
  String get url;
  String get html_url;
  String get followers_url;
  String get following_url;
  String get gists_url;
  String get starred_url;
  String get subscriptions_url;
  String get organizations_url;
  String get repos_url;
  String get events_url;
  String get received_events_url;
  String get type;
  bool get site_admin;
  String get name;
  String get company;
  String get blog;
  String get location;
  String get email;
  String get starred;
  String get bio;
  int get public_repos;
  int get public_gists;
  int get followers;
  int get following;
  DateTime get created_at;
  DateTime get updated_at;
  int get private_gists;
  int get total_private_repos;
  int get owned_private_repos;
  int get disk_usage;
  int get collaborators;
  bool get two_factor_authentication;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'login': login,
        'id': id,
        'node_id': node_id,
        'avatar_url': avatar_url,
        'gravatar_id': gravatar_id,
        'url': url,
        'html_url': html_url,
        'followers_url': followers_url,
        'following_url': following_url,
        'gists_url': gists_url,
        'starred_url': starred_url,
        'subscriptions_url': subscriptions_url,
        'organizations_url': organizations_url,
        'repos_url': repos_url,
        'events_url': events_url,
        'received_events_url': received_events_url,
        'type': type,
        'site_admin': site_admin,
        'name': name,
        'company': company,
        'blog': blog,
        'location': location,
        'email': email,
        'starred': starred,
        'bio': bio,
        'public_repos': public_repos,
        'public_gists': public_gists,
        'followers': followers,
        'following': following,
        'created_at': created_at?.toIso8601String(),
        'updated_at': updated_at?.toIso8601String(),
        'private_gists': private_gists,
        'total_private_repos': total_private_repos,
        'owned_private_repos': owned_private_repos,
        'disk_usage': disk_usage,
        'collaborators': collaborators,
        'two_factor_authentication': two_factor_authentication
      };
}
