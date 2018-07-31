// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EventPayload.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

EventPayload _$EventPayloadFromJson(Map<String, dynamic> json) =>
    new EventPayload()
      ..pushId = json['push_id'] as String
      ..size = json['size'] as int
      ..distinctSize = json['distinct_size'] as int
      ..ref = json['ref'] as String
      ..head = json['head'] as String
      ..before = json['before'] as String
      ..commits = (json['commits'] as List)
          ?.map((e) => e == null
              ? null
              : new PushEventCommit.fromJson(e as Map<String, dynamic>))
          ?.toList()
      ..action = json['action'] as String
      ..refType = json['ref_type'] as String
      ..masterBranch = json['master_branch'] as String
      ..description = json['description'] as String
      ..pusherType = json['pusher_type'] as String
      ..release = json['release'] == null
          ? null
          : new Release.fromJson(json['release'] as Map<String, dynamic>)
      ..issue = json['issue'] == null
          ? null
          : new Issue.fromJson(json['issue'] as Map<String, dynamic>)
      ..comment = json['comment'] == null
          ? null
          : new IssueEvent.fromJson(json['comment'] as Map<String, dynamic>);

abstract class _$EventPayloadSerializerMixin {
  String get pushId;
  int get size;
  int get distinctSize;
  String get ref;
  String get head;
  String get before;
  List<PushEventCommit> get commits;
  String get action;
  String get refType;
  String get masterBranch;
  String get description;
  String get pusherType;
  Release get release;
  Issue get issue;
  IssueEvent get comment;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'push_id': pushId,
        'size': size,
        'distinct_size': distinctSize,
        'ref': ref,
        'head': head,
        'before': before,
        'commits': commits,
        'action': action,
        'ref_type': refType,
        'master_branch': masterBranch,
        'description': description,
        'pusher_type': pusherType,
        'release': release,
        'issue': issue,
        'comment': comment
      };
}
