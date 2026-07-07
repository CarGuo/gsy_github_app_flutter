import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/page/dynamic/dynamic_bloc.dart';

/// B/1 单测：验证 [DynamicBloc.loadMoreData] 的分页去重契约。
///
/// 背景（roadmap §2.5）：GitHub `/users/{user}/received_events` 是流式列表，
/// 两次分页请求之间新事件持续涌入，第 N 页尾部与第 N+1 页头部会出现同一 `event.id`。
/// 旧实现直接 `pullLoadWidgetControl.addList(res.data)`，导致同一张卡片在上拉后
/// 重复出现，用户视角是"分页边界丢事件 / 抖动"。
///
/// 修复后 [DynamicBloc.loadMoreData] 应满足以下契约：
/// 1. **无重叠**：incoming 全部新 id → 全部 append，顺序保留
/// 2. **头尾重叠**：incoming 里已存在于 existing 的 id 被丢弃，其余保留原顺序 append
/// 3. **全重叠**：incoming 全是已存在的 id → dataList 长度不变
/// 4. **null id**：id 为 null 的事件不参与去重，一律 append（保守，不吞事件）
/// 5. **null res / null res.data**：不崩，dataList 保持不变
/// 6. **existing 优先**：同一 id 的新旧对象共存时，保留 existing 对象引用不变
Event _mkEvent(String? id, {String type = 'PushEvent'}) {
  return Event.fromJson({
    'id': id,
    'type': type,
    'actor': null,
    'repo': null,
    'org': null,
    'payload': null,
    'public': true,
    'created_at': null,
  });
}

DataResult _mkRes(List<Event> data) => DataResult(data, true);

void main() {
  group('DynamicBloc.loadMoreData 去重契约', () {
    test('无重叠：incoming 全部新 id 应全部 append', () {
      final bloc = DynamicBloc();
      bloc.refreshData(_mkRes([_mkEvent('1'), _mkEvent('2'), _mkEvent('3')]));
      bloc.loadMoreData(_mkRes([_mkEvent('4'), _mkEvent('5'), _mkEvent('6')]));
      final list = bloc.dataList as List;
      expect(list.length, 6);
      expect(list.map((e) => (e as Event).id).toList(),
          ['1', '2', '3', '4', '5', '6']);
    });

    test('头尾重叠：incoming 里已存在的 id 被丢弃，新 id 保留原顺序 append', () {
      final bloc = DynamicBloc();
      // page 1: 1,2,3
      bloc.refreshData(_mkRes([_mkEvent('1'), _mkEvent('2'), _mkEvent('3')]));
      // page 2: 3,4,5 —— 3 与 page1 尾部重叠
      bloc.loadMoreData(_mkRes([_mkEvent('3'), _mkEvent('4'), _mkEvent('5')]));
      final list = bloc.dataList as List;
      expect(list.length, 5, reason: '重复的 3 应被丢弃');
      expect(list.map((e) => (e as Event).id).toList(),
          ['1', '2', '3', '4', '5']);
    });

    test('全重叠：incoming 全部已存在 → dataList 长度不变', () {
      final bloc = DynamicBloc();
      bloc.refreshData(_mkRes([_mkEvent('1'), _mkEvent('2'), _mkEvent('3')]));
      bloc.loadMoreData(_mkRes([_mkEvent('1'), _mkEvent('2'), _mkEvent('3')]));
      final list = bloc.dataList as List;
      expect(list.length, 3);
      expect(list.map((e) => (e as Event).id).toList(), ['1', '2', '3']);
    });

    test('null id 的事件不参与去重，保守 append', () {
      final bloc = DynamicBloc();
      bloc.refreshData(_mkRes([_mkEvent('1'), _mkEvent(null)]));
      bloc.loadMoreData(_mkRes([_mkEvent(null), _mkEvent('2')]));
      final list = bloc.dataList as List;
      expect(list.length, 4, reason: 'null id 不应被识别成"重复"从而丢事件');
      expect(list.map((e) => (e as Event).id).toList(), ['1', null, null, '2']);
    });

    test('null res / null res.data / 空 data：不崩，dataList 不变', () {
      final bloc = DynamicBloc();
      bloc.refreshData(_mkRes([_mkEvent('1'), _mkEvent('2')]));
      bloc.loadMoreData(null);
      bloc.loadMoreData(DataResult(null, true));
      bloc.loadMoreData(_mkRes([]));
      final list = bloc.dataList as List;
      expect(list.length, 2);
      expect(list.map((e) => (e as Event).id).toList(), ['1', '2']);
    });

    test('existing 优先：同 id 的新对象不覆盖 existing 引用', () {
      final bloc = DynamicBloc();
      final oldE = _mkEvent('1', type: 'PushEvent');
      bloc.refreshData(_mkRes([oldE]));
      final newE = _mkEvent('1', type: 'ForkEvent');
      bloc.loadMoreData(_mkRes([newE, _mkEvent('2')]));
      final list = bloc.dataList as List;
      expect(list.length, 2);
      expect(identical(list[0], oldE), isTrue,
          reason: 'existing 对象引用应保留，避免 UI 卡片瞬时位移');
      expect((list[0] as Event).type, 'PushEvent',
          reason: '不被 incoming 的同 id 新对象覆盖');
      expect((list[1] as Event).id, '2');
    });

    test('三页连续 loadMore：每页尾部与下一页头部各重叠 1 条，合并后无重复', () {
      final bloc = DynamicBloc();
      // page 1: 1,2,3,4,5
      bloc.refreshData(_mkRes([
        _mkEvent('1'),
        _mkEvent('2'),
        _mkEvent('3'),
        _mkEvent('4'),
        _mkEvent('5'),
      ]));
      // page 2: 5,6,7,8,9 —— 5 与 page1 重叠
      bloc.loadMoreData(_mkRes([
        _mkEvent('5'),
        _mkEvent('6'),
        _mkEvent('7'),
        _mkEvent('8'),
        _mkEvent('9'),
      ]));
      // page 3: 9,10,11 —— 9 与 page2 重叠
      bloc.loadMoreData(_mkRes([
        _mkEvent('9'),
        _mkEvent('10'),
        _mkEvent('11'),
      ]));
      final list = bloc.dataList as List;
      expect(list.length, 11, reason: '5+4+2=11，两处边界重叠各丢 1 条');
      expect(list.map((e) => (e as Event).id).toList(),
          ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11']);
    });
  });
}
