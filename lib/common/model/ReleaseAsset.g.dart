// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ReleaseAsset.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

ReleaseAsset _$ReleaseAssetFromJson(Map<String, dynamic> json) =>
    new ReleaseAsset(
        json['id'] as String,
        json['name'] as String,
        json['label'] as String,
        json['uploader'] == null
            ? null
            : new User.fromJson(json['uploader'] as Map<String, dynamic>),
        json['content_type'] as String,
        json['state'] as String,
        json['size'] as int,
        json['downloadCout'] as int,
        json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
        json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
        json['browser_download_url'] as String);

abstract class _$ReleaseAssetSerializerMixin {
  String get id;
  String get name;
  String get label;
  User get uploader;
  String get contentType;
  String get state;
  int get size;
  int get downloadCout;
  DateTime get createdAt;
  DateTime get updatedAt;
  String get downloadUrl;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'label': label,
        'uploader': uploader,
        'content_type': contentType,
        'state': state,
        'size': size,
        'downloadCout': downloadCout,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'browser_download_url': downloadUrl
      };
}
