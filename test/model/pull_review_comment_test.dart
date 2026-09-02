import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/model/pull_review_comment.dart';

void main() {
  group('PullReviewComment.fromJson - 常规映射', () {
    test('完整 payload 保留全部字段并解析时间/用户', () {
      final c = PullReviewComment.fromJson({
        'id': 42,
        'path': 'android/app/build.gradle',
        'position': 3,
        'original_position': 2,
        'line': 41,
        'original_line': 40,
        'diff_hunk': '@@ -38,4 +38,7 @@',
        'body': 'nit: prefer const',
        'user': {'login': 'Copilot'},
        'html_url':
            'https://github.com/CarGuo/gsy_github_app_flutter/pull/938#discussion_r1',
        'created_at': '2026-07-01T10:00:00Z',
        'updated_at': '2026-07-01T10:05:00Z',
      });
      expect(c.id, 42);
      expect(c.path, 'android/app/build.gradle');
      expect(c.position, 3);
      expect(c.originalPosition, 2);
      expect(c.line, 41);
      expect(c.originalLine, 40);
      expect(c.diffHunk, '@@ -38,4 +38,7 @@');
      expect(c.body, 'nit: prefer const');
      expect(c.user?.login, 'Copilot');
      expect(c.htmlUrl, contains('#discussion_r1'));
      expect(c.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));
      expect(c.updatedAt, DateTime.parse('2026-07-01T10:05:00Z'));
    });
  });

  group('PullReviewComment.fromJson - 健壮性', () {
    test('空 payload 不 crash 且全部 12 个字段均为 null', () {
      final c = PullReviewComment.fromJson(<String, dynamic>{});
      expect(c.id, isNull);
      expect(c.path, isNull);
      expect(c.position, isNull);
      expect(c.originalPosition, isNull);
      expect(c.line, isNull);
      expect(c.originalLine, isNull);
      expect(c.diffHunk, isNull);
      expect(c.body, isNull);
      expect(c.user, isNull);
      expect(c.htmlUrl, isNull);
      expect(c.createdAt, isNull);
      expect(c.updatedAt, isNull);
    });

    test('created_at 为空串时 createdAt 保持 null', () {
      final c = PullReviewComment.fromJson({'created_at': ''});
      expect(c.createdAt, isNull);
    });

    test('created_at 非法字符串时 createdAt 保持 null', () {
      final c = PullReviewComment.fromJson({'created_at': 'not-a-date'});
      expect(c.createdAt, isNull);
    });

    test('user 不是 Map 时不构造 User 对象', () {
      final c = PullReviewComment.fromJson({'user': 'Copilot'});
      expect(c.user, isNull);
    });

    test('user 是 Map<dynamic, dynamic>（GraphQL/hive 常见）时也能解析出 User', () {
      final Map<dynamic, dynamic> rawUser = <dynamic, dynamic>{
        'login': 'Copilot',
      };
      final c = PullReviewComment.fromJson(<String, dynamic>{
        'user': rawUser,
      });
      expect(c.user, isNotNull,
          reason: '只判 is Map 才不会把 Map<dynamic,dynamic> 误当成非法');
      expect(c.user?.login, 'Copilot');
    });

    test('num 字段容忍 double 类型', () {
      final c = PullReviewComment.fromJson({
        'id': 12.0,
        'position': 3.9,
        'line': 40.0,
      });
      expect(c.id, 12);
      expect(c.position, 3);
      expect(c.line, 40);
    });

    test('num 字段收到 String 时抛 TypeError（当前契约：外部 API 必须传 num）', () {
      expect(() => PullReviewComment.fromJson({'id': '42'}),
          throwsA(isA<TypeError>()));
      expect(() => PullReviewComment.fromJson({'position': '3'}),
          throwsA(isA<TypeError>()));
    });
  });

  group('PullReviewComment.displayLine', () {
    test('优先取 line', () {
      final c = PullReviewComment(line: 41, originalLine: 20);
      expect(c.displayLine, 41);
    });

    test('line 缺失时回退到 originalLine', () {
      final c = PullReviewComment(originalLine: 20);
      expect(c.displayLine, 20);
    });

    test('两者都缺时为 null（UI 走已过时兜底）', () {
      final c = PullReviewComment();
      expect(c.displayLine, isNull);
    });
  });
}
