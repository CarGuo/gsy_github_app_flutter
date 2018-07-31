// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitFile.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

CommitFile _$CommitFileFromJson(Map<String, dynamic> json) => new CommitFile(
    json['sha'] as String,
    json['filename'] as String,
    json['status'] as String,
    json['additions'] as int,
    json['deletions'] as int,
    json['changes'] as int,
    json['blob_url'] as String,
    json['raw_url'] as String,
    json['contents_url'] as String,
    json['patch'] as String);

abstract class _$CommitFileSerializerMixin {
  String get sha;
  String get fileName;
  String get status;
  int get additions;
  int get deletions;
  int get changes;
  String get blobUrl;
  String get rawUrl;
  String get contentsUrl;
  String get patch;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'sha': sha,
        'filename': fileName,
        'status': status,
        'additions': additions,
        'deletions': deletions,
        'changes': changes,
        'blob_url': blobUrl,
        'raw_url': rawUrl,
        'contents_url': contentsUrl,
        'patch': patch
      };
}
