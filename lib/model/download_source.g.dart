// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadSource _$DownloadSourceFromJson(Map<String, dynamic> json) =>
    DownloadSource(
      json['url'] as String?,
      json['isSourceCode'] as bool?,
      json['name'] as String?,
      (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DownloadSourceToJson(DownloadSource instance) =>
    <String, dynamic>{
      'url': instance.url,
      'isSourceCode': instance.isSourceCode,
      'name': instance.name,
      'size': instance.size,
    };
