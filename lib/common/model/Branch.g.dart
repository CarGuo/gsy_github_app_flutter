// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Branch.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Branch _$BranchFromJson(Map<String, dynamic> json) => new Branch(
    json['name'] as String,
    json['tarball_url'] as bool,
    json['tarballUrl'] as String,
    json['zipball_url'] as String);

abstract class _$BranchSerializerMixin {
  String get name;
  String get tarballUrl;
  String get zipballUrl;
  bool get isBranch;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'tarballUrl': tarballUrl,
        'zipball_url': zipballUrl,
        'tarball_url': isBranch
      };
}
