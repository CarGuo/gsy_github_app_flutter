// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Repository.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Repository _$RepositoryFromJson(Map<String, dynamic> json) => new Repository(
    json['id'] as int,
    json['size'] as int,
    json['name'] as String,
    json['full_name'] as String,
    json['html_url'] as String,
    json['description'] as String,
    json['language'] as String,
    json['license'] == null
        ? null
        : new License.fromJson(json['license'] as Map<String, dynamic>),
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
        : new User.fromJson(json['owner'] as Map<String, dynamic>),
    json['parent'] == null
        ? null
        : new Repository.fromJson(json['parent'] as Map<String, dynamic>),
    json['permissions'] == null
        ? null
        : new RepositoryPermissions.fromJson(
            json['permissions'] as Map<String, dynamic>),
    (json['topics'] as List)?.map((e) => e as String)?.toList())
  ..allIssueCount = json['allIssueCount'] as int;

abstract class _$RepositorySerializerMixin {
  int get id;
  int get size;
  String get name;
  String get fullName;
  String get htmlUrl;
  String get description;
  String get language;
  String get defaultBranch;
  DateTime get createdAt;
  DateTime get updatedAt;
  DateTime get pushedAt;
  String get gitUrl;
  String get sshUrl;
  String get cloneUrl;
  String get svnUrl;
  int get stargazersCount;
  int get watchersCount;
  int get forksCount;
  int get openIssuesCount;
  int get subscribersCount;
  bool get private;
  bool get fork;
  bool get hasIssues;
  bool get hasProjects;
  bool get hasDownloads;
  bool get hasWiki;
  bool get hasPages;
  User get owner;
  License get license;
  Repository get parent;
  RepositoryPermissions get permissions;
  List<String> get topics;
  int get allIssueCount;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'size': size,
        'name': name,
        'full_name': fullName,
        'html_url': htmlUrl,
        'description': description,
        'language': language,
        'default_branch': defaultBranch,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'pushed_at': pushedAt?.toIso8601String(),
        'git_url': gitUrl,
        'ssh_url': sshUrl,
        'clone_url': cloneUrl,
        'svn_url': svnUrl,
        'stargazers_count': stargazersCount,
        'watchers_count': watchersCount,
        'forks_count': forksCount,
        'open_issues_count': openIssuesCount,
        'subscribers_count': subscribersCount,
        'private': private,
        'fork': fork,
        'has_issues': hasIssues,
        'has_projects': hasProjects,
        'has_downloads': hasDownloads,
        'has_wiki': hasWiki,
        'has_pages': hasPages,
        'owner': owner,
        'license': license,
        'parent': parent,
        'permissions': permissions,
        'topics': topics,
        'allIssueCount': allIssueCount
      };
}
