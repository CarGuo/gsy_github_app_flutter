// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EventPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventPayload _$EventPayloadFromJson(Map<String, dynamic> json) {
  return EventPayload()
    ..pushId = json['push_id'] as int
    ..size = json['size'] as int
    ..distinctSize = json['distinct_size'] as int
    ..ref = json['ref'] as String
    ..head = json['head'] as String
    ..before = json['before'] as String
    ..commits = (json['commits'] as List)
        ?.map((e) => e == null
            ? null
            : PushEventCommit.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..action = json['action'] as String
    ..refType = json['ref_type'] as String
    ..masterBranch = json['master_branch'] as String
    ..description = json['description'] as String
    ..pusherType = json['pusher_type'] as String
    ..release = json['release'] == null
        ? null
        : Release.fromJson(json['release'] as Map<String, dynamic>)
    ..issue = json['issue'] == null
        ? null
        : Issue.fromJson(json['issue'] as Map<String, dynamic>)
    ..comment = json['comment'] == null
        ? null
        : IssueEvent.fromJson(json['comment'] as Map<String, dynamic>);
}

Map<String, dynamic> _$EventPayloadToJson(EventPayload instance) =>
    <String, dynamic>{
      'push_id': instance.pushId,
      'size': instance.size,
      'distinct_size': instance.distinctSize,
      'ref': instance.ref,
      'head': instance.head,
      'before': instance.before,
      'commits': instance.commits,
      'action': instance.action,
      'ref_type': instance.refType,
      'master_branch': instance.masterBranch,
      'description': instance.description,
      'pusher_type': instance.pusherType,
      'release': instance.release,
      'issue': instance.issue,
      'comment': instance.comment
    };
