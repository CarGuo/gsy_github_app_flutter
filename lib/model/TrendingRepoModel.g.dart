// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TrendingRepoModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrendingRepoModel _$TrendingRepoModelFromJson(Map<String, dynamic> json) {
  return TrendingRepoModel(
      json['fullName'] as String,
      json['url'] as String,
      json['description'] as String,
      json['language'] as String,
      json['meta'] as String,
      (json['contributors'] as List)?.map((e) => e as String)?.toList(),
      json['contributorsUrl'] as String,
      json['starCount'] as String,
      json['name'] as String,
      json['reposName'] as String,
      json['forkCount'] as String);
}

Map<String, dynamic> _$TrendingRepoModelToJson(TrendingRepoModel instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'url': instance.url,
      'description': instance.description,
      'language': instance.language,
      'meta': instance.meta,
      'contributors': instance.contributors,
      'contributorsUrl': instance.contributorsUrl,
      'starCount': instance.starCount,
      'forkCount': instance.forkCount,
      'name': instance.name,
      'reposName': instance.reposName
    };
