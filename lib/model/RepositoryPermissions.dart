import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'RepositoryPermissions.g.dart';

@JsonSerializable()
class RepositoryPermissions {
  bool? admin;
  bool? push;
  bool? pull;

  RepositoryPermissions(
    this.admin,
    this.push,
    this.pull,
  );

  factory RepositoryPermissions.fromJson(Map<String, dynamic> json) => _$RepositoryPermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$RepositoryPermissionsToJson(this);
}
