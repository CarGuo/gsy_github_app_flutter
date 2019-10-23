// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitStats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitStats _$CommitStatsFromJson(Map<String, dynamic> json) {
  return CommitStats(
      json['total'] as int, json['additions'] as int, json['deletions'] as int);
}

Map<String, dynamic> _$CommitStatsToJson(CommitStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'additions': instance.additions,
      'deletions': instance.deletions
    };
