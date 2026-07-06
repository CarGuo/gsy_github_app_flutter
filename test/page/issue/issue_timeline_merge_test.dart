import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';

///
/// issue-timeline-flash 回归测试。
///
/// 背景：`IssueDetailPageState` 通过 `_decorateWithTimeline` + `_wrapNextWithTimeline`
/// 把 timeline 事件穿插到 comments 列表中；`GSYListState.handleRefresh` 会两级消费
/// （先 res.data，再 await res.next()），如果第二级没有再次合并 timeline，
/// 网络分支会覆盖 db 分支的合并结果 —— 用户表现为 "一闪就没"。
///
/// 本文件把 `tool/dbg/replay_issue_timeline_flash.dart` 中的纯函数契约
/// 沉淀为 CI 可执行的黑盒测试。若生产实现语义改动，需同步更新此契约。
///

List<IssueTimelineEvent> _timelineEvents = <IssueTimelineEvent>[];

DateTime? _timeOf(dynamic v) {
  if (v is Issue) return v.createdAt;
  if (v is IssueTimelineEvent) return v.createdAt;
  return null;
}

void _decorateWithTimeline(dynamic res) {
  if (res == null || res.data is! List) return;
  final rawList = res.data as List;
  final comments = rawList.whereType<Issue>().toList();
  if (comments.isEmpty && rawList.isNotEmpty) return;
  final events = _timelineEvents.where((e) => e.event != 'commented');
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

void _wrapNextWithTimeline(dynamic res) {
  if (res == null) return;
  final original = res.next;
  if (original == null) return;
  res.next = () async {
    final resNext = await original();
    _decorateWithTimeline(resNext);
    return resNext;
  };
}

Issue _mkIssue(int id, DateTime t) => Issue(
      id, 1, 'title', 'open', false, 0, t, t, null, '', '',
      null, null, null, null,
    );

IssueTimelineEvent _mkEvent(String event, DateTime? t) => IssueTimelineEvent(
      id: DateTime.now().microsecondsSinceEpoch,
      event: event,
      createdAt: t,
    );

Future<List<dynamic>> _simulateHandleRefresh(DataResult res) async {
  final dataList = <dynamic>[];
  if (res.result == true && res.data is List) {
    dataList
      ..clear()
      ..addAll(res.data as List);
  }
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

void main() {
  setUp(() {
    _timelineEvents = <IssueTimelineEvent>[];
  });

  group('issue-timeline-flash 合并契约', () {
    test('case1: 合并 + wrapNext 后，两级消费仍保留 timeline events', () async {
      final t0 = DateTime.utc(2026, 7, 1, 10);
      final t1 = DateTime.utc(2026, 7, 1, 11);
      final t2 = DateTime.utc(2026, 7, 1, 12);
      final t3 = DateTime.utc(2026, 7, 1, 13);

      _timelineEvents = [
        _mkEvent('labeled', t1),
        _mkEvent('closed', t3),
      ];

      final dbRes = DataResult(
        <Issue>[_mkIssue(101, t0), _mkIssue(102, t2)],
        true,
        next: () async => DataResult(
          <Issue>[
            _mkIssue(101, t0),
            _mkIssue(102, t2),
            _mkIssue(103, t3.add(const Duration(hours: 1))),
          ],
          true,
        ),
      );

      _decorateWithTimeline(dbRes);
      _wrapNextWithTimeline(dbRes);

      final finalList = await _simulateHandleRefresh(dbRes);

      expect(finalList.length, 5, reason: '3 comments + 2 events');
      expect(finalList.whereType<IssueTimelineEvent>().length, 2);
      expect(finalList.whereType<Issue>().length, 3);

      final times = finalList.map(_timeOf).toList();
      for (var i = 1; i < times.length; i++) {
        expect(times[i - 1]!.isAfter(times[i]!), isFalse,
            reason: '时间序升序 (index $i)');
      }
      expect(finalList.whereType<IssueTimelineEvent>().first.event, 'labeled');
      expect(finalList.whereType<IssueTimelineEvent>().last.event, 'closed');
    });

    test('case2: 未包装 next 时二次消费会清空 events（复现 bug）', () async {
      final t0 = DateTime.utc(2026, 7, 1, 10);
      final t1 = DateTime.utc(2026, 7, 1, 11);
      final t2 = DateTime.utc(2026, 7, 1, 12);

      _timelineEvents = [_mkEvent('labeled', t1)];

      final dbRes = DataResult(
        <Issue>[_mkIssue(101, t0), _mkIssue(102, t2)],
        true,
        next: () async => DataResult(
          <Issue>[_mkIssue(101, t0), _mkIssue(102, t2)],
          true,
        ),
      );

      _decorateWithTimeline(dbRes);
      // 故意不 wrap，模拟修复前逻辑
      final finalList = await _simulateHandleRefresh(dbRes);
      expect(finalList.whereType<IssueTimelineEvent>(), isEmpty,
          reason: '未包装 next 时事件被覆盖');
      expect(finalList.length, 2);
    });

    test('case3: 二次调用 decorate 幂等', () {
      _timelineEvents = [_mkEvent('labeled', DateTime.utc(2026, 7, 1, 11))];
      final res = DataResult(
          <Issue>[_mkIssue(101, DateTime.utc(2026, 7, 1, 10))], true);

      _decorateWithTimeline(res);
      final lenAfterFirst = (res.data as List).length;
      _decorateWithTimeline(res);
      final lenAfterSecond = (res.data as List).length;

      expect(lenAfterFirst, 2);
      expect(lenAfterSecond, 2, reason: '合并后长度稳定');
    });

    test('case4: 边界 —— null createdAt 排最后 & res.data == null 不抛异常', () {
      _timelineEvents = [
        _mkEvent('closed', null),
        _mkEvent('labeled', DateTime.utc(2026, 7, 1, 11)),
      ];
      final res =
          DataResult(<Issue>[_mkIssue(101, DateTime.utc(2026, 7, 1, 10))], true);
      _decorateWithTimeline(res);
      final merged = res.data as List;
      expect(merged.length, 3);
      expect(_timeOf(merged.last), isNull);

      final res2 = DataResult(null, true);
      expect(() {
        _decorateWithTimeline(res2);
        _wrapNextWithTimeline(res2);
      }, returnsNormally);
      expect(res2.data, isNull);
    });
  });
}
