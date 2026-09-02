import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// 每张 group 卡片默认展开的最大事件条数。
/// 超过这个数量的组会显示"展开剩余 N 条"入口，点击后一次性铺开。
const int kEventGroupInlineLimit = 5;

/// 计算连续同 actor 事件组的最小组大小。
/// 例：`3 1 1 1 4` 里长度为 3 与 4 的连续段会成为一个 group，
/// 单条事件（长度 1）保持原来的 [GSYEventItem] 渲染，避免把普通列表也变成卡片墙。
const int _kMinGroupSize = 2;

/// 描述从原始 dataList 中识别出的一段"连续同用户事件"。
/// - [startIndex] / [endIndex] 是相对原始 list 的闭区间。
/// - [events] 是该段内按顺序抓出的 [Event]，长度等于区间长度。
class EventGroupSpan {
  final int startIndex;
  final int endIndex;
  final List<Event> events;

  const new({
    required this.startIndex,
    required this.endIndex,
    required this.events,
  });

  int get length => events.length;

  /// 分组的稳定身份。
  ///
  /// key 只依赖"这一段连续段的开头是谁 + 从哪条事件起头"，不依赖 [startIndex] /
  /// [endIndex] / [length]。这样跨页 loadMore 把新事件追加进同一段时（例：
  /// 上一页尾部与新一页头部同一 actor 被 `buildEventGroupSpans` 合并），
  /// key 保持不变 → [GSYEventGroupItem] 的 State 不会被销毁重建 →
  /// 用户之前点开的"展开剩余 N 条"不会因分页而收回。
  ///
  /// [Event.id] 是 nullable，null 时用 actor.login 兜底，罕见且不影响主路径。
  String get stableKey {
    final Event head = events.first;
    final String? id = head.id;
    final String login = head.actor?.login ?? '';
    if (id != null && id.isNotEmpty) {
      return 'evt_$id';
    }
    return 'actor_${login}_$startIndex';
  }
}

/// 扫描一个 pullLoadWidgetControl.dataList，把"连续同一个 actor.login 的 Event"
/// 折叠成 [EventGroupSpan]。
///
/// 规则：
/// - 只有 [Event] 且 actor.login 非空 才参与分组。
/// - 非 Event 项（例：组织成员 User）永远只占一个位置，不进 group。
/// - 连续段长度 < [_kMinGroupSize] 时视为普通 event，走原来的 [GSYEventItem]。
///
/// 返回的 map: key = 原始 list index，value = 该 index 所属 group 的 span。
/// 只有 span 的 startIndex 会被 map 命中；startIndex+1..endIndex 通过 [isConsumedGroupIndex]
/// 单独判定，避免重复渲染。
Map<int, EventGroupSpan> buildEventGroupSpans(List<dynamic> dataList) {
  final Map<int, EventGroupSpan> spans = <int, EventGroupSpan>{};
  int i = 0;
  while (i < dataList.length) {
    final item = dataList[i];
    if (item is! Event) {
      i++;
      continue;
    }
    final String? login = item.actor?.login;
    if (login == null || login.isEmpty) {
      i++;
      continue;
    }
    int j = i + 1;
    while (j < dataList.length) {
      final next = dataList[j];
      if (next is! Event) break;
      if (next.actor?.login != login) break;
      j++;
    }
    final int runLength = j - i;
    if (runLength >= _kMinGroupSize) {
      final List<Event> events = <Event>[];
      for (int k = i; k < j; k++) {
        events.add(dataList[k] as Event);
      }
      spans[i] = EventGroupSpan(
        startIndex: i,
        endIndex: j - 1,
        events: events,
      );
    }
    i = j;
  }
  return spans;
}

/// 判断某个原始 index 是不是被 group 的 startIndex 覆盖掉了（应渲染为空占位）。
/// 用 [buildEventGroupSpans] 的结果反查：
/// 只要存在 span 使 startIndex < index <= endIndex，就返回 true。
///
/// 注意：这是 O(spans.length) 线性扫。itemBuilder 会对每一个 index 都调一次，
/// 长列表下等于 O(N × spans) 每帧。渲染路径请优先用 [EventGroupIndex]，
/// 那份是 O(1) hash-set 查询 + 单次 dataList 引用级缓存。
bool isConsumedGroupIndex(int index, Map<int, EventGroupSpan> spans) {
  for (final span in spans.values) {
    if (index > span.startIndex && index <= span.endIndex) {
      return true;
    }
  }
  return false;
}

/// 分组扫描结果的缓存视图。
///
/// 存在的意义：
/// - [buildEventGroupSpans] 是 O(N) 全表扫。
/// - [isConsumedGroupIndex] 是 O(spans) 线性扫。
/// - `ListView.builder` 会**为每个可见 index 都调一次 itemBuilder**，
///   如果直接在 itemBuilder 里 `buildEventGroupSpans(dataList)` 再
///   `isConsumedGroupIndex(...)`，长列表 (N > 200) 会退化到 O(N²)，
///   真机上表现为滚动掉帧。
///
/// 用法（父组件）：
/// ```dart
/// final index = EventGroupIndex.of(dataList);
/// // 在 itemBuilder 里
/// final span = index.headSpanAt(i);      // O(1)
/// if (span != null) return GSYEventGroupItem(span, ...);
/// if (index.isConsumed(i)) return const SizedBox.shrink();
/// return normalItem(i);
/// ```
///
/// 缓存策略：以 dataList 引用为键（[Expando]）+ length 作副键。
/// - loadMore 走 [List.addAll]，引用同一 List 但 length 变 → miss，会重扫。
/// - 未改数据的普通 rebuild：引用一致且 length 相同 → hit，0 次扫描。
/// - refresh 换新 List 引用：Expando 找不到条目 → miss，重扫；
///   旧 List 无强引用时 Expando 里的条目会随之被 GC 回收，无泄漏。
///
/// 多 tab 共存友好：动态 tab 和仓库详情 Activity tab 各自的 dataList 是
/// 不同 List 引用，Expando 里天然各占一个槽，互不覆盖。
class EventGroupIndex {
  final Map<int, EventGroupSpan> _headSpans;
  final Set<int> _consumedIndices;

  new _(this._headSpans, this._consumedIndices);

  /// group head 落在此 index 时返回对应 span；否则 null。O(1)。
  EventGroupSpan? headSpanAt(int index) => _headSpans[index];

  /// 该 index 是否被上游 group 的 startIndex 吞掉（应渲染 shrink）。O(1)。
  bool isConsumed(int index) => _consumedIndices.contains(index);

  /// 供调试 / 单测用。
  int get groupCount => _headSpans.length;

  /// 取给定 dataList 的分组索引。命中缓存则直接返回，否则重扫并缓存。
  static EventGroupIndex of(List<dynamic> dataList) {
    final cached = _cache[dataList];
    if (cached != null && cached.sourceLength == dataList.length) {
      return cached.index;
    }
    final Map<int, EventGroupSpan> headSpans = buildEventGroupSpans(dataList);
    final Set<int> consumed = <int>{};
    for (final span in headSpans.values) {
      for (int i = span.startIndex + 1; i <= span.endIndex; i++) {
        consumed.add(i);
      }
    }
    final built = EventGroupIndex._(headSpans, consumed);
    _cache[dataList] = _EventGroupIndexCacheEntry(
      sourceLength: dataList.length,
      index: built,
    );
    return built;
  }

  /// 手动清缓存。业务无需调用；仅测试 / 内存压力场景使用。
  ///
  /// 注意：`Expando` 无法整体清空，需要提供想清的 dataList。
  static void debugClearCacheFor(List<dynamic> dataList) {
    _cache[dataList] = null;
  }

  static final Expando<_EventGroupIndexCacheEntry> _cache =
      Expando<_EventGroupIndexCacheEntry>('EventGroupIndex');
}

class _EventGroupIndexCacheEntry {
  final int sourceLength;
  final EventGroupIndex index;
  new({
    required this.sourceLength,
    required this.index,
  });
}

/// 连续同用户事件折叠卡片。
///
/// 默认只渲染前 [kEventGroupInlineLimit] 条事件行；如果 group 事件总数超过该阈值，
/// 底部出现"展开剩余 N 条"按钮，点击后一次铺开所有事件。
/// 头像/用户名 在整张卡片顶部只显示一次；每一行事件展示 actionTarget + actionTime，
/// 保留原 [GSYEventItem] 的点击跳转行为（复用 [EventUtils.ActionUtils]）。
class GSYEventGroupItem extends StatefulWidget {
  final EventGroupSpan span;

  const new(this.span, {super.key});

  @override
  State<GSYEventGroupItem> createState() => _GSYEventGroupItemState();
}

class _GSYEventGroupItemState extends State<GSYEventGroupItem>
    with AutomaticKeepAliveClientMixin<GSYEventGroupItem> {
  bool _expanded = false;

  /// 只在用户主动点开"展开剩余 N 条"之后才保活。
  /// 这样默认折叠的 group 依然遵循 ListView 的 off-screen dispose，
  /// 只有用户明确展开过的组会跨越视口保持展开态，把内存代价压到最小。
  /// 手动 [updateKeepAlive] 会在切换 _expanded 时同步给上层的 KeepAlive element。
  @override
  bool get wantKeepAlive => _expanded;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final events = widget.span.events;
    final int total = events.length;
    final int visibleCount =
        _expanded ? total : (total <= kEventGroupInlineLimit ? total : kEventGroupInlineLimit);
    final int remaining = total - visibleCount;

    final Event first = events.first;
    final String actorLogin = first.actor?.login ?? '';
    final String actorAvatar = first.actor?.avatar_url ?? '';

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < visibleCount; i++) {
      final e = events[i];
      final vm = EventViewModel.fromEventMap(context, e);
      rows.add(_buildEventRow(context, e, vm, isLast: i == visibleCount - 1 && remaining == 0));
    }

    Widget? footer;
    if (remaining > 0) {
      footer = InkWell(
        onTap: () {
          setState(() {
            _expanded = true;
          });
          updateKeepAlive();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.l10n.event_group_expand_more(remaining),
                style: GSYConstant.smallActionLightText,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: GSYColors.actionBlue),
            ],
          ),
        ),
      );
    } else if (_expanded && total > kEventGroupInlineLimit) {
      footer = InkWell(
        onTap: () {
          setState(() {
            _expanded = false;
          });
          updateKeepAlive();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.l10n.event_group_collapse,
                style: GSYConstant.smallActionLightText,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_up,
                  size: 16, color: GSYColors.actionBlue),
            ],
          ),
        ),
      );
    }

    return GSYCardItem(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6, left: 12, right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                GSYUserIconWidget(
                  padding: const EdgeInsets.only(right: 8.0),
                  width: 34.0,
                  height: 34.0,
                  minTapTargetSize: null,
                  image: actorAvatar,
                  onPressed: () {
                    if (actorLogin.isNotEmpty) {
                      NavigatorUtils.goPerson(context, actorLogin);
                    }
                  },
                ),
                Expanded(
                  child: Text(actorLogin,
                      style: GSYConstant.smallTextBold, maxLines: 1),
                ),
                Text(
                  context.l10n.event_group_count(total),
                  style: GSYConstant.smallSubText,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...rows,
            if (footer != null) footer,
          ],
        ),
      ),
    );
  }

  Widget _buildEventRow(
      BuildContext context, Event event, EventViewModel vm,
      {required bool isLast}) {
    final target = vm.actionTarget ?? '';
    final des = vm.actionDes ?? '';
    return InkWell(
      onTap: () {
        EventUtils.ActionUtils(context, event, "");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast
                  ? Colors.transparent
                  : GSYColors.subLightTextColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    target,
                    style: GSYConstant.smallTextBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  CommonUtils.getNewsTimeStr(event.createdAt!),
                  style: GSYConstant.smallSubText,
                ),
              ],
            ),
            if (des.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  des,
                  style: GSYConstant.smallSubText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
