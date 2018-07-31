// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Release.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Release _$ReleaseFromJson(Map<String, dynamic> json) => new Release(
    json['id'] as String,
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
        : new User.fromJson(json['author'] as Map<String, dynamic>),
    (json['assets'] as List)
        ?.map((e) => e == null
            ? null
            : new ReleaseAsset.fromJson(e as Map<String, dynamic>))
        ?.toList());

abstract class _$ReleaseSerializerMixin {
  String get id;
  String get tagName;
  String get targetCommitish;
  String get name;
  String get body;
  String get bodyHtml;
  String get tarballUrl;
  String get zipballUrl;
  bool get draft;
  bool get preRelease;
  DateTime get createdAt;
  DateTime get publishedAt;
  User get author;
  List<ReleaseAsset> get assets;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'tag_name': tagName,
        'target_commitish': targetCommitish,
        'name': name,
        'body': body,
        'body_html': bodyHtml,
        'tarball_url': tarballUrl,
        'zipball_url': zipballUrl,
        'draft': draft,
        'prerelease': preRelease,
        'created_at': createdAt?.toIso8601String(),
        'published_at': publishedAt?.toIso8601String(),
        'author': author,
        'assets': assets
      };
}
