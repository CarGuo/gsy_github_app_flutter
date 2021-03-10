import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:json_annotation/json_annotation.dart';

import 'EventPayload.dart';
import 'Repository.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'Event.g.dart';

@JsonSerializable()
class Event {
  String? id;
  String? type;
  User? actor;
  Repository? repo;
  User? org;
  EventPayload? payload;
  @JsonKey(name: "public")
  bool? isPublic;
  @JsonKey(name: "created_at")
  DateTime? createdAt;

  Event(
    this.id,
    this.type,
    this.actor,
    this.repo,
    this.org,
    this.payload,
    this.isPublic,
    this.createdAt,
  );

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

}
