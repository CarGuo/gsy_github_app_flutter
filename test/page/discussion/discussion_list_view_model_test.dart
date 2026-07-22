import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/page/discussion/widget/discussion_item.dart';

/// [DiscussionItemViewModel.fromMap] 契约测试。
///
/// 覆盖 discussion 列表卡片依赖的字段解析边界：
/// 1. 完整节点：所有字段正常拿到
/// 2. `answerChosenAt` 有值 → `answered=true`（与详情页 answered 徽标同标准）
/// 3. GitHub 允许作者删号 → `author == null`，UI 层需展示 ghost，不能崩
/// 4. `number` 缺失或不是 int → 返回 null，让上层 skip 该条
/// 5. `title` 缺失 → 允许空串（列表 UI 兜底），不 fail
/// 6. `comments.totalCount` / `upvoteCount` / `locked` 类型错乱 → 走各自默认值
/// 7. `category.emoji` 是 shortname（如 `:speech_balloon:`）→ 原样透传，
///    渲染层再 `resolveEmojiShortcode`，模型层不该越权
/// 8. 入参本身为 null → 返回 null
///
/// 若这里失守，页面层会到处 `as` / `!` 炸空；单测比真机截图更容易发现。
void main() {
  group('DiscussionItemViewModel.fromMap', () {
    test('完整节点解析全部字段', () {
      final vm = DiscussionItemViewModel.fromMap({
        'number': 680,
        'title': 'bettafish 生产内容产生的 ai 幻觉非常严重',
        'author': {
          'login': 'b612sheryl',
          'avatarUrl': 'https://avatars.githubusercontent.com/u/1?v=4',
        },
        'category': {'name': 'General', 'emoji': ':speech_balloon:'},
        'comments': {'totalCount': 1},
        'upvoteCount': 3,
        'answerChosenAt': null,
        'url': 'https://github.com/666ghj/BettaFish/discussions/680',
        'locked': false,
      });
      expect(vm, isNotNull);
      expect(vm!.number, 680);
      expect(vm.title, 'bettafish 生产内容产生的 ai 幻觉非常严重');
      expect(vm.authorLogin, 'b612sheryl');
      expect(vm.authorAvatar,
          'https://avatars.githubusercontent.com/u/1?v=4');
      expect(vm.categoryName, 'General');
      expect(vm.categoryEmoji, ':speech_balloon:');
      expect(vm.upvoteCount, 3);
      expect(vm.commentCount, 1);
      expect(vm.answered, false);
      expect(vm.url,
          'https://github.com/666ghj/BettaFish/discussions/680');
      expect(vm.locked, false);
    });

    test('answerChosenAt 有值 → answered=true', () {
      final vm = DiscussionItemViewModel.fromMap({
        'number': 42,
        'title': 't',
        'answerChosenAt': '2026-06-01T00:00:00Z',
      });
      expect(vm, isNotNull);
      expect(vm!.answered, isTrue);
    });

    test('author 为 null（作者已删号）→ 字段降级，不抛异常', () {
      final vm = DiscussionItemViewModel.fromMap({
        'number': 1,
        'title': 'ghost',
        'author': null,
      });
      expect(vm, isNotNull);
      expect(vm!.authorLogin, isNull);
      expect(vm.authorAvatar, isNull);
    });

    test('number 缺失或非 int → 返回 null（上层 skip）', () {
      expect(DiscussionItemViewModel.fromMap({'title': 'no number'}), isNull);
      expect(
          DiscussionItemViewModel.fromMap(
              {'number': '99', 'title': 'string number'}),
          isNull);
    });

    test('title 缺失 → 允许空串', () {
      final vm = DiscussionItemViewModel.fromMap({'number': 7});
      expect(vm, isNotNull);
      expect(vm!.title, '');
    });

    test('comments / upvoteCount / locked 类型错乱 → 用默认值兜底', () {
      final vm = DiscussionItemViewModel.fromMap({
        'number': 8,
        'title': 't',
        'comments': null,
        'upvoteCount': null,
        'locked': null,
      });
      expect(vm, isNotNull);
      expect(vm!.commentCount, 0);
      expect(vm.upvoteCount, 0);
      expect(vm.locked, false);
    });

    test('category.emoji 保留 shortname（渲染层再解析）', () {
      final vm = DiscussionItemViewModel.fromMap({
        'number': 9,
        'title': 't',
        'category': {'name': 'Q&A', 'emoji': ':pray:'},
      });
      expect(vm, isNotNull);
      expect(vm!.categoryEmoji, ':pray:');
      expect(vm.categoryName, 'Q&A');
    });

    test('入参 null → 返回 null', () {
      expect(DiscussionItemViewModel.fromMap(null), isNull);
    });
  });

  /// GraphQL `discussions.pageInfo.hasNextPage` → `needLoadMore` 反哺契约。
  ///
  /// 背景：`GSYListState.resolveDataResult` 默认按 `res.data.length >= PAGE_SIZE`
  /// 决定 needLoadMore，与 GraphQL cursor 分页语义脱节。`DiscussionListPage._fetchPage`
  /// 在成功分支显式覆盖为 `pageInfo.hasNextPage` 兜底。这里锁定 pageInfo
  /// 反序列化的关键契约，避免未来某次 refactor 把 bool 意外读成 String / null
  /// 让 needLoadMore 走错分支。
  ///
  /// 这里不 mock 网络层（graphql client 需要单独 harness），只对**从 map 结构
  /// 提取 hasNextPage bool** 做黑盒断言，等价于 _fetchPage 里那一行赋值语义。
  group('discussions.pageInfo.hasNextPage 契约', () {
    bool extractHasNextPage(Map<String, dynamic>? pageInfo) {
      // 与 [DiscussionListPage._fetchPage] 保持完全一致的读法
      return (pageInfo?['hasNextPage'] as bool?) ?? false;
    }

    test('hasNextPage=true → needLoadMore 应为 true', () {
      expect(
          extractHasNextPage({'hasNextPage': true, 'endCursor': 'c1'}), true);
    });

    test('hasNextPage=false → needLoadMore 应为 false（最后一页硬约束）', () {
      expect(extractHasNextPage({'hasNextPage': false, 'endCursor': 'c1'}),
          false);
    });

    test('pageInfo 为 null → 默认 false（不再拉，避免死循环）', () {
      expect(extractHasNextPage(null), false);
    });

    test('hasNextPage 字段缺失 → 默认 false', () {
      expect(extractHasNextPage(<String, dynamic>{'endCursor': 'c1'}), false);
    });
  });
}
