// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TrendingRepoModel.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

TrendingRepoModel _$TrendingRepoModelFromJson(Map<String, dynamic> json) =>
    new TrendingRepoModel(
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

abstract class _$TrendingRepoModelSerializerMixin {
  String get fullName;
  String get url;
  String get description;
  String get language;
  String get meta;
  List<String> get contributors;
  String get contributorsUrl;
  String get starCount;
  String get forkCount;
  String get name;
  String get reposName;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'fullName': fullName,
        'url': url,
        'description': description,
        'language': language,
        'meta': meta,
        'contributors': contributors,
        'contributorsUrl': contributorsUrl,
        'starCount': starCount,
        'forkCount': forkCount,
        'name': name,
        'reposName': reposName
      };
}
