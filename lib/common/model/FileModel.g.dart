// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'FileModel.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

FileModel _$FileModelFromJson(Map<String, dynamic> json) => new FileModel(
    json['name'] as String,
    json['path'] as String,
    json['sha'] as String,
    json['size'] as int,
    json['url'] as String,
    json['html_url'] as String,
    json['git_url'] as String,
    json['download_url'] as String,
    json['type'] as String);

abstract class _$FileModelSerializerMixin {
  String get name;
  String get path;
  String get sha;
  int get size;
  String get url;
  String get htmlUrl;
  String get gitUrl;
  String get downloadUrl;
  String get type;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'path': path,
        'sha': sha,
        'size': size,
        'url': url,
        'html_url': htmlUrl,
        'git_url': gitUrl,
        'download_url': downloadUrl,
        'type': type
      };
}
