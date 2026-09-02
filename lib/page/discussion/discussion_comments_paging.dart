/// GitHub Discussion 详情页 comments 分页数据处理（纯 Dart 逻辑，无 Flutter 依赖）。
///
/// 抽出这一层的动机（也是 review 时最容易问的）：
/// - detail_page 里 `setState` 分支太杂：首屏 vs loadMore vs 网络错误 vs pageInfo 缺失
///   每种都要判断 `_comments / _endCursor / _hasNextPage` 三个状态是否一致
/// - 纯逻辑抽出来后，可以在 [test/page/discussion/discussion_comments_paging_test.dart]
///   里覆盖：空态、非空、hasNextPage 真假、endCursor null 兜底、payload 缺字段兜底
/// - widget 层只负责 `pickCommentsPage(raw)` + `mergeCommentsPage(state, page)` 两个纯函数
///   的调用，不再需要在 UI 里穿插 null 校验
///
/// 不做的事：
/// - 不做 replies 分页（roadmap §3.1 后续子任务）
/// - 不做 comment 排序 / 时间倒序（GitHub 服务端默认按创建时间正序，遵循这个）
library;

/// 一页 comments 的规范化视图。所有字段都是 non-null，UI 侧不用再兜底。
class DiscussionCommentsPage {
  /// 本页 comment nodes（保持服务端顺序，不排序）
  final List<Map<String, dynamic>> nodes;

  /// 是否还有下一页；服务端明确返回 false 或字段缺失都视为 false
  final bool hasNextPage;

  /// 下一页游标；hasNextPage=false 时可能为 null
  final String? endCursor;

  /// 服务端汇报的评论总数（含未拉取的）。用于头部 "N comments" 校对
  final int totalCount;

  const new({
    required this.nodes,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  /// 空态构造（用于"首屏返回失败"或"没有 comments 字段"的兜底）
  static const empty = DiscussionCommentsPage(
    nodes: <Map<String, dynamic>>[],
    hasNextPage: false,
    endCursor: null,
    totalCount: 0,
  );
}

/// 从 GraphQL 返回的 `repository.discussion` map 里挑出 comments connection。
///
/// 兼容两种入参形态：
/// - 首屏走 [readDiscussion]：传入 `discussion` 整个 map，会读取 `discussion['comments']`
/// - loadMore 走 [readDiscussionCommentsPage]：也可以直接传 `discussion` map
///
/// 任一层缺失都返回 [DiscussionCommentsPage.empty]（而不是 throw / null），
/// 避免 UI 层还要写一遍 null-check。
DiscussionCommentsPage pickCommentsPage(Map<String, dynamic>? discussion) {
  if (discussion == null) return DiscussionCommentsPage.empty;
  final commentsRaw = discussion['comments'];
  if (commentsRaw is! Map) {
    return DiscussionCommentsPage.empty;
  }
  final nodesRaw = commentsRaw['nodes'];
  final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
  if (nodesRaw is List) {
    for (final e in nodesRaw) {
      if (e is Map<String, dynamic>) {
        nodes.add(e);
      } else if (e is Map) {
        nodes.add(Map<String, dynamic>.from(e));
      }
    }
  }
  final pageInfoRaw = commentsRaw['pageInfo'];
  bool hasNextPage = false;
  String? endCursor;
  if (pageInfoRaw is Map) {
    hasNextPage = pageInfoRaw['hasNextPage'] == true;
    final ec = pageInfoRaw['endCursor'];
    if (ec is String && ec.isNotEmpty) endCursor = ec;
  }
  final tc = commentsRaw['totalCount'];
  final int totalCount = tc is int ? tc : 0;
  return DiscussionCommentsPage(
    nodes: nodes,
    hasNextPage: hasNextPage,
    endCursor: endCursor,
    totalCount: totalCount,
  );
}

/// 把新一页 comments 追加到已有列表尾部，并**用新页的 pageInfo 覆盖**旧的。
///
/// 关键约束：
/// - 顺序为"旧 + 新"，与 GitHub Web 上滚动加载视觉一致
/// - `hasNextPage` / `endCursor` 一律用**新页**的（GitHub 服务端语义：`after` 之后
///   的分页信息在新的 pageInfo 里）
/// - `totalCount` 也用新页的：服务端可能在两次请求之间有新评论进来，取最新更准
/// - 不做去重：GitHub 分页游标不重叠，服务端强一致；如果哪天出现重复，是服务端 bug
///   而不是客户端应该兜底的地方（写在这里避免下次 review 又要问一遍）
DiscussionCommentsPage mergeCommentsPage(
  DiscussionCommentsPage prev,
  DiscussionCommentsPage next,
) {
  return DiscussionCommentsPage(
    nodes: <Map<String, dynamic>>[...prev.nodes, ...next.nodes],
    hasNextPage: next.hasNextPage,
    endCursor: next.endCursor,
    totalCount: next.totalCount,
  );
}
