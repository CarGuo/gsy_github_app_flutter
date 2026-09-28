import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_group_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_new_load_widget.dart';

// Component regression only: synthetic events are not device business evidence.
Event event(String id, String login) => Event.fromJson({
  'id': id,
  'type': 'PushEvent',
  'actor': {'login': login},
});

void main() {
  test('same-length in-place refresh replaces grouped events and grouping', () {
    final control = GSYPullLoadWidgetControl();
    addTearDown(control.dispose);
    control.dataList = [event('old-1', 'alice'), event('old-2', 'alice')];
    final data = control.dataList!;
    expect(EventGroupIndex.of(data).headSpanAt(0)!.events.first.id, 'old-1');
    control.dataList = [event('new-1', 'bob'), event('new-2', 'bob')];
    expect(identical(control.dataList, data), isTrue);
    final refreshed = EventGroupIndex.of(data);
    expect(refreshed.headSpanAt(0)!.events.map((e) => e.id), [
      'new-1',
      'new-2',
    ]);
    control.dataList = [event('new-1', 'bob'), event('new-2', 'carol')];
    expect(EventGroupIndex.of(data).groupCount, 0);
  });

  test('pagination extends a group while retaining its stable identity', () {
    final data = [event('first', 'alice'), event('second', 'alice')];
    final before = EventGroupIndex.of(data).headSpanAt(0)!;
    data.add(event('third', 'alice'));
    final after = EventGroupIndex.of(data);
    expect(after.headSpanAt(0)!.stableKey, before.stableKey);
    expect(after.headSpanAt(0)!.events.map((e) => e.id), [
      'first',
      'second',
      'third',
    ]);
    expect(after.isConsumed(2), isTrue);
  });
}
