// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitStats.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

CommitStats _$CommitStatsFromJson(Map<String, dynamic> json) => new CommitStats(
    json['total'] as int, json['additions'] as int, json['deletions'] as int);

abstract class _$CommitStatsSerializerMixin {
  int get total;
  int get additions;
  int get deletions;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'total': total,
        'additions': additions,
        'deletions': deletions
      };
}
