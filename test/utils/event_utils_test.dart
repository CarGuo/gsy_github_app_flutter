import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/model/event.dart';

/// 事件描述测试：
/// - 覆盖 GitHub Events API 关键事件类型的多语言输出（zh 场景）
/// - 覆盖未识别事件的 [EventUtils.loggedUnknownEventTypes] 遥测
///
/// 与 [issue_timeline_item_test.dart] 平行；两个模块 event 命名完全不同，
/// 不要合并。Event 构造统一走 [Event.fromJson] 以模拟 API 真实 payload。

Widget _harness(void Function(BuildContext ctx) probe, {Locale locale = const Locale('zh')}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Builder(builder: (ctx) {
      probe(ctx);
      return const Scaffold(body: SizedBox.shrink());
    }),
  );
}

/// dart 字面量 `{...}` 默认为 `Map<dynamic, dynamic>`，
/// 而 `Event.fromJson` / 嵌套子对象的 `fromJson` 要求 `Map<String, dynamic>`，
/// 这里递归强转一次，避免每个用例反复 `<String, dynamic>` 打字面量类型。
Map<String, dynamic> _m(Map<String, Object?> raw) {
  Object? conv(Object? v) {
    if (v is Map) {
      return v.map<String, dynamic>(
        (k, vv) => MapEntry(k.toString(), conv(vv)),
      );
    }
    if (v is List) {
      return v.map(conv).toList();
    }
    return v;
  }
  return conv(raw) as Map<String, dynamic>;
}

void main() {
  setUp(() {
    EventUtils.resetUnknownEventLogForTest();
  });

  testWidgets('PushEvent → 中文文案 + 短 sha 描述', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PushEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy_github_app_flutter'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'ref': 'refs/heads/master',
        'head': 'abcdef1234567890',
        'commits': [
          {'sha': 'a1b2c3d4e5f6a1b2c3d4', 'message': 'fix: null-safe fork actor'}
        ]
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('推送'));
    expect(got.actionStr, contains('master'));
    expect(got.actionStr, contains('CarGuo/gsy_github_app_flutter'));
    expect(got.des, contains('a1b2c3d'));
    expect(got.des, contains('fix: null-safe fork actor'));
  });

  testWidgets('IssuesEvent → 中文 issue 文案', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'IssuesEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'opened',
        'issue': {'number': 42, 'title': '标题占位'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('打开'));
    expect(got.actionStr, contains('42'));
    expect(got.actionStr, contains('CarGuo/gsy'));
    expect(got.des, '标题占位');
  });

  testWidgets('ForkEvent → 缺 actor 时走 fork_repo 分支不崩', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'ForkEvent',
      'actor': null,
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, isNotNull);
    expect(got.actionStr, contains('CarGuo/gsy'));
  });

  testWidgets('未知事件 → actionStr 为空 + 登记到 loggedUnknownEventTypes',
      (tester) async {
    // SecurityAdvisoryEvent: webhook 里有，Events API 不 emit，属"文档滞后 + 尚未收编"
    // 一旦 GitHub 把它加进 events feed 且我们扩了 case，这个样本可以再换
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'SecurityAdvisoryEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, '');
    expect(
      EventUtils.loggedUnknownEventTypes.contains('SecurityAdvisoryEvent'),
      isTrue,
      reason: 'default 分支必须把未知事件类型登记到 debug-only 集合',
    );
  });

  testWidgets('DiscussionEvent + created → 走 event_dynamic_discussion 整句', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'DiscussionEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'created'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('讨论'));
    expect(got.actionStr, contains('CarGuo/gsy'));
    // action 走通用词典 → created 翻成"创建"
    expect(got.actionStr, contains('创建'));
    expect(
      EventUtils.loggedUnknownEventTypes.contains('DiscussionEvent'),
      isFalse,
      reason: 'DiscussionEvent 已收编，不应再进 unknown 遥测',
    );
  });

  testWidgets('DiscussionCommentEvent + answered → action 词典化为"标记回答"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'DiscussionCommentEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'answered'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('讨论评论'));
    expect(got.actionStr, contains('标记回答'),
        reason: 'answered 必须走 event_action_answered 词典，不允许英文透出');
    expect(got.actionStr, isNot(contains('answered')));
  });

  testWidgets('PullRequestReviewThreadEvent + resolved → PR 评审讨论串整句', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PullRequestReviewThreadEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'resolved'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('PR 评审讨论串'));
    expect(got.actionStr, contains('CarGuo/gsy'));
  });

  testWidgets('SponsorshipEvent → 独立整句，不含 repo（payload 里没有 repo 语义）', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'SponsorshipEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'created'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    // sponsorship 语义在账户维度，模板里没塞 repo 槽位
    expect(got.actionStr, contains('赞助'));
    expect(got.actionStr, contains('创建'));
  });

  testWidgets('通用 action category_changed → 词典化"变更分类"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'DiscussionEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'category_changed'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('变更分类'));
    expect(got.actionStr, isNot(contains('category_changed')),
        reason: 'category_changed 必须走 event_action_category_changed 词典');
  });

  testWidgets('未知事件同类型重复触发 → 只登记一次', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'WeirdEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {}
    }));

    await tester.pumpWidget(_harness((ctx) {
      EventUtils.getActionAndDes(ctx, ee);
      EventUtils.getActionAndDes(ctx, ee);
      EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(EventUtils.loggedUnknownEventTypes.length, 1);
    expect(EventUtils.loggedUnknownEventTypes.first, 'WeirdEvent');
  });

  testWidgets('l10n extension 可用性冒烟：context.l10n 非空', (tester) async {
    AppLocalizations? seen;
    await tester.pumpWidget(_harness((ctx) {
      seen = ctx.l10n;
    }));
    expect(seen, isNotNull);
  });

  testWidgets('WatchEvent + started → 走独立整句 key（zh：关注了 xxx）', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'WatchEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'started'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    // WatchEvent started 用独立整句 key，避免英语侧读成 "started xxx" 不通顺
    expect(got.actionStr, contains('关注了'));
    expect(got.actionStr, isNot(contains('started')),
        reason: 'WatchEvent started 分支必须走独立句，不允许英文透出');
    expect(got.actionStr, contains('CarGuo/gsy'));
  });

  testWidgets('WatchEvent + started → 英文 locale 走独立整句（Starred xxx）', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'WatchEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'started'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }, locale: const Locale('en')));

    // 英语侧文法完整：Starred CarGuo/gsy，而不是通用词典拼出的 "started CarGuo/gsy"
    expect(got.actionStr, contains('Starred'));
    expect(got.actionStr, contains('CarGuo/gsy'));
  });

  testWidgets('PullRequestEvent + synchronize → 翻译为"更新"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PullRequestEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'synchronize'}
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('更新'));
    expect(got.actionStr, isNot(contains('synchronize')));
  });

  testWidgets('PullRequestEvent + auto_merge_enabled → 词典化"启用自动合并"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PullRequestEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'auto_merge_enabled',
        'number': 42,
        'pull_request': {'title': 'chore: bump deps'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('启用自动合并'));
    expect(got.actionStr, isNot(contains('auto_merge_enabled')),
        reason: 'auto_merge_enabled 必须走 event_action_auto_merge_enabled 词典');
  });

  testWidgets('PullRequestEvent + auto_merge_disabled → 词典化"关闭自动合并"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PullRequestEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'auto_merge_disabled',
        'number': 42,
        'pull_request': {'title': 'chore: bump deps'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('关闭自动合并'));
    expect(got.actionStr, isNot(contains('auto_merge_disabled')),
        reason: 'auto_merge_disabled 必须走 event_action_auto_merge_disabled 词典');
  });

  // B/2: 补齐 5 个之前透传英文的冷 action 词条，覆盖 IssuesEvent 去重、
  // PullRequestEvent merge queue、DeploymentEvent 部署三类事件源。
  testWidgets('IssuesEvent + marked_as_duplicate → 词典化"标记为重复"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'IssuesEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'marked_as_duplicate',
        'issue': {'number': 42, 'title': 'dup issue'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('标记为重复'));
    expect(got.actionStr, isNot(contains('marked_as_duplicate')),
        reason: 'marked_as_duplicate 必须走 event_action_marked_as_duplicate 词典');
  });

  testWidgets('IssuesEvent + unmarked_as_duplicate → 词典化"取消重复标记"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'IssuesEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'unmarked_as_duplicate',
        'issue': {'number': 42, 'title': 'undup issue'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('取消重复标记'));
    expect(got.actionStr, isNot(contains('unmarked_as_duplicate')),
        reason: 'unmarked_as_duplicate 必须走 event_action_unmarked_as_duplicate 词典');
  });

  testWidgets('PullRequestEvent + enqueued → 词典化"加入合并队列"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PullRequestEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'enqueued',
        'number': 42,
        'pull_request': {'title': 'chore: bump deps'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('加入合并队列'));
    expect(got.actionStr, isNot(contains('enqueued')),
        reason: 'enqueued 必须走 event_action_enqueued 词典');
  });

  testWidgets('PullRequestEvent + dequeued → 词典化"移出合并队列"', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'PullRequestEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'dequeued',
        'number': 42,
        'pull_request': {'title': 'chore: bump deps'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    expect(got.actionStr, contains('移出合并队列'));
    expect(got.actionStr, isNot(contains('dequeued')),
        reason: 'dequeued 必须走 event_action_dequeued 词典');
  });

  testWidgets('DeploymentEvent + deployed → 词典化"已部署"', (tester) async {
    // DeploymentEvent 目前走 UnknownEvent 通用兜底，但 payload.action 已被
    // _translateAction 词典化。这里只断言词条命中，不依赖事件类型 UI 分支。
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'DeploymentEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'deployed',
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    // action 词典化：deployed 不透传到 actionStr / des 里
    final combined = '${got.actionStr ?? ''}|${got.des ?? ''}';
    expect(combined, isNot(contains('deployed')),
        reason: 'deployed 必须走 event_action_deployed 词典');
  });

  testWidgets('未知 action → 原样返回英文 + 遥测独立表登记', (tester) async {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'IssuesEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'brand_new_action_from_github',
        'issue': {'number': 1, 'title': 't'}
      }
    }));

    late ({String? actionStr, String? des}) got;
    await tester.pumpWidget(_harness((ctx) {
      got = EventUtils.getActionAndDes(ctx, ee);
    }));

    // 未识别 action 兜底原样透传，UI 不空白
    expect(got.actionStr, contains('brand_new_action_from_github'));
    // 遥测走独立表，避免和事件类型未知混在一起
    expect(
      EventUtils.loggedUnknownActions.contains('brand_new_action_from_github'),
      isTrue,
    );
    // 事件类型是 IssuesEvent（已识别），未知事件表里不应出现该 action
    expect(
      EventUtils.loggedUnknownEventTypes.any((e) => e.contains('brand_new_action')),
      isFalse,
    );
  });

  // roadmap §3.1 交互阶段：EventPayload.discussion 序列化契约。
  //
  // ActionUtils switch 在 DiscussionEvent / DiscussionCommentEvent 分支里
  // 读 event.payload?.discussion?.number 决定是走 goDiscussionDetail 还是回退
  // goReposDetail。这两个用例只锁 raw JSON → 模型的解析结果，
  // 跳转本身依赖 BuildContext + NavigatorUtils，无既有 mock 模式，暂不覆盖。
  test('EventPayload.discussion.number 从 raw json 正常解析出 int', () {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'DiscussionEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {
        'action': 'created',
        'discussion': {'number': 42, 'title': '不该被 EventPayload 读到'}
      }
    }));

    expect(ee.payload?.discussion?.number, 42);
  });

  test('EventPayload.discussion 缺失时保持 null，回退分支可用', () {
    final ee = Event.fromJson(_m({
      'id': 'x',
      'type': 'DiscussionEvent',
      'actor': {'login': 'alice'},
      'repo': {'name': 'CarGuo/gsy'},
      'org': null,
      'public': true,
      'created_at': '2026-01-01T00:00:00Z',
      'payload': {'action': 'created'}
    }));

    expect(ee.payload?.discussion, isNull);
  });
}
