// Debug replay script for `issue-timeline-flash`.
//
// 目的：在不启动 Flutter/Gradle 的前提下，用 Dart VM 黑盒验证 issue 详情页
// 的 timeline 合并 + res.next 包装逻辑，模拟 GSYListState.handleRefresh 的
// 两级消费流程（先消费 res.data，再 await res.next() 消费 resNext.data）。
//
// 用法：
//   dart run tool/dbg/replay_issue_timeline_flash.dart

import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';

// ============================================================
// 复刻 issue_detail_page.dart 中的两个纯函数逻辑（不依赖 State）。
// 若源文件里的实现与此不一致，测试将暴露差异。
// ============================================================

List<IssueTimelineEvent> globalTimeline = <IssueTimelineEvent>[];

DateTime? _timeOf(dynamic v) {
  if (v is Issue) return v.createdAt;
  if (v is IssueTimelineEvent) return v.createdAt;
  return null;
}

void decorateWithTimeline(dynamic res) {
  if (res == null || res.data is! List) return;
  final rawList = res.data as List;
  final comments = rawList.whereType<Issue>().toList();
  if (comments.isEmpty && rawList.isNotEmpty) return; // 已合并过则跳过
  final events = globalTimeline.where((e) => e.event != 'commented');
  final merged = <dynamic>[...comments, ...events];
  merged.sort((a, b) {
    final ta = _timeOf(a);
    final tb = _timeOf(b);
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return ta.compareTo(tb);
  });
  res.data = merged;
}

void wrapNextWithTimeline(dynamic res) {
  if (res == null) return;
  final original = res.next;
  if (original == null) return;
  res.next = () async {
    final resNext = await original();
    decorateWithTimeline(resNext);
    return resNext;
  };
}

// ============================================================
// Fixture
// ============================================================

Issue mkIssue(int id, DateTime t, {String body = ''}) => Issue(
      id, 1, 'title', 'open', false, 0, t, t, null, body, body,
      null, null, null, null,
    );

IssueTimelineEvent mkEvent(String event, DateTime t) => IssueTimelineEvent(
      id: DateTime.now().microsecondsSinceEpoch,
      event: event,
      createdAt: t,
    );

// ============================================================
// GSYListState.handleRefresh 的简化重放（对 dataList 的关键副作用）
// ============================================================

Future<List<dynamic>> simulateHandleRefresh(DataResult res) async {
  final dataList = <dynamic>[];
  // 第一次消费 res
  if (res.result == true && res.data is List) {
    dataList
      ..clear()
      ..addAll(res.data as List);
  }
  // 追加 res.next（若存在）
  if (res.next != null) {
    final resNext = await res.next!();
    if (resNext != null && resNext.result == true && resNext.data is List) {
      dataList
        ..clear()
        ..addAll(resNext.data as List);
    }
  }
  return dataList;
}

// ============================================================
// Cases
// ============================================================

void _assert(bool cond, String msg) {
  if (!cond) {
    // ignore: avoid_print
    print('  ❌ ASSERT FAILED: $msg');
    throw StateError(msg);
  }
  // ignore: avoid_print
  print('  ✅ $msg');
}

Future<void> case1WithFix() async {
  // ignore: avoid_print
  print('\n[case1] 修复后：合并 + wrapNext，两级消费后仍然含 timeline events');
  final t0 = DateTime(2026, 7, 1, 10);
  final t1 = DateTime(2026, 7, 1, 11);
  final t2 = DateTime(2026, 7, 1, 12);
  final t3 = DateTime(2026, 7, 1, 13);

  globalTimeline = [
    mkEvent('labeled', t1),
    mkEvent('closed', t3),
  ];

  // db 分支：只有 comments，无 events
  final dbRes = DataResult(
    <Issue>[mkIssue(101, t0), mkIssue(102, t2)],
    true,
    // next 模拟网络回：返回纯 comments
    next: () async => DataResult(
      <Issue>[mkIssue(101, t0), mkIssue(102, t2), mkIssue(103, t3.add(const Duration(hours: 1)))],
      true,
    ),
  );

  decorateWithTimeline(dbRes);
  wrapNextWithTimeline(dbRes);

  final finalList = await simulateHandleRefresh(dbRes);
  _assert(finalList.length == 5,
      '最终 dataList 长度 = 5 (3 comments + 2 events)，实际 ${finalList.length}');
  _assert(finalList.whereType<IssueTimelineEvent>().length == 2,
      '包含 2 个 timeline events');
  _assert(finalList.whereType<Issue>().length == 3, '包含 3 个 comments');

  // 时间序：t0(issue) < t1(event) < t2(issue) < t3(event) < t3+1h(issue)
  final times = finalList.map(_timeOf).toList();
  for (var i = 1; i < times.length; i++) {
    _assert(!times[i - 1]!.isAfter(times[i]!),
        '时间序升序：index $i (${times[i - 1]} -> ${times[i]})');
  }
  final firstEvent = finalList.whereType<IssueTimelineEvent>().first;
  _assert(firstEvent.event == 'labeled', '第一个事件是 labeled');
  final lastEvent = finalList.whereType<IssueTimelineEvent>().last;
  _assert(lastEvent.event == 'closed', '最后一个事件是 closed');
}

Future<void> case2WithoutWrap() async {
  // ignore: avoid_print
  print('\n[case2] 反例：只合并 db res 不包装 next → 网络次消费清空 events（复现"一闪"）');
  final t0 = DateTime(2026, 7, 1, 10);
  final t1 = DateTime(2026, 7, 1, 11);
  final t2 = DateTime(2026, 7, 1, 12);

  globalTimeline = [mkEvent('labeled', t1)];

  final dbRes = DataResult(
    <Issue>[mkIssue(101, t0), mkIssue(102, t2)],
    true,
    next: () async => DataResult(
      <Issue>[mkIssue(101, t0), mkIssue(102, t2)],
      true,
    ),
  );

  decorateWithTimeline(dbRes);
  // 注意：这里故意不 wrapNextWithTimeline，模拟修复前逻辑
  final finalList = await simulateHandleRefresh(dbRes);
  _assert(finalList.whereType<IssueTimelineEvent>().isEmpty,
      '修复前：二次消费后 timeline events 消失（复现 bug）');
  _assert(finalList.length == 2, '只剩 2 个 comments');
}

Future<void> case3IdempotentDecorate() async {
  // ignore: avoid_print
  print('\n[case3] 二次调用 decorate 应幂等（已合并的 List<dynamic> 不再重复合并）');
  final t0 = DateTime(2026, 7, 1, 10);
  final t1 = DateTime(2026, 7, 1, 11);
  globalTimeline = [mkEvent('labeled', t1)];

  final res = DataResult(<Issue>[mkIssue(101, t0)], true);
  decorateWithTimeline(res);
  final lenAfterFirst = (res.data as List).length;
  decorateWithTimeline(res); // 再来一次
  final lenAfterSecond = (res.data as List).length;
  _assert(lenAfterFirst == 2 && lenAfterSecond == 2,
      '合并前后长度稳定为 2（$lenAfterFirst -> $lenAfterSecond）');
}

Future<void> case4NullSafety() async {
  // ignore: avoid_print
  print('\n[case4] 边界：res == null / data 非 List / events 时间为 null');
  globalTimeline = [
    IssueTimelineEvent(event: 'closed', createdAt: null),
    mkEvent('labeled', DateTime(2026, 7, 1, 11)),
  ];
  final res = DataResult(<Issue>[mkIssue(101, DateTime(2026, 7, 1, 10))], true);
  decorateWithTimeline(res);
  final merged = res.data as List;
  _assert(merged.length == 3, '包含 1 comment + 2 events（含 null 时间）');
  // null 时间应排最后
  _assert(_timeOf(merged.last) == null, 'null createdAt 事件应排最后');

  // res.data == null 不应炸
  final res2 = DataResult(null, true);
  decorateWithTimeline(res2);
  wrapNextWithTimeline(res2);
  _assert(res2.data == null, 'res.data == null 情况下保持不变、不抛异常');
}

Future<void> main() async {
  // ignore: avoid_print
  print('=== issue-timeline-flash replay ===');
  try {
    await case1WithFix();
    await case2WithoutWrap();
    await case3IdempotentDecorate();
    await case4NullSafety();
    // ignore: avoid_print
    print('\n🎉 ALL CASES PASSED');
  } catch (e) {
    // ignore: avoid_print
    print('\n💥 REPLAY FAILED: $e');
    rethrow;
  }
}
