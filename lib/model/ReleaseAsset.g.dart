// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ReleaseAsset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseAsset _$ReleaseAssetFromJson(Map<String, dynamic> json) {
  return ReleaseAsset(
      json['id'] as int,
      json['name'] as String,
      json['label'] as String,
      json['uploader'] == null
          ? null
          : User.fromJson(json['uploader'] as Map<String, dynamic>),
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
}

Map<String, dynamic> _$ReleaseAssetToJson(ReleaseAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'label': instance.label,
      'uploader': instance.uploader,
      'content_type': instance.contentType,
      'state': instance.state,
      'size': instance.size,
      'downloadCout': instance.downloadCout,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'browser_download_url': instance.downloadUrl
    };
