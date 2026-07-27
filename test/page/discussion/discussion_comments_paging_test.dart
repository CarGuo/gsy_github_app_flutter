import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/page/discussion/discussion_comments_paging.dart';

/// [pickCommentsPage] + [mergeCommentsPage] 契约测试。
///
/// 分页逻辑一旦跑歪，真机上要么"加载更多"按钮永远不显示，要么点了报错也
/// 不清空 loading 状态，靠肉眼很难在一次冒烟里覆盖全 4 态。所以把纯逻辑
/// 抽到 [discussion_comments_paging.dart] 里，用这份单测卡住：
///
/// 1. `null` discussion → 空态兜底
/// 2. `comments` 字段缺失 / 类型错 → 空态兜底
/// 3. `nodes` 非空 + hasNextPage=true + endCursor 非空 → 正常返回
/// 4. `pageInfo` 缺失 → hasNextPage 视为 false
/// 5. `pageInfo.endCursor` 是空串 → endCursor 归 null（避免 loadMore 拿空串去请求）
/// 6. `nodes` 混合 `Map<String, dynamic>` 与 `Map<dynamic, dynamic>`
///    → 均能被规范化，不会漏
/// 7. `mergeCommentsPage` 尾部追加 + pageInfo 用新页覆盖 + totalCount 用新页
void main() {
  group('pickCommentsPage', () {
    test('discussion 为 null → 返回 empty', () {
      final page = pickCommentsPage(null);
      expect(page.nodes, isEmpty);
      expect(page.hasNextPage, isFalse);
      expect(page.endCursor, isNull);
      expect(page.totalCount, 0);
      expect(page, same(DiscussionCommentsPage.empty));
    });

    test('comments 字段缺失 → 返回 empty', () {
      final page = pickCommentsPage(<String, dynamic>{'title': 'x'});
      expect(page.nodes, isEmpty);
      expect(page.hasNextPage, isFalse);
      expect(page.endCursor, isNull);
    });

    test('comments 字段类型错（不是 Map）→ 返回 empty', () {
      final page = pickCommentsPage(<String, dynamic>{'comments': 'oops'});
      expect(page.nodes, isEmpty);
      expect(page.hasNextPage, isFalse);
    });

    test('正常一页：nodes / hasNextPage / endCursor / totalCount 都拿到', () {
      final page = pickCommentsPage(<String, dynamic>{
        'comments': <String, dynamic>{
          'totalCount': 12,
          'pageInfo': <String, dynamic>{
            'hasNextPage': true,
            'endCursor': 'cursor_1',
          },
          'nodes': <dynamic>[
            <String, dynamic>{'id': 'c1', 'bodyHTML': 'hello'},
            <String, dynamic>{'id': 'c2', 'bodyHTML': 'world'},
          ],
        },
      });
      expect(page.totalCount, 12);
      expect(page.hasNextPage, isTrue);
      expect(page.endCursor, 'cursor_1');
      expect(page.nodes, hasLength(2));
      expect(page.nodes.first['id'], 'c1');
    });

    test('pageInfo 缺失 → hasNextPage=false', () {
      final page = pickCommentsPage(<String, dynamic>{
        'comments': <String, dynamic>{
          'totalCount': 3,
          'nodes': <dynamic>[
            <String, dynamic>{'id': 'c1'},
          ],
        },
      });
      expect(page.hasNextPage, isFalse);
      expect(page.endCursor, isNull);
      expect(page.nodes, hasLength(1));
    });

    test('endCursor 是空串 → 归 null，防止 loadMore 用空游标发请求', () {
      final page = pickCommentsPage(<String, dynamic>{
        'comments': <String, dynamic>{
          'pageInfo': <String, dynamic>{
            'hasNextPage': true,
            'endCursor': '',
          },
          'nodes': <dynamic>[],
        },
      });
      expect(page.hasNextPage, isTrue);
      expect(page.endCursor, isNull);
    });

    test('nodes 里混杂 Map<dynamic,dynamic> → 规范化成 Map<String,dynamic>', () {
      final rawDynMap = <dynamic, dynamic>{'id': 'cx', 'bodyHTML': 'raw'};
      final page = pickCommentsPage(<String, dynamic>{
        'comments': <String, dynamic>{
          'nodes': <dynamic>[
            rawDynMap,
            <String, dynamic>{'id': 'cy'},
          ],
        },
      });
      expect(page.nodes, hasLength(2));
      expect(page.nodes.first['id'], 'cx');
      expect(page.nodes.first['bodyHTML'], 'raw');
    });
  });

  group('mergeCommentsPage', () {
    test('尾部追加 + pageInfo/totalCount 用新页', () {
      const prev = DiscussionCommentsPage(
        nodes: <Map<String, dynamic>>[
          {'id': 'c1'},
          {'id': 'c2'},
        ],
        hasNextPage: true,
        endCursor: 'cursor_1',
        totalCount: 10,
      );
      const next = DiscussionCommentsPage(
        nodes: <Map<String, dynamic>>[
          {'id': 'c3'},
        ],
        hasNextPage: false,
        endCursor: null,
        totalCount: 11,
      );
      final merged = mergeCommentsPage(prev, next);
      expect(merged.nodes.map((e) => e['id']).toList(),
          ['c1', 'c2', 'c3']);
      expect(merged.hasNextPage, isFalse);
      expect(merged.endCursor, isNull);
      expect(merged.totalCount, 11);
    });

    test('新页空 → 旧列表保留，pageInfo 归零', () {
      const prev = DiscussionCommentsPage(
        nodes: <Map<String, dynamic>>[
          {'id': 'c1'},
        ],
        hasNextPage: true,
        endCursor: 'cursor_1',
        totalCount: 5,
      );
      final merged = mergeCommentsPage(prev, DiscussionCommentsPage.empty);
      expect(merged.nodes, hasLength(1));
      expect(merged.hasNextPage, isFalse);
      expect(merged.endCursor, isNull);
      expect(merged.totalCount, 0);
    });
  });
}
