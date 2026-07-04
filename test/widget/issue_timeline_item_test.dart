import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_timeline_item.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

User _user(String login) {
  final u = User.empty();
  u.login = login;
  return u;
}

GSYMarkdownWidget? _findBodyMarkdown(WidgetTester tester) {
  final finder = find.byType(GSYMarkdownWidget);
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<GSYMarkdownWidget>(finder);
}

void main() {
  // loggedUnknownEvents 是 static Set，跨测试进程共享。放到顶层 setUp 里清，
  // 避免未来在本文件顶部新增走 default 分支的测试导致隐蔽污染。
  setUp(() {
    IssueTimelineItem.resetUnknownEventLogForTest();
  });

  testWidgets('reviewed + approved + body 非空 → markdown 卡片渲染 body',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'approved',
      actor: _user('alice'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: 'LGTM 但请补一下注释',
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    final md = _findBodyMarkdown(tester);
    expect(md, isNotNull);
    expect(md!.markdownData, 'LGTM 但请补一下注释');
  });

  testWidgets('reviewed + changes_requested + 长 body → markdown 卡片渲染完整 body',
      (tester) async {
    final longBody = '这块请拆成两个方法，另外补一下 null 判断。' * 3;
    final event = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'changes_requested',
      actor: _user('bob'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: longBody,
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    final md = _findBodyMarkdown(tester);
    expect(md, isNotNull);
    expect(md!.markdownData, longBody);
  });

  testWidgets(
      'reviewed + markdown 语法 body → markdown 语法被解析而非以纯文本 Text 出现',
      (tester) async {
    const md = '## Pull request overview\n\n'
        'Reduces the released Android APK size by...\n\n'
        '**Changes:**\n'
        '- Restrict NDK ABI filters to `arm64-v8a`.';
    final event = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'commented',
      actor: _user('copilot'),
      createdAt: DateTime(2026, 4, 7, 10, 0),
      body: md,
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    final w = _findBodyMarkdown(tester);
    expect(w, isNotNull);
    expect(w!.markdownData, md);
    // 关键：markdown 原文中的 `##` `**` 若真被解析，就不会作为**纯 Text** 逐字出现。
    // 用 Markdown 一定会拆分成 RichText，所以匹配整段文本必失败；
    // 但被解析后的短 token（如 "## Pull request overview"、"**Changes:**"）
    // 也不会作为单个 Text 出现——这是能真正区分"传成 Text" vs "被 Markdown 解析"的断言。
    expect(find.text('## Pull request overview'), findsNothing);
    expect(find.text('**Changes:**'), findsNothing);
  });

  testWidgets('reviewed + body 首尾带空白 → markdown 传入前已被 trim',
      (tester) async {
    const rawBody = '  \n\n真正的评审意见\n\n  ';
    const trimmedBody = '真正的评审意见';
    final event = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'approved',
      actor: _user('trimmer'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: rawBody,
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    final w = _findBodyMarkdown(tester);
    expect(w, isNotNull);
    expect(w!.markdownData, trimmedBody);
  });

  testWidgets('reviewed + approved + body 为 null → 不显示 markdown 卡片',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'approved',
      actor: _user('carol'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: null,
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.byType(GSYMarkdownWidget), findsNothing);
  });

  testWidgets('reviewed + body 只有空白字符 → 不显示 markdown 卡片',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'commented',
      actor: _user('dave'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: '   \n\t  ',
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.byType(GSYMarkdownWidget), findsNothing);
  });

  testWidgets('非 reviewed 事件即使 body 非空也不显示 markdown 卡片',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'labeled',
      actor: _user('eve'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: '这个字段本不应存在',
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.byType(GSYMarkdownWidget), findsNothing);
  });

  testWidgets('空 body reviewed 与 labeled 事件渲染高度一致（不残留 markdown 卡片外壳）',
      (tester) async {
    final emptyReviewed = IssueTimelineEvent(
      event: 'reviewed',
      reviewState: 'approved',
      actor: _user('carol'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
      body: null,
    );
    final labeled = IssueTimelineEvent(
      event: 'labeled',
      actor: _user('carol'),
      createdAt: DateTime(2026, 7, 3, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(emptyReviewed)));
    await tester.pump();
    final emptyReviewedSize = tester.getSize(find.byType(IssueTimelineItem));

    await tester.pumpWidget(_wrap(IssueTimelineItem(labeled)));
    await tester.pump();
    final labeledSize = tester.getSize(find.byType(IssueTimelineItem));

    expect(
      (emptyReviewedSize.height - labeledSize.height).abs(),
      lessThan(1.0),
      reason:
          '空 body 的 reviewed 事件不应该多出任何 markdown 卡片相关的额外高度；两者应视觉等高',
    );
  });

  testWidgets('committed + actor 缺失 → 用 commitAuthorName + 短哈希 + message 渲染',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'committed',
      actor: null,
      commitAuthorName: 'copilot-swe-agent[bot]',
      commitSha: '9b6cafcb2ff003874f7de61cbd1e03ca415349c1',
      commitMessage:
          'Add NDK arm64 filter and legacy packaging config for Android release APK size reduction',
      createdAt: DateTime(2026, 4, 7, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(
      find.textContaining('9b6cafc'),
      findsOneWidget,
      reason: 'commit 短哈希必须出现',
    );
    expect(
      find.textContaining('copilot-swe-agent[bot]'),
      findsOneWidget,
      reason: 'actor 缺失时应回落到 commitAuthorName',
    );
    expect(
      find.textContaining('Add NDK arm64 filter'),
      findsOneWidget,
      reason: 'commit message 应出现在事件行',
    );
    // 关键回归：不应再出现原先的兜底占位 "---"
    expect(find.textContaining('---'), findsNothing,
        reason: 'actor 缺失不应再回退到字面量 ---');
    // 关键回归：应走 pr_timeline_committed 分支（有 em dash 分隔），而不是 generic
    // generic 分支渲染出来是 "x committed"（无分隔符），这里必须能看到 em dash
    expect(find.textContaining(' — '), findsOneWidget,
        reason: 'committed + message 应走 pr_timeline_committed，包含 em dash');
  });

  testWidgets('committed + actor 存在 → 优先使用 actor.login 而非 commitAuthorName',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'committed',
      actor: _user('real-actor'),
      commitAuthorName: 'commit-author-name',
      commitSha: 'abcdefabcdef1234567890abcdef12345678abcd',
      commitMessage: 'hello world',
      createdAt: DateTime(2026, 4, 7, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('real-actor'), findsOneWidget);
    expect(find.textContaining('abcdefa'), findsOneWidget);
    expect(find.textContaining('hello world'), findsOneWidget);
    expect(find.textContaining('commit-author-name'), findsNothing,
        reason: 'actor 存在时不应再使用 commitAuthorName');
  });

  testWidgets('committed + message 为 null → 走 no_message 变体，不出现 em dash',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'committed',
      commitAuthorName: 'x',
      commitSha: '1234567890abcdef1234567890abcdef12345678',
      commitMessage: null,
      createdAt: DateTime(2026, 4, 7, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('1234567'), findsOneWidget);
    // 断言：no_message 变体应包含 "x committed 1234567"（英文默认 locale）
    // 用 shortSha + actor 组合断言比裸 'x' 精确得多
    expect(find.textContaining('x committed 1234567'), findsOneWidget,
        reason: 'no_message 变体应生成 "{actor} committed {shortSha}" 整句');
    expect(find.textContaining(' — '), findsNothing,
        reason: 'no_message 变体不应出现 em dash 分隔符');
  });

  testWidgets('committed + sha 缺失 → 兜底到 generic 而不是崩溃',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'committed',
      commitAuthorName: 'x',
      commitSha: null,
      commitMessage: 'msg',
      createdAt: DateTime(2026, 4, 7, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    // 走 issue_timeline_generic("x", "committed")
    expect(find.textContaining('committed'), findsOneWidget);
  });

  testWidgets('committed + actor 缺失 + commitAuthorName 也缺 → 兜底 --- 而不是崩溃',
      (tester) async {
    // 覆盖 fallback 链最末段：actor?.login ?? commitAuthorName ?? '---'
    final event = IssueTimelineEvent(
      event: 'committed',
      actor: null,
      commitAuthorName: null,
      commitSha: '1234567890abcdef1234567890abcdef12345678',
      commitMessage: 'msg',
      createdAt: DateTime(2026, 4, 7, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('---'), findsOneWidget,
        reason: 'actor 和 commitAuthorName 都缺失时应回落到字面 ---');
    expect(find.textContaining('1234567'), findsOneWidget);
  });

  testWidgets('copilot_work_started → 走 pr_timeline_copilot_work_started 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'copilot_work_started',
      actor: _user('copilot-swe-agent[bot]'),
      createdAt: DateTime(2026, 7, 1, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('copilot-swe-agent[bot]'), findsOneWidget);
    // 关键回归：不应再显示英文字面事件名 "copilot_work_started"
    expect(find.textContaining('copilot_work_started'), findsNothing,
        reason: '不应再走 generic 兜底显示字面事件名');
    // 英文默认 locale 应命中 "started working on this PR"
    expect(find.textContaining('started working on this PR'), findsOneWidget);
  });

  testWidgets('copilot_work_finished → 走 pr_timeline_copilot_work_finished 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'copilot_work_finished',
      actor: _user('copilot-swe-agent[bot]'),
      createdAt: DateTime(2026, 7, 1, 11, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('copilot_work_finished'), findsNothing,
        reason: '不应再走 generic 兜底显示字面事件名');
    expect(find.textContaining('finished working on this PR'), findsOneWidget);
  });

  testWidgets('added_to_merge_queue → 走 pr_timeline_added_to_merge_queue 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'added_to_merge_queue',
      actor: _user('alice'),
      createdAt: DateTime(2026, 7, 4, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('added_to_merge_queue'), findsNothing,
        reason: '不应走 generic 兜底显示字面事件名');
    expect(find.textContaining('added this pull request to the merge queue'),
        findsOneWidget);
  });

  testWidgets(
      'removed_from_merge_queue → 走 pr_timeline_removed_from_merge_queue 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'removed_from_merge_queue',
      actor: _user('bob'),
      createdAt: DateTime(2026, 7, 4, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('removed_from_merge_queue'), findsNothing);
    expect(
        find.textContaining('removed this pull request from the merge queue'),
        findsOneWidget);
  });

  testWidgets('added_to_project_v2 → 走 issue_timeline_added_to_project 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'added_to_project_v2',
      actor: _user('alice'),
      createdAt: DateTime(2026, 7, 4, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('added_to_project_v2'), findsNothing);
    expect(find.textContaining('added this to a project'), findsOneWidget);
  });

  testWidgets(
      'project_v2_item_status_changed → 走 issue_timeline_project_status_changed 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'project_v2_item_status_changed',
      actor: _user('alice'),
      createdAt: DateTime(2026, 7, 4, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('project_v2_item_status_changed'), findsNothing);
    expect(find.textContaining('changed the project status'), findsOneWidget);
  });

  testWidgets('issue_type_added → 走 issue_timeline_issue_type_added 分支',
      (tester) async {
    final event = IssueTimelineEvent(
      event: 'issue_type_added',
      actor: _user('alice'),
      createdAt: DateTime(2026, 7, 4, 10, 0),
    );

    await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
    await tester.pump();

    expect(find.textContaining('issue_type_added'), findsNothing);
    expect(find.textContaining('set the issue type'), findsOneWidget);
  });

  group('未知事件遥测', () {
    testWidgets('未知事件 → 走 generic 兜底不崩，且事件名进入去重表（一次性登记）',
        (tester) async {
      final event = IssueTimelineEvent(
        event: 'brand_new_ai_event',
        actor: _user('alice'),
        createdAt: DateTime(2026, 7, 4, 10, 0),
      );

      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();

      // 渲染层：不崩，走 generic 兜底显示事件名
      expect(find.textContaining('brand_new_ai_event'), findsOneWidget);

      // 遥测层：进程内已登记，避免同一事件后续 build 重复日志
      expect(
        IssueTimelineItem.loggedUnknownEvents.contains('brand_new_ai_event'),
        isTrue,
      );
    });

    testWidgets('同一未知事件多次 build → 去重表大小仍为 1（不重复登记）',
        (tester) async {
      final event = IssueTimelineEvent(
        event: 'yet_another_unknown',
        actor: _user('alice'),
        createdAt: DateTime(2026, 7, 4, 10, 0),
      );

      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();
      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();
      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();

      expect(
        IssueTimelineItem.loggedUnknownEvents
            .where((e) => e == 'yet_another_unknown')
            .length,
        1,
      );
    });

    testWidgets('已识别事件（committed）→ 不进入未知事件去重表',
        (tester) async {
      final event = IssueTimelineEvent(
        event: 'committed',
        actor: _user('alice'),
        commitAuthorName: 'alice',
        createdAt: DateTime(2026, 7, 4, 10, 0),
        commitSha: '1234567abcdef',
        commitMessage: 'fix: something',
      );

      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();

      expect(
        IssueTimelineItem.loggedUnknownEvents.contains('committed'),
        isFalse,
        reason: '已有 case 分支的事件不应进入未知事件遥测',
      );
    });

    testWidgets('event 名为空串 → 不登记（那是数据缺失，不是未知事件）',
        (tester) async {
      final event = IssueTimelineEvent(
        event: '',
        actor: _user('alice'),
        createdAt: DateTime(2026, 7, 4, 10, 0),
      );

      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();

      expect(IssueTimelineItem.loggedUnknownEvents.contains(''), isFalse);
    });

    testWidgets('event 为 null → 不登记，也不崩',
        (tester) async {
      final event = IssueTimelineEvent(
        event: null,
        actor: _user('alice'),
        createdAt: DateTime(2026, 7, 4, 10, 0),
      );

      await tester.pumpWidget(_wrap(IssueTimelineItem(event)));
      await tester.pump();

      // null 是脏数据形态，走 generic 兜底但不进入未知事件登记表。
      // 现有集合总大小应为 0（本 group setUp 已清空）。
      expect(IssueTimelineItem.loggedUnknownEvents.length, 0,
          reason: 'event=null 属于脏数据，不应污染未知事件遥测表');
    });
  });
}
