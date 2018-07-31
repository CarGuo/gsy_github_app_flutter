// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommitGitInfo.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

CommitGitInfo _$CommitGitInfoFromJson(Map<String, dynamic> json) =>
    new CommitGitInfo(
        json['message'] as String,
        json['url'] as String,
        json['comment_count'] as int,
        json['author'] == null
            ? null
            : new CommitGitUser.fromJson(
                json['author'] as Map<String, dynamic>),
        json['committer'] == null
            ? null
            : new CommitGitUser.fromJson(
                json['committer'] as Map<String, dynamic>));

abstract class _$CommitGitInfoSerializerMixin {
  String get message;
  String get url;
  int get commentCount;
  CommitGitUser get author;
  CommitGitUser get committer;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'message': message,
        'url': url,
        'comment_count': commentCount,
        'author': author,
        'committer': committer
      };
}
