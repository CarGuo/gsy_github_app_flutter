import 'package:gsy_github_app_flutter/model/CommitFile.dart';
import 'package:json_annotation/json_annotation.dart';

import 'RepoCommit.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'CommitsComparison.g.dart';

@JsonSerializable()
class CommitsComparison{
  String? url;
  @JsonKey(name: "html_url")
  String? htmlUrl;
  @JsonKey(name: "base_commit")
  RepoCommit? baseCommit;
  @JsonKey(name: "merge_base_commit")
  RepoCommit? mergeBaseCommit;
  String? status;
  @JsonKey(name: "total_commits")
  int? totalCommits;
  List<RepoCommit>? commits;
  List<CommitFile>? files;

  CommitsComparison(
    this.url,
    this.htmlUrl,
    this.baseCommit,
    this.mergeBaseCommit,
    this.status,
    this.totalCommits,
    this.commits,
    this.files,
  );

  factory CommitsComparison.fromJson(Map<String, dynamic> json) => _$CommitsComparisonFromJson(json);

  Map<String, dynamic> toJson() => _$CommitsComparisonToJson(this);
}
