// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitGitUser.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

CommitGitUser _$CommitGitUserFromJson(Map<String, dynamic> json) =>
    new CommitGitUser(json['name'] as String, json['email'] as String,
        json['date'] == null ? null : DateTime.parse(json['date'] as String));

abstract class _$CommitGitUserSerializerMixin {
  String get name;
  String get email;
  DateTime get date;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'date': date?.toIso8601String()
      };
}
