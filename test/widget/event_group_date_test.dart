import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_group_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_new_load_widget.dart';

// 2026-10-21：组件回归使用真实模型解析和 widget；不替代设备冒烟证据。
const _avatarUrl = 'https://example.invalid/event-date-avatar.png';

Event _event(
  String id,
  String actor, {
  Map<String, dynamic> fields = const {},
}) => Event.fromJson({
  'id': id,
  'type': 'WatchEvent',
  'actor': {'login': actor, 'avatar_url': _avatarUrl},
  'repo': {'name': 'fixture/repository-$id'},
  ...fields,
});

Future<void> _cacheAvatar(WidgetTester tester) async {
  // 使用 Flutter 官方测试图片和 ImageCache 隔离 HTTP，日期断言不依赖头像失败。
  final image = await tester.runAsync(() => createTestImage());
  PaintingBinding.instance.imageCache.putIfAbsent(
    const NetworkImage(_avatarUrl),
    () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image!))),
  );
}

Widget _list(GSYPullLoadWidgetControl control) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(
    body: ListenableBuilder(
      listenable: control,
      builder: (context, _) {
        final events = List<Event>.from(control.dataList!);
        final groups = EventGroupIndex.of(events);
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final span = groups.headSpanAt(index);
            if (span != null) {
              return GSYEventGroupItem(
                span,
                key: ValueKey('group_${span.stableKey}'),
              );
            }
            if (groups.isConsumed(index)) return const SizedBox.shrink();
            return GSYEventItem(
              EventViewModel.fromEventMap(context, events[index]),
              key: ValueKey(events[index].id),
              needImage: false,
            );
          },
        );
      },
    ),
  ),
);

void main() {
  setUp(() {
    final previous = CommonUtils.curLocale;
    CommonUtils.curLocale = const Locale('en');
    addTearDown(() => CommonUtils.curLocale = previous);
  });

  testWidgets(
    'missing dates keep single-row semantics when groups split and merge',
    (tester) async {
      await _cacheAvatar(tester);
      final control = GSYPullLoadWidgetControl();
      addTearDown(control.dispose);
      final omittedDate = _event('omitted', 'alice');
      final nullDate = _event('null', 'alice', fields: {'created_at': null});
      expect(omittedDate.createdAt, isNull);
      expect(nullDate.createdAt, isNull);

      control.dataList = [omittedDate];
      await tester.pumpWidget(_list(control));
      await tester.pumpAndSettle();
      expect(find.byType(GSYEventItem), findsOneWidget);
      expect(find.text('right now'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      Future<void> verifyRefresh(
        List<Event> events, {
        required bool grouped,
      }) async {
        control.dataList = events;
        await tester.pumpAndSettle();
        expect(
          find.byType(GSYEventGroupItem),
          grouped ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(GSYEventItem),
          grouped ? findsNothing : findsNWidgets(2),
        );
        expect(find.text('right now'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
      }

      await verifyRefresh([omittedDate, nullDate], grouped: true);
      await verifyRefresh([
        omittedDate,
        _event('null', 'bob', fields: {'created_at': null}),
      ], grouped: false);
      await verifyRefresh([omittedDate, nullDate], grouped: true);
    },
  );

  testWidgets(
    'dated rows show the same source date before and after grouping',
    (tester) async {
      await _cacheAvatar(tester);
      final control = GSYPullLoadWidgetControl();
      addTearDown(control.dispose);
      final dated = _event(
        'dated',
        'alice',
        fields: {'created_at': '2020-01-02T03:04:05Z'},
      );
      control.dataList = [dated];
      await tester.pumpWidget(_list(control));
      await tester.pumpAndSettle();
      expect(find.text('2020-01-02'), findsOneWidget);
      expect(tester.takeException(), isNull);

      control.dataList = [dated, _event('missing', 'alice')];
      await tester.pumpAndSettle();
      expect(find.byType(GSYEventGroupItem), findsOneWidget);
      expect(find.text('2020-01-02'), findsOneWidget);
      expect(find.text('right now'), findsOneWidget);
      expect(dated.createdAt, DateTime.utc(2020, 1, 2, 3, 4, 5));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    },
  );
}
