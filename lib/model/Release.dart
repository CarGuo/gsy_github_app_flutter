import 'package:gsy_github_app_flutter/model/ReleaseAsset.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'Release.g.dart';

@JsonSerializable()
class Release {
  int? id;
  @JsonKey(name: "tag_name")
  String? tagName;
  @JsonKey(name: "target_commitish")
  String? targetCommitish;
  String? name;
  String? body;
  @JsonKey(name: "body_html")
  String? bodyHtml;
  @JsonKey(name: "tarball_url")
  String? tarballUrl;
  @JsonKey(name: "zipball_url")
  String? zipballUrl;

  bool? draft;
  @JsonKey(name: "prerelease")
  bool? preRelease;
  @JsonKey(name: "created_at")
  DateTime? createdAt;
  @JsonKey(name: "published_at")
  DateTime? publishedAt;

  User? author;
  List<ReleaseAsset>? assets;

  Release(
    this.id,
    this.tagName,
    this.targetCommitish,
    this.name,
    this.body,
    this.bodyHtml,
    this.tarballUrl,
    this.zipballUrl,
    this.draft,
    this.preRelease,
    this.createdAt,
    this.publishedAt,
    this.author,
    this.assets,
  );

  factory Release.fromJson(Map<String, dynamic> json) =>
      _$ReleaseFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseToJson(this);
}
