import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'Branch.g.dart';

@JsonSerializable()
class Branch {
  String name;
  String tarballUrl;
  @JsonKey(name: "zipball_url")
  String zipballUrl;
  @JsonKey(name: "tarball_url")

  bool isBranch = true;

  Branch(this.name, this.isBranch, this.tarballUrl, this.zipballUrl);

  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);

  Map<String, dynamic> toJson() => _$BranchToJson(this);
}
