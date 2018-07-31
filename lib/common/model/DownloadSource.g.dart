// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DownloadSource.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

DownloadSource _$DownloadSourceFromJson(Map<String, dynamic> json) =>
    new DownloadSource(json['url'] as String, json['isSourceCode'] as bool,
        json['name'] as String, json['size'] as int);

abstract class _$DownloadSourceSerializerMixin {
  String get url;
  bool get isSourceCode;
  String get name;
  int get size;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'isSourceCode': isSourceCode,
        'name': name,
        'size': size
      };
}
