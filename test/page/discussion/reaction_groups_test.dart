import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/page/discussion/reaction_groups.dart';

void main() {
  group('pickReactionGroups - GraphQL reactionGroups 规范化', () {
    test('null / 非 List / 空 List 都返回空列表', () {
      expect(pickReactionGroups(null), isEmpty);
      expect(pickReactionGroups('not a list'), isEmpty);
      expect(pickReactionGroups(<dynamic>[]), isEmpty);
    });

    test('完整 8 组 reaction 全部规范化，按 kReactionContents 顺序输出', () {
      final raw = <Map<String, dynamic>>[
        for (final c in kReactionContents)
          {
            'content': c,
            'viewerHasReacted': c == 'HEART',
            'reactors': {'totalCount': c == 'THUMBS_UP' ? 30 : 1},
          }
      ];
      final result = pickReactionGroups(raw);
      expect(result.length, 8);
      expect(result.map((r) => r.content).toList(), kReactionContents);
      expect(result.first.content, 'THUMBS_UP');
      expect(result.first.count, 30);
      expect(result.firstWhere((r) => r.content == 'HEART').viewerHasReacted,
          isTrue);
      expect(
          result
              .firstWhere((r) => r.content == 'THUMBS_UP')
              .viewerHasReacted,
          isFalse);
      for (final r in result) {
        expect(r.emoji, kReactionEmoji[r.content]);
      }
    });

    test('服务端返回顺序打乱时输出仍按 kReactionContents 顺序', () {
      final raw = <Map<String, dynamic>>[
        {'content': 'HEART', 'reactors': {'totalCount': 2}},
        {'content': 'THUMBS_UP', 'reactors': {'totalCount': 5}},
        {'content': 'EYES', 'reactors': {'totalCount': 1}},
      ];
      final result = pickReactionGroups(raw);
      expect(result.map((r) => r.content).toList(),
          <String>['THUMBS_UP', 'HEART', 'EYES']);
    });

    test('未知 content（GitHub 未来新增枚举）被宽容丢弃', () {
      final raw = <Map<String, dynamic>>[
        {'content': 'THUMBS_UP', 'reactors': {'totalCount': 3}},
        {'content': 'FIRE_EMOJI_NEW', 'reactors': {'totalCount': 99}},
        {'content': 'HEART', 'reactors': {'totalCount': 1}},
      ];
      final result = pickReactionGroups(raw);
      expect(result.map((r) => r.content).toList(),
          <String>['THUMBS_UP', 'HEART']);
    });

    test('reactors 缺失 / totalCount 缺失 / viewerHasReacted 非 bool 时兜底为 0/false',
        () {
      final raw = <Map<String, dynamic>>[
        {'content': 'THUMBS_UP'}, // 缺 reactors
        {'content': 'LAUGH', 'reactors': <String, dynamic>{}}, // 缺 totalCount
        {
          'content': 'HEART',
          'reactors': {'totalCount': 'not-int'}, // 类型错
          'viewerHasReacted': 'maybe', // 非 bool
        },
      ];
      final result = pickReactionGroups(raw);
      expect(result.length, 3);
      for (final r in result) {
        expect(r.count, 0);
        expect(r.viewerHasReacted, isFalse);
      }
    });

    test('元素类型错（非 Map）应跳过', () {
      final raw = <dynamic>[
        'not-a-map',
        42,
        {'content': 'ROCKET', 'reactors': {'totalCount': 7}},
      ];
      final result = pickReactionGroups(raw);
      expect(result.length, 1);
      expect(result.first.content, 'ROCKET');
      expect(result.first.count, 7);
    });
  });

  group('applyLocalReactionToggle - 本地增量推进', () {
    List<ReactionSummary> emptyList() => const <ReactionSummary>[];

    ReactionSummary summary(String content,
            {int count = 0, bool viewer = false}) =>
        ReactionSummary(
          content: content,
          emoji: kReactionEmoji[content]!,
          count: count,
          viewerHasReacted: viewer,
        );

    test('add：对不存在的 content 新增一条 count=1 / viewerHasReacted=true', () {
      final next = applyLocalReactionToggle(emptyList(), 'HEART', add: true);
      expect(next.length, 1);
      expect(next.first.content, 'HEART');
      expect(next.first.count, 1);
      expect(next.first.viewerHasReacted, isTrue);
    });

    test('add：对已存在但未 react 的 content，count+1 且 viewer 置真', () {
      final current = <ReactionSummary>[summary('THUMBS_UP', count: 5)];
      final next = applyLocalReactionToggle(current, 'THUMBS_UP', add: true);
      expect(next.first.count, 6);
      expect(next.first.viewerHasReacted, isTrue);
    });

    test('add：对已 react 的 content 幂等（返回原引用）', () {
      final current = <ReactionSummary>[
        summary('HEART', count: 3, viewer: true),
      ];
      final next = applyLocalReactionToggle(current, 'HEART', add: true);
      expect(identical(next, current), isTrue);
    });

    test('remove：对已 react 的 content，count-1 且 viewer 置假', () {
      final current = <ReactionSummary>[
        summary('ROCKET', count: 4, viewer: true),
      ];
      final next = applyLocalReactionToggle(current, 'ROCKET', add: false);
      expect(next.first.count, 3);
      expect(next.first.viewerHasReacted, isFalse);
    });

    test('remove：对未 react 的 content 幂等（返回原引用）', () {
      final current = <ReactionSummary>[summary('EYES', count: 2)];
      final next = applyLocalReactionToggle(current, 'EYES', add: false);
      expect(identical(next, current), isTrue);
    });

    test('remove：count=1 且已 react 时会归零，不会出现 -1', () {
      final current = <ReactionSummary>[
        summary('CONFUSED', count: 1, viewer: true),
      ];
      final next =
          applyLocalReactionToggle(current, 'CONFUSED', add: false);
      expect(next.first.count, 0);
      expect(next.first.viewerHasReacted, isFalse);
    });

    test('未知 content 保持原列表不动', () {
      final current = <ReactionSummary>[summary('HEART', count: 1)];
      final next =
          applyLocalReactionToggle(current, 'FIRE_EMOJI_NEW', add: true);
      expect(identical(next, current), isTrue);
    });

    test('add 多个 content 后输出仍按 kReactionContents 顺序', () {
      var list = emptyList();
      list = applyLocalReactionToggle(list, 'HEART', add: true);
      list = applyLocalReactionToggle(list, 'THUMBS_UP', add: true);
      list = applyLocalReactionToggle(list, 'EYES', add: true);
      expect(list.map((r) => r.content).toList(),
          <String>['THUMBS_UP', 'HEART', 'EYES']);
    });
  });
}
