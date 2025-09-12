// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitFile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitFile _$CommitFileFromJson(Map<String, dynamic> json) => CommitFile(
  json['sha'] as String?,
  json['filename'] as String?,
  json['status'] as String?,
  (json['additions'] as num?)?.toInt(),
  (json['deletions'] as num?)?.toInt(),
  (json['changes'] as num?)?.toInt(),
  json['blob_url'] as String?,
  json['raw_url'] as String?,
  json['contents_url'] as String?,
  json['patch'] as String?,
);

Map<String, dynamic> _$CommitFileToJson(CommitFile instance) =>
    <String, dynamic>{
      'sha': instance.sha,
      'filename': instance.fileName,
      'status': instance.status,
      'additions': instance.additions,
      'deletions': instance.deletions,
      'changes': instance.changes,
      'blob_url': instance.blobUrl,
      'raw_url': instance.rawUrl,
      'contents_url': instance.contentsUrl,
      'patch': instance.patch,
    };
