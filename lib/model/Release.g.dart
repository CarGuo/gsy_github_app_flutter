// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Release _$ReleaseFromJson(Map<String, dynamic> json) {
  return Release(
      json['id'] as int,
      json['tag_name'] as String,
      json['target_commitish'] as String,
      json['name'] as String,
      json['body'] as String,
      json['body_html'] as String,
      json['tarball_url'] as String,
      json['zipball_url'] as String,
      json['draft'] as bool,
      json['prerelease'] as bool,
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
      (json['assets'] as List)
          ?.map((e) => e == null
              ? null
              : ReleaseAsset.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$ReleaseToJson(Release instance) => <String, dynamic>{
      'id': instance.id,
      'tag_name': instance.tagName,
      'target_commitish': instance.targetCommitish,
      'name': instance.name,
      'body': instance.body,
      'body_html': instance.bodyHtml,
      'tarball_url': instance.tarballUrl,
      'zipball_url': instance.zipballUrl,
      'draft': instance.draft,
      'prerelease': instance.preRelease,
      'created_at': instance.createdAt?.toIso8601String(),
      'published_at': instance.publishedAt?.toIso8601String(),
      'author': instance.author,
      'assets': instance.assets
    };
