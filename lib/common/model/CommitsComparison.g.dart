// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitsComparison.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

CommitsComparison _$CommitsComparisonFromJson(Map<String, dynamic> json) =>
    new CommitsComparison(
        json['url'] as String,
        json['html_url'] as String,
        json['base_commit'] == null
            ? null
            : new RepoCommit.fromJson(
                json['base_commit'] as Map<String, dynamic>),
        json['merge_base_commit'] == null
            ? null
            : new RepoCommit.fromJson(
                json['merge_base_commit'] as Map<String, dynamic>),
        json['status'] as String,
        json['total_commits'] as int,
        (json['commits'] as List)
            ?.map((e) => e == null
                ? null
                : new RepoCommit.fromJson(e as Map<String, dynamic>))
            ?.toList(),
        (json['files'] as List)
            ?.map((e) => e == null
                ? null
                : new CommitFile.fromJson(e as Map<String, dynamic>))
            ?.toList());

abstract class _$CommitsComparisonSerializerMixin {
  String get url;
  String get htmlUrl;
  RepoCommit get baseCommit;
  RepoCommit get mergeBaseCommit;
  String get status;
  int get totalCommits;
  List<RepoCommit> get commits;
  List<CommitFile> get files;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'html_url': htmlUrl,
        'base_commit': baseCommit,
        'merge_base_commit': mergeBaseCommit,
        'status': status,
        'total_commits': totalCommits,
        'commits': commits,
        'files': files
      };
}
