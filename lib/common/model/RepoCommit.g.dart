// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RepoCommit.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

RepoCommit _$RepoCommitFromJson(Map<String, dynamic> json) => new RepoCommit(
    json['sha'] as String,
    json['url'] as String,
    json['html_url'] as String,
    json['comments_url'] as String,
    json['commit'] == null
        ? null
        : new CommitGitInfo.fromJson(json['commit'] as Map<String, dynamic>),
    json['author'] == null
        ? null
        : new User.fromJson(json['author'] as Map<String, dynamic>),
    json['committer'] == null
        ? null
        : new User.fromJson(json['committer'] as Map<String, dynamic>),
    (json['parents'] as List)
        ?.map((e) => e == null
            ? null
            : new RepoCommit.fromJson(e as Map<String, dynamic>))
        ?.toList());

abstract class _$RepoCommitSerializerMixin {
  String get sha;
  String get url;
  String get htmlUrl;
  String get commentsUrl;
  CommitGitInfo get commit;
  User get author;
  User get committer;
  List<RepoCommit> get parents;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'sha': sha,
        'url': url,
        'html_url': htmlUrl,
        'comments_url': commentsUrl,
        'commit': commit,
        'author': author,
        'committer': committer,
        'parents': parents
      };
}
