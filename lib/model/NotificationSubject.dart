import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'NotificationSubject.g.dart';

@JsonSerializable()
class NotificationSubject {
  String? title;
  String? url;
  String? type;

  NotificationSubject(this.title, this.url, this.type);

  factory NotificationSubject.fromJson(Map<String, dynamic> json) => _$NotificationSubjectFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSubjectToJson(this);
}
