// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitStats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitStats _$CommitStatsFromJson(Map<String, dynamic> json) => CommitStats(
      (json['total'] as num?)?.toInt(),
      (json['additions'] as num?)?.toInt(),
      (json['deletions'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CommitStatsToJson(CommitStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'additions': instance.additions,
      'deletions': instance.deletions,
    };
