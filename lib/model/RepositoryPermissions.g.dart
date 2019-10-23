// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RepositoryPermissions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepositoryPermissions _$RepositoryPermissionsFromJson(
    Map<String, dynamic> json) {
  return RepositoryPermissions(
      json['admin'] as bool, json['push'] as bool, json['pull'] as bool);
}

Map<String, dynamic> _$RepositoryPermissionsToJson(
        RepositoryPermissions instance) =>
    <String, dynamic>{
      'admin': instance.admin,
      'push': instance.push,
      'pull': instance.pull
    };
