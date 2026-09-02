import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/model/pull_request_review_thread.dart';

void main() {
  group('PullRequestReviewThread.fromGraphql - 常规映射', () {
    test('完整 payload 抓 databaseId 列表并保留 isResolved', () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'PRRT_kwDOA',
        'isResolved': false,
        'comments': {
          'nodes': [
            {'databaseId': 101},
            {'databaseId': 102},
          ],
        },
      });
      expect(t, isNotNull);
      expect(t!.id, 'PRRT_kwDOA');
      expect(t.isResolved, false);
      expect(t.commentDatabaseIds, [101, 102]);
    });

    test('isResolved 为 true 时忠实透传', () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'isResolved': true,
        'comments': {'nodes': []},
      });
      expect(t!.isResolved, true);
      expect(t.commentDatabaseIds, isEmpty);
    });
  });

  group('PullRequestReviewThread.fromGraphql - 健壮性', () {
    test('map 为 null 时返回 null（GraphQL 空结果保护）', () {
      expect(PullRequestReviewThread.fromGraphql(null), isNull);
    });

    test('comments 字段缺失时 commentDatabaseIds 为空列表', () {
      final t = PullRequestReviewThread.fromGraphql({'id': 'x'});
      expect(t, isNotNull);
      expect(t!.commentDatabaseIds, isEmpty);
    });

    test('nodes 中含 num 之外的 databaseId 应被过滤掉', () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'comments': {
          'nodes': [
            {'databaseId': 101},
            {'databaseId': null},
            {'databaseId': 'not-int'},
            {'databaseId': 102},
          ],
        },
      });
      expect(t!.commentDatabaseIds, [101, 102]);
    });

    test('databaseId 为 double 时容忝并 toInt（防止 GraphQL 序列化把整数变浮点）', () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'comments': {
          'nodes': [
            {'databaseId': 101.0},
            {'databaseId': 102.7},
          ],
        },
      });
      expect(t!.commentDatabaseIds, [101, 102],
          reason: 'databaseId 是 num 就接收，double 用 toInt 截断');
    });

    test('databaseId 为 NaN/Infinity 时应被过滤（isFinite 守约，避免 toInt 抛 UnsupportedError）',
        () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'comments': {
          'nodes': [
            {'databaseId': 101},
            {'databaseId': double.nan},
            {'databaseId': double.infinity},
            {'databaseId': double.negativeInfinity},
            {'databaseId': 102},
          ],
        },
      });
      expect(t!.commentDatabaseIds, [101, 102],
          reason: 'NaN/Infinity.toInt() 会抛 UnsupportedError，必须先 isFinite 兜底');
    });

    test('databaseId 边界值：0 / 负数 / int64 上界 都原样保留', () {
      // reviewer F5 关注点：契约收紧程度到 isFinite 为止——finite 但不合理的值
      // （比如负数、极大整数）交给上游 GitHub 保证，客户端只做"能不能 toInt"的
      // 兜底。这条测试把当前契约锁死，防止后来人误加"必须为正整数"过滤把
      // 合法但少见的 0 也当垃圾丢掉。
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'comments': {
          'nodes': [
            {'databaseId': 0},
            {'databaseId': -1},
            {'databaseId': 9007199254740992},
          ],
        },
      });
      expect(t!.commentDatabaseIds, [0, -1, 9007199254740992],
          reason: '0 / 负数 / 大整数都是 finite num，按当前契约保留原值');
    });

    test('nodes 不是 List 时保持空列表', () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'comments': {'nodes': 'oops'},
      });
      expect(t!.commentDatabaseIds, isEmpty);
    });

    test('id 收到非 String 类型时抛 TypeError（当前契约：GraphQL 必须传 String）', () {
      expect(
          () => PullRequestReviewThread.fromGraphql({
                'id': 123,
                'comments': {'nodes': []},
              }),
          throwsA(isA<TypeError>()));
    });

    test('isResolved 收到非 bool 类型时抛 TypeError（当前契约：GraphQL 必须传 bool）',
        () {
      expect(
          () => PullRequestReviewThread.fromGraphql({
                'id': 'x',
                'isResolved': 'true',
                'comments': {'nodes': []},
              }),
          throwsA(isA<TypeError>()));
    });
  });

  group('PullRequestReviewThread primary constructor 语义', () {
    test('默认命名参数 commentDatabaseIds 应为 const []', () {
      final t = PullRequestReviewThread();
      expect(t.id, isNull);
      expect(t.isResolved, isNull);
      expect(t.commentDatabaseIds, isEmpty);
    });

    test('默认实例的 commentDatabaseIds 是不可变 const list', () {
      final t = PullRequestReviewThread();
      expect(() => t.commentDatabaseIds.add(1),
          throwsA(isA<UnsupportedError>()));
    });

    test('fromGraphql 构造的实例 commentDatabaseIds 元素顺序与内容锁定', () {
      final t = PullRequestReviewThread.fromGraphql({
        'id': 'x',
        'comments': {
          'nodes': [
            {'databaseId': 1},
          ],
        },
      })!;
      expect(t.commentDatabaseIds, [1]);
    });

    test('显式传入的字段应覆盖默认值', () {
      final t = PullRequestReviewThread(
        id: 'y',
        isResolved: true,
        commentDatabaseIds: [1, 2, 3],
      );
      expect(t.id, 'y');
      expect(t.isResolved, true);
      expect(t.commentDatabaseIds, [1, 2, 3]);
    });
  });
}
