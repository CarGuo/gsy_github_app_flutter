// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repository _$RepositoryFromJson(Map<String, dynamic> json) {
  return Repository(
      json['id'] as int,
      json['size'] as int,
      json['name'] as String,
      json['full_name'] as String,
      json['html_url'] as String,
      json['description'] as String,
      json['language'] as String,
      json['license'] == null
          ? null
          : License.fromJson(json['license'] as Map<String, dynamic>),
      json['default_branch'] as String,
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      json['pushed_at'] == null
          ? null
          : DateTime.parse(json['pushed_at'] as String),
      json['git_url'] as String,
      json['ssh_url'] as String,
      json['clone_url'] as String,
      json['svn_url'] as String,
      json['stargazers_count'] as int,
      json['watchers_count'] as int,
      json['forks_count'] as int,
      json['open_issues_count'] as int,
      json['subscribers_count'] as int,
      json['private'] as bool,
      json['fork'] as bool,
      json['has_issues'] as bool,
      json['has_projects'] as bool,
      json['has_downloads'] as bool,
      json['has_wiki'] as bool,
      json['has_pages'] as bool,
      json['owner'] == null
          ? null
          : User.fromJson(json['owner'] as Map<String, dynamic>),
      json['parent'] == null
          ? null
          : Repository.fromJson(json['parent'] as Map<String, dynamic>),
      json['permissions'] == null
          ? null
          : RepositoryPermissions.fromJson(
              json['permissions'] as Map<String, dynamic>),
      (json['topics'] as List)?.map((e) => e as String)?.toList())
    ..allIssueCount = json['allIssueCount'] as int;
}

Map<String, dynamic> _$RepositoryToJson(Repository instance) =>
    <String, dynamic>{
      'id': instance.id,
      'size': instance.size,
      'name': instance.name,
      'full_name': instance.fullName,
      'html_url': instance.htmlUrl,
      'description': instance.description,
      'language': instance.language,
      'default_branch': instance.defaultBranch,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'pushed_at': instance.pushedAt?.toIso8601String(),
      'git_url': instance.gitUrl,
      'ssh_url': instance.sshUrl,
      'clone_url': instance.cloneUrl,
      'svn_url': instance.svnUrl,
      'stargazers_count': instance.stargazersCount,
      'watchers_count': instance.watchersCount,
      'forks_count': instance.forksCount,
      'open_issues_count': instance.openIssuesCount,
      'subscribers_count': instance.subscribersCount,
      'private': instance.private,
      'fork': instance.fork,
      'has_issues': instance.hasIssues,
      'has_projects': instance.hasProjects,
      'has_downloads': instance.hasDownloads,
      'has_wiki': instance.hasWiki,
      'has_pages': instance.hasPages,
      'owner': instance.owner,
      'license': instance.license,
      'parent': instance.parent,
      'permissions': instance.permissions,
      'topics': instance.topics,
      'allIssueCount': instance.allIssueCount
    };
