// Reactions 数据规范化 & 本地状态推进（纯 Dart，无 flutter 依赖）。
//
// 承接 roadmap §3.1 剩余分支 pt.1 "reactions bar"，负责把 GraphQL
// `Reactable.reactionGroups` 的原始返回结构（`List<Map<String, dynamic>>`）
// 抽象成 [ReactionSummary] 列表，供 UI 侧直接消费；同时提供
// [applyLocalReactionToggle] 用于 mutation 成功后**就地**推进本地状态，
// 避免为一次加/取消 reaction 重新拉整页 discussion。
//
// 单文件承载三个 concern：
//   1. `ReactionContent` 8 类枚举字面量 <=> emoji 一一映射
//   2. `pickReactionGroups(raw)` 规范化（宽容处理：null / 缺字段 / 未知 content）
//   3. `applyLocalReactionToggle(list, content, add)` 增量推进（幂等）
//
// **纯函数原则**：不引入 flutter/material、不做网络 IO，只操作 Map / List /
// 基本类型。这样 [test/page/discussion/reaction_groups_test.dart] 可以走
// 纯 Dart 单测，不必拉起 widget binding。

/// GraphQL `ReactionContent` 8 类枚举字面量（顺序与 GitHub 网页版长按弹窗一致：
/// 👍 👎 😄 🎉 😕 ❤️ 🚀 👀）。
///
/// 顺序在 UI 里作为 chip 选择器的**默认展示顺序**，与 GitHub Web 对齐可减少
/// 用户认知负担；未来若产品要求"按热度排序"，仅在 UI 层做视觉排序，不改这里。
const List<String> kReactionContents = <String>[
  'THUMBS_UP',
  'THUMBS_DOWN',
  'LAUGH',
  'HOORAY',
  'CONFUSED',
  'HEART',
  'ROCKET',
  'EYES',
];

/// `ReactionContent` 到 emoji 的映射（**唯一权威**，UI / 单测都从这里读）。
///
/// 未列在这里的 `content`（如 GitHub 未来新增枚举值）会在
/// [pickReactionGroups] 里被宽容丢弃 —— 保持"新 emoji 不会崩前端"的兜底。
const Map<String, String> kReactionEmoji = <String, String>{
  'THUMBS_UP': '👍',
  'THUMBS_DOWN': '👎',
  'LAUGH': '😄',
  'HOORAY': '🎉',
  'CONFUSED': '😕',
  'HEART': '❤️',
  'ROCKET': '🚀',
  'EYES': '👀',
};

/// 单条 reaction 分组的运行时快照。
///
/// - [content]：GraphQL `ReactionContent` 枚举字面量（`THUMBS_UP` 等）
/// - [emoji]：与 [content] 一一对应的 emoji（[kReactionEmoji] 权威值）
/// - [count]：该类 reaction 的人数（0 表示尚无人 react；渲染时可过滤 0）
/// - [viewerHasReacted]：当前登录用户是否已 react；用于本地 chip 高亮
///   与"再点一次是 add 还是 remove"的分支
class ReactionSummary {
  final String content;
  final String emoji;
  final int count;
  final bool viewerHasReacted;

  const ReactionSummary({
    required this.content,
    required this.emoji,
    required this.count,
    required this.viewerHasReacted,
  });

  /// 复制并覆盖部分字段（reaction 状态推进时用；`copyWith(count: xx)`）。
  ReactionSummary copyWith({
    int? count,
    bool? viewerHasReacted,
  }) =>
      ReactionSummary(
        content: content,
        emoji: emoji,
        count: count ?? this.count,
        viewerHasReacted: viewerHasReacted ?? this.viewerHasReacted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionSummary &&
          content == other.content &&
          emoji == other.emoji &&
          count == other.count &&
          viewerHasReacted == other.viewerHasReacted;

  @override
  int get hashCode => Object.hash(content, emoji, count, viewerHasReacted);

  @override
  String toString() =>
      'ReactionSummary($content $emoji count=$count viewerHasReacted=$viewerHasReacted)';
}

/// 把 GraphQL `reactionGroups` 原始返回规范化为 [ReactionSummary] 列表。
///
/// - 入参 [raw] 是 GraphQL 的 `List<dynamic>?`（每项为
///   `{content, viewerHasReacted, reactors: {totalCount}}` Map）
/// - `null` / 非 List / 空 List / 元素类型错 均返回空列表（不抛异常）
/// - 未在 [kReactionEmoji] 里的 content 直接跳过（GitHub 未来新增枚举兜底）
/// - `viewerHasReacted` 非 bool 或缺失时按 false 处理
/// - `reactors.totalCount` 非 int 或缺失时按 0 处理
/// - 输出顺序按 [kReactionContents] 固定（`THUMBS_UP → EYES`），与 UI 层
///   chip 展示顺序对齐；服务端返回顺序不稳定，这里做一次归一
List<ReactionSummary> pickReactionGroups(dynamic raw) {
  if (raw is! List) return const <ReactionSummary>[];
  final Map<String, ReactionSummary> byContent = <String, ReactionSummary>{};
  for (final item in raw) {
    if (item is! Map) continue;
    final content = item['content'];
    if (content is! String) continue;
    final emoji = kReactionEmoji[content];
    if (emoji == null) continue;
    final reactors = item['reactors'];
    final int count = (reactors is Map && reactors['totalCount'] is int)
        ? reactors['totalCount'] as int
        : 0;
    final bool viewerHasReacted = item['viewerHasReacted'] == true;
    byContent[content] = ReactionSummary(
      content: content,
      emoji: emoji,
      count: count,
      viewerHasReacted: viewerHasReacted,
    );
  }
  return <ReactionSummary>[
    for (final c in kReactionContents)
      if (byContent.containsKey(c)) byContent[c]!,
  ];
}

/// 在 mutation 成功前**乐观**推进本地 reactions 列表；或在 mutation 返回后
/// 拿服务端最新 reactionGroups 覆盖前的过渡态。
///
/// 语义：
///   - `add=true`  且该 content 已 `viewerHasReacted=true`：视为幂等，返回原
///     引用（不新造对象，方便上层 identical 检测）
///   - `add=true`  且未 react：count+1，viewerHasReacted=true
///   - `add=false` 且该 content 未 `viewerHasReacted`：视为幂等，返回原引用
///   - `add=false` 且已 react：count 减 1（不低于 0），viewerHasReacted=false
///   - list 里不存在该 content 时：
///       * `add=true`  → 追加一条 count=1 / viewerHasReacted=true
///       * `add=false` → 视为幂等，返回原引用
///
/// 未列在 [kReactionEmoji] 的 content 直接不动（避免 UI 拿到不认识的 emoji）。
///
/// **返回值总是有序**（按 [kReactionContents] 固定顺序），与
/// [pickReactionGroups] 的输出契约对齐。
List<ReactionSummary> applyLocalReactionToggle(
  List<ReactionSummary> current,
  String content, {
  required bool add,
}) {
  final emoji = kReactionEmoji[content];
  if (emoji == null) return current;

  final Map<String, ReactionSummary> byContent = <String, ReactionSummary>{
    for (final r in current) r.content: r,
  };
  final existing = byContent[content];

  if (add) {
    if (existing != null && existing.viewerHasReacted) return current;
    if (existing == null) {
      byContent[content] = ReactionSummary(
        content: content,
        emoji: emoji,
        count: 1,
        viewerHasReacted: true,
      );
    } else {
      byContent[content] = existing.copyWith(
        count: existing.count + 1,
        viewerHasReacted: true,
      );
    }
  } else {
    if (existing == null || !existing.viewerHasReacted) return current;
    final int nextCount = existing.count - 1;
    byContent[content] = existing.copyWith(
      count: nextCount < 0 ? 0 : nextCount,
      viewerHasReacted: false,
    );
  }

  return <ReactionSummary>[
    for (final c in kReactionContents)
      if (byContent.containsKey(c)) byContent[c]!,
  ];
}
