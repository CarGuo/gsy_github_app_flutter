// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Branch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Branch _$BranchFromJson(Map<String, dynamic> json) {
  return Branch(json['name'] as String, json['tarball_url'] as bool,
      json['tarballUrl'] as String, json['zipball_url'] as String);
}

Map<String, dynamic> _$BranchToJson(Branch instance) => <String, dynamic>{
      'name': instance.name,
      'tarballUrl': instance.tarballUrl,
      'zipball_url': instance.zipballUrl,
      'tarball_url': instance.isBranch
    };
