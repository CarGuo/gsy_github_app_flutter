import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/issue_event.dart';
import 'package:gsy_github_app_flutter/model/push_event_commit.dart';
import 'package:gsy_github_app_flutter/model/release.dart';
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'event_payload.g.dart';

@JsonSerializable()
class EventPayload {

  @JsonKey(name: "push_id")
  int? pushId;
  int? size;
  @JsonKey(name: "distinct_size")
  int? distinctSize;
  String? ref;
  String? head;
  String? before;
  List<PushEventCommit>? commits;

  String? action;
  @JsonKey(name: "ref_type")
  String? refType;
  @JsonKey(name: "master_branch")
  String? masterBranch;
  String? description;
  @JsonKey(name: "pusher_type")
  String? pusherType;

  Release? release;
  Issue? issue;
  IssueEvent? comment;

  /// DiscussionEvent / DiscussionCommentEvent 的 payload.discussion。
  ///
  /// 只解析路由跳转最小需要的字段（`number`），title / body / user 一律
  /// 走 [readDiscussion](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart)
  /// GraphQL 单独拉，避免 events 列表阶段把 payload 塞得过大。
  EventDiscussionRef? discussion;

  /// SecurityAdvisoryEvent 的 payload.security_advisory。
  ///
  /// GitHub 全站级安全公告事件（repo 常为 null）。只承载首页动态里
  /// 展示需要的核心字段：GHSA id、CVE id、severity、summary。完整
  /// vulnerabilities / references 走详情页 GraphQL 或 REST 单拉。
  @JsonKey(name: "security_advisory")
  EventSecurityAdvisoryRef? securityAdvisory;

  EventPayload();

  factory EventPayload.fromJson(Map<String, dynamic> json) => _$EventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$EventPayloadToJson(this);
}

/// 事件 payload 里嵌套的 discussion 引用。
///
/// 仅承载路由必需字段。完整 discussion 展示走 GraphQL。
@JsonSerializable()
class EventDiscussionRef {
  int? number;

  EventDiscussionRef();

  factory EventDiscussionRef.fromJson(Map<String, dynamic> json) =>
      _$EventDiscussionRefFromJson(json);

  Map<String, dynamic> toJson() => _$EventDiscussionRefToJson(this);
}

/// 事件 payload 里嵌套的 security advisory 引用。
///
/// 参考 GitHub Events API `SecurityAdvisoryEvent.payload.security_advisory`。
/// severity 官方枚举：`low` / `moderate` / `high` / `critical`。
@JsonSerializable()
class EventSecurityAdvisoryRef {
  @JsonKey(name: "ghsa_id")
  String? ghsaId;
  @JsonKey(name: "cve_id")
  String? cveId;
  String? severity;
  String? summary;

  EventSecurityAdvisoryRef();

  factory EventSecurityAdvisoryRef.fromJson(Map<String, dynamic> json) =>
      _$EventSecurityAdvisoryRefFromJson(json);

  Map<String, dynamic> toJson() => _$EventSecurityAdvisoryRefToJson(this);
}
