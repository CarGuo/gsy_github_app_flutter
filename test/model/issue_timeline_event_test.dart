import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';

void main() {
  group('IssueTimelineEvent.fromJson - 基础事件', () {
    test('labeled 保留 label 名字', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'labeled',
        'actor': {'login': 'alice'},
        'created_at': '2026-07-01T10:00:00Z',
        'label': {'name': 'bug', 'color': 'ff0000'},
      });
      expect(e.event, 'labeled');
      expect(e.actor?.login, 'alice');
      expect(e.label?.name, 'bug');
      expect(e.body, isNull);
    });

    test('renamed 拆解 from / to', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'renamed',
        'rename': {'from': 'old', 'to': 'new'},
      });
      expect(e.renameFrom, 'old');
      expect(e.renameTo, 'new');
    });

    test('cross-referenced 抽取 source.issue', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'cross-referenced',
        'source': {
          'issue': {
            'html_url': 'https://github.com/a/b/issues/1',
            'title': 'linked issue',
            'state': 'open',
          },
        },
      });
      expect(e.sourceUrl, 'https://github.com/a/b/issues/1');
      expect(e.sourceTitle, 'linked issue');
      expect(e.sourceState, 'open');
    });
  });

  group('IssueTimelineEvent.fromJson - reviewed 事件', () {
    test('reviewed/approved 保留 state 且 body 非 null', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'reviewed',
        'state': 'approved',
        'user': {'login': 'bob'},
        'submitted_at': '2026-07-01T10:00:00Z',
        'body': 'LGTM',
        'author_association': 'MEMBER',
      });
      expect(e.event, 'reviewed');
      expect(e.reviewState, 'approved');
      expect(e.actor?.login, 'bob');
      expect(e.body, 'LGTM');
      expect(e.authorAssociation, 'MEMBER');
      expect(e.createdAt, isNotNull);
    });

    test('reviewed/changes_requested 保留长 body', () {
      final longBody = 'Please refactor this section and add tests. ' * 10;
      final e = IssueTimelineEvent.fromJson({
        'event': 'reviewed',
        'state': 'changes_requested',
        'user': {'login': 'carol'},
        'submitted_at': '2026-07-01T10:00:00Z',
        'body': longBody,
      });
      expect(e.reviewState, 'changes_requested');
      expect(e.body, longBody);
    });

    test('reviewed 无 body 时保持 null 而非空串', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'reviewed',
        'state': 'commented',
        'user': {'login': 'dave'},
        'submitted_at': '2026-07-01T10:00:00Z',
      });
      expect(e.body, isNull);
    });

    test('reviewed 用 submitted_at 兜底 created_at', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'reviewed',
        'state': 'approved',
        'submitted_at': '2026-07-01T10:00:00Z',
      });
      expect(e.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));
    });
  });

  group('IssueTimelineEvent.fromJson - review_requested / removed', () {
    test('review_requested 从 requested_reviewer 取 login', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'review_requested',
        'actor': {'login': 'author'},
        'requested_reviewer': {'login': 'reviewer1'},
      });
      expect(e.reviewerName, 'reviewer1');
    });

    test('review_requested 回退到 requested_team.name', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'review_requested',
        'actor': {'login': 'author'},
        'requested_team': {'name': 'core-team'},
      });
      expect(e.reviewerName, 'core-team');
    });

    test('review_requested 两者皆缺时 reviewerName 为 null', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'review_requested',
        'actor': {'login': 'author'},
      });
      expect(e.reviewerName, isNull);
    });

    test('review_request_removed 走同一 reviewer 解析', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'review_request_removed',
        'actor': {'login': 'author'},
        'requested_reviewer': {'login': 'reviewer2'},
      });
      expect(e.reviewerName, 'reviewer2');
    });
  });

  group('IssueTimelineEvent.fromJson - PR 分支/合并事件', () {
    test('head_ref_force_pushed 只保留基础字段', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'head_ref_force_pushed',
        'actor': {'login': 'author'},
        'created_at': '2026-07-01T10:00:00Z',
      });
      expect(e.event, 'head_ref_force_pushed');
      expect(e.actor?.login, 'author');
      expect(e.body, isNull);
      expect(e.reviewState, isNull);
    });

    test('base_ref_changed 不误读 body', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'base_ref_changed',
        'actor': {'login': 'author'},
        'body': '这个字段应被忽略',
      });
      expect(e.body, isNull);
    });

    test('auto_merge_enabled 不误读 authorAssociation', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'auto_merge_enabled',
        'actor': {'login': 'author'},
        'author_association': 'CONTRIBUTOR',
      });
      expect(e.authorAssociation, isNull);
    });

    test('ready_for_review / convert_to_draft 基础字段', () {
      final e1 = IssueTimelineEvent.fromJson({
        'event': 'ready_for_review',
        'actor': {'login': 'author'},
      });
      expect(e1.event, 'ready_for_review');

      final e2 = IssueTimelineEvent.fromJson({
        'event': 'convert_to_draft',
        'actor': {'login': 'author'},
      });
      expect(e2.event, 'convert_to_draft');
    });
  });

  group('IssueTimelineEvent.fromJson - commented 事件', () {
    test('commented 保留 body / commentId / authorAssociation', () {
      final e = IssueTimelineEvent.fromJson({
        'id': 123456,
        'event': 'commented',
        'user': {'login': 'commenter'},
        'body': 'hello',
        'author_association': 'COLLABORATOR',
        'created_at': '2026-07-01T10:00:00Z',
      });
      expect(e.isCommented, isTrue);
      expect(e.commentId, 123456);
      expect(e.body, 'hello');
      expect(e.authorAssociation, 'COLLABORATOR');
    });

    test('非 commented 事件 commentId 为 null 即使 json.id 存在', () {
      final e = IssueTimelineEvent.fromJson({
        'id': 999,
        'event': 'labeled',
        'label': {'name': 'x', 'color': '000000'},
      });
      expect(e.id, 999);
      expect(e.commentId, isNull);
    });
  });

  group('IssueTimelineEvent.fromJson - committed 事件', () {
    test('committed 事件 event=committed 时解析 sha/message/author', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'committed',
        'sha': '9b6cafcb2ff003874f7de61cbd1e03ca415349c1',
        'message':
            'Add NDK arm64 filter and legacy packaging config for Android release APK size reduction',
        'author': {
          'name': 'copilot-swe-agent[bot]',
          'date': '2026-07-01T10:00:00Z',
        },
        'html_url':
            'https://github.com/CarGuo/gsy_github_app_flutter/pull/938/commits/9b6cafcb2ff003874f7de61cbd1e03ca415349c1',
      });
      expect(e.event, 'committed');
      expect(e.commitSha, '9b6cafcb2ff003874f7de61cbd1e03ca415349c1');
      expect(e.commitShortSha, '9b6cafc');
      expect(
          e.commitMessage,
          'Add NDK arm64 filter and legacy packaging config for Android release APK size reduction');
      expect(e.commitAuthorName, 'copilot-swe-agent[bot]');
      expect(e.sourceUrl, contains('/commits/9b6cafcb'));
      expect(e.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));
      // actor 缺失时 UI 由 build() 用 commitAuthorName 兜底
      expect(e.actor, isNull);
    });

    test('committed 事件 event 缺失但顶层带 sha 也能推断出 committed', () {
      final e = IssueTimelineEvent.fromJson({
        'sha': 'abcdefabcdef1234567890abcdef12345678abcd',
        'message': 'first line\n\nbody line',
        'author': {'name': 'someone'},
      });
      expect(e.event, 'committed');
      expect(e.commitShortSha, 'abcdefa');
      expect(e.commitMessage, 'first line',
          reason: 'commit message 应只保留首行');
    });

    test('committed 事件 message 为空字符串时 commitMessage 为 null', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'committed',
        'sha': '1234567890abcdef1234567890abcdef12345678',
        'message': '',
        'author': {'name': 'x'},
      });
      expect(e.event, 'committed');
      expect(e.commitSha, '1234567890abcdef1234567890abcdef12345678');
      expect(e.commitMessage, isNull);
    });

    test('committed 事件多行 message 只取首行且 trim', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'committed',
        'sha': '1234567890abcdef1234567890abcdef12345678',
        'message': '  headline text  \n\nCo-authored-by: Bot <bot@example.com>',
        'author': {'name': 'x'},
      });
      expect(e.commitMessage, 'headline text');
    });

    test('committed 事件 author.name 为空字符串时 commitAuthorName 应为 null', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'committed',
        'sha': '1234567890abcdef1234567890abcdef12345678',
        'message': 'msg',
        'author': {'name': ''},
      });
      expect(e.event, 'committed');
      expect(e.commitAuthorName, isNull,
          reason: '空 name 字符串不应变成 commitAuthorName，让 UI 走 actor 或 --- 兜底');
    });
  });

  group('IssueTimelineEvent.fromJson - Copilot 事件', () {
    test('copilot_work_started 事件解析 event 和 actor', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'copilot_work_started',
        'actor': {'login': 'copilot-swe-agent[bot]', 'type': 'Bot'},
        'created_at': '2026-07-01T10:00:00Z',
      });
      expect(e.event, 'copilot_work_started');
      expect(e.actor?.login, 'copilot-swe-agent[bot]');
      expect(e.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));
    });

    test('copilot_work_finished 事件解析 event 和 actor', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'copilot_work_finished',
        'actor': {'login': 'copilot-swe-agent[bot]', 'type': 'Bot'},
        'created_at': '2026-07-01T11:00:00Z',
      });
      expect(e.event, 'copilot_work_finished');
      expect(e.actor?.login, 'copilot-swe-agent[bot]');
    });

    test('copilot 事件 body/authorAssociation 应保持 null，不被 payload 污染', () {
      // reviewer 建议 #5：copilot 事件不在 body/reviewed 白名单里，
      // 即使 payload 恶意/意外带上 body，也不应该被读进模型
      final e = IssueTimelineEvent.fromJson({
        'event': 'copilot_work_started',
        'actor': {'login': 'copilot-swe-agent[bot]', 'type': 'Bot'},
        'body': 'this should be ignored',
        'body_html': '<p>ignored</p>',
        'author_association': 'BOT',
      });
      expect(e.body, isNull,
          reason: 'body 只对 commented/reviewed 生效，不应污染其它事件');
      expect(e.bodyHtml, isNull);
      expect(e.authorAssociation, isNull);
    });
  });

  group('IssueTimelineEvent.fromJson - 健壮性', () {
    test('缺失所有字段不 crash', () {
      final e = IssueTimelineEvent.fromJson(<String, dynamic>{});
      expect(e.event, isNull);
      expect(e.actor, isNull);
      expect(e.createdAt, isNull);
    });

    test('未知 event 也能构造，raw 保留原 payload', () {
      final e = IssueTimelineEvent.fromJson({
        'event': 'added_to_merge_queue',
        'actor': {'login': 'x'},
      });
      expect(e.event, 'added_to_merge_queue');
      expect(e.raw['event'], 'added_to_merge_queue');
    });
  });
}
