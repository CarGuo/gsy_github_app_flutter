import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'ReleaseAsset.g.dart';

@JsonSerializable()
class ReleaseAsset {
  int? id;
  String? name;
  String? label;
  User? uploader;
  @JsonKey(name: "content_type")
  String? contentType;
  String? state;
  int? size;
  int? downloadCout;
  @JsonKey(name: "created_at")
  DateTime? createdAt;
  @JsonKey(name: "updated_at")
  DateTime? updatedAt;
  @JsonKey(name: "browser_download_url")
  String? downloadUrl;

  ReleaseAsset(
    this.id,
    this.name,
    this.label,
    this.uploader,
    this.contentType,
    this.state,
    this.size,
    this.downloadCout,
    this.createdAt,
    this.updatedAt,
    this.downloadUrl,
  );

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => _$ReleaseAssetFromJson(json);
  Map<String, dynamic> toJson() => _$ReleaseAssetToJson(this);
}
