// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RepositoryPermissions.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

RepositoryPermissions _$RepositoryPermissionsFromJson(
        Map<String, dynamic> json) =>
    new RepositoryPermissions(
        json['admin'] as bool, json['push'] as bool, json['pull'] as bool);

abstract class _$RepositoryPermissionsSerializerMixin {
  bool get admin;
  bool get push;
  bool get pull;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'admin': admin, 'push': push, 'pull': pull};
}
