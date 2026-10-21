import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/page/user/base_person_provider.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_header.dart';
import 'package:gsy_github_app_flutter/widget/only_share_widget.dart';

void main() {
  testWidgets('honor waits for profile identity and remains refreshable', (
    tester,
  ) async {
    final requests = <String, int>{};
    var generation = 1;
    final container = ProviderContainer(
      overrides: [
        fetchHonorDataProvider.overrideWith((ref, login) async {
          requests.update(login, (value) => value + 1, ifAbsent: () => 1);
          return HonorModel.fromJson({'stared': generation, 'list': []});
        }),
      ],
    );
    addTearDown(container.dispose);

    Future<void> showHeader(User profile) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: OnlyShareInstanceWidget(
                value: fetchHonorDataProvider(profile.login ?? 'route-user'),
                child: UserHeaderBottom(profile, const Radius.circular(10)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder honorValue(String value) => find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().endsWith('\n$value'),
    );

    // 2026-10-21: 回归空资料首帧→有效资料→多次主动失效→用户身份切换。
    // provider override 只替换异步数据源，保留真实 Header/Riverpod 订阅边界。
    await showHeader(User.empty());
    expect(requests, isEmpty);
    expect(honorValue('---'), findsOneWidget);

    final person = User.empty()..login = 'first-user';
    await showHeader(person);
    expect(requests, {'first-user': 1});
    expect(honorValue('1'), findsOneWidget);

    await showHeader(person);
    expect(requests, {
      'first-user': 1,
    }, reason: 'Rebuild reuses the same request');

    for (generation = 2; generation <= 4; generation++) {
      container.invalidate(fetchHonorDataProvider('first-user'));
      await tester.pump();
      await tester.pump();
      expect(requests, {'first-user': generation});
      expect(honorValue('$generation'), findsOneWidget);
    }

    generation = 10;
    await showHeader(User.empty()..login = 'second-user');
    expect(requests, {'first-user': 4, 'second-user': 1});
    expect(honorValue('10'), findsOneWidget);
    expect(honorValue('4'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
