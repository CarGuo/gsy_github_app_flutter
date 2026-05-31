import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/app.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/env/config_wrapper.dart';
import 'package:gsy_github_app_flutter/env/dev.dart' as dev_env;
import 'package:gsy_github_app_flutter/env/env_config.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  patrolTest('guest startup reaches login and opens OAuth webview', ($) async {
    await _pumpApp($, preferences: _guestPreferences());

    await $('Login').waitUntilVisible(timeout: _routeTimeout);
    expect($('Username'), findsOneWidget);
    expect($('Password'), findsOneWidget);

    await $('OAuth').tap();
    await $('OAuth').waitUntilVisible(timeout: _routeTimeout);
    expect(find.byType(AppBar), findsOneWidget);
  }, timeout: _testTimeout);

  patrolTest(
    'signed-in shell regression covers tabs drawer settings and logout',
    ($) async {
      await _pumpApp($, preferences: _signedInPreferences());

      await $('GSYGithubApp').waitUntilVisible(timeout: _routeTimeout);
      await $('Dynamic').waitUntilVisible(timeout: _routeTimeout);
      await $('Trend').tap();
      await $('Dynamic').tap();

      await $(Icons.menu).tap();
      await $('patrol-regression').waitUntilVisible(timeout: _routeTimeout);

      await $('Theme').tap();
      await $('Theme 2').waitUntilVisible(timeout: _routeTimeout);
      await $('Theme 2').tap();
      await $.tester.pump(_shortWait);

      await $('Language').tap();
      await $('English').waitUntilVisible(timeout: _routeTimeout);
      await $('English').tap();
      await $.tester.pump(_shortWait);

      await $('Grey').tap();
      await $('Logout').tap();
      await $('Login').waitUntilVisible(timeout: _routeTimeout);
    },
    timeout: _testTimeout,
  );
}

const _routeTimeout = Duration(seconds: 20);
const _shortWait = Duration(milliseconds: 500);
const _testTimeout = Timeout(Duration(minutes: 3));
const _githubToken = String.fromEnvironment('PATROL_GITHUB_TOKEN');

Future<void> _pumpApp(
  PatrolIntegrationTester $, {
  required Map<String, Object> preferences,
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(preferences);
  await $.tester.pumpWidget(
    ConfigWrapper(
      config: EnvConfig.fromJson(dev_env.config),
      child: const FlutterReduxApp(),
    ),
  );

  await $.tester.pump(const Duration(seconds: 5));
}

Map<String, Object> _guestPreferences() {
  return {Config.LOCALE: '2', Config.VIBRATION_ENABLE: 'true'};
}

Map<String, Object> _signedInPreferences() {
  return {
    Config.TOKEN_KEY: _authorizationHeader(),
    Config.USER_INFO: jsonEncode(_fakeUserInfo()),
    Config.LOCALE: '2',
    Config.VIBRATION_ENABLE: 'true',
  };
}

String _authorizationHeader() {
  final token = _githubToken.trim();
  if (token.isEmpty) {
    return 'token patrol-regression-token';
  }
  return token.startsWith('token ') ? token : 'token $token';
}

Map<String, Object?> _fakeUserInfo() {
  return {
    'login': 'patrol-regression',
    'id': 1,
    'node_id': 'PATROL_REGRESSION',
    'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
    'gravatar_id': '',
    'url': 'https://api.github.com/users/patrol-regression',
    'html_url': 'https://github.com/patrol-regression',
    'followers_url': 'https://api.github.com/users/patrol-regression/followers',
    'following_url':
        'https://api.github.com/users/patrol-regression/following{/other_user}',
    'gists_url':
        'https://api.github.com/users/patrol-regression/gists{/gist_id}',
    'starred_url':
        'https://api.github.com/users/patrol-regression/starred{/owner}{/repo}',
    'subscriptions_url':
        'https://api.github.com/users/patrol-regression/subscriptions',
    'organizations_url': 'https://api.github.com/users/patrol-regression/orgs',
    'repos_url': 'https://api.github.com/users/patrol-regression/repos',
    'events_url':
        'https://api.github.com/users/patrol-regression/events{/privacy}',
    'received_events_url':
        'https://api.github.com/users/patrol-regression/received_events',
    'type': 'User',
    'site_admin': false,
    'name': 'Patrol Regression',
    'company': null,
    'blog': '',
    'location': 'CI',
    'email': 'patrol@example.com',
    'starred': '0',
    'bio': 'Local regression fixture',
    'public_repos': 0,
    'public_gists': 0,
    'followers': 0,
    'following': 0,
    'created_at': '2020-01-01T00:00:00.000Z',
    'updated_at': '2020-01-01T00:00:00.000Z',
    'private_gists': 0,
    'total_private_repos': 0,
    'owned_private_repos': 0,
    'disk_usage': 0,
    'collaborators': 0,
    'two_factor_authentication': false,
  };
}
