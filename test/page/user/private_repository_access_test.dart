import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/page/common_list_page.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_header.dart';

void main() {
  group('issue #943 private repository access', () {
    test('public profile endpoint remains public-user scoped', () {
      expect(
        Address.userRepos('CarSmallGuo', null),
        'https://api.github.com/users/CarSmallGuo/repos?sort=pushed',
      );
    });

    test('authenticated endpoint requests all owned repositories', () {
      expect(
        Address.authenticatedUserRepos(null),
        'https://api.github.com/user/repos?visibility=all&affiliation=owner&sort=pushed',
      );
      expect(
        Address.authenticatedUserRepos('updated'),
        'https://api.github.com/user/repos?visibility=all&affiliation=owner&sort=updated',
      );
    });

    test('a successful empty response is authoritative and clears old data', () {
      final result = ReposRepository.parseUserRepositoryResponse(true, []);

      expect(result.result, isTrue);
      expect(result.data, isEmpty);
    });

    test('a failed or malformed response is not treated as an empty account', () {
      final failed = ReposRepository.parseUserRepositoryResponse(false, []);
      final malformed =
          ReposRepository.parseUserRepositoryResponse(true, <String, dynamic>{});

      expect(failed.result, isFalse);
      expect(failed.data, isNull);
      expect(malformed.result, isFalse);
      expect(malformed.data, isNull);
    });

    test('an authenticated request exception clears sensitive rows first', () async {
      var cleared = false;

      await expectLater(
        runAuthenticatedRepositoryRequest(
          () => Future<dynamic>.error(StateError('malformed repository row')),
          () => cleared = true,
        ),
        throwsA(isA<StateError>()),
      );
      expect(cleared, isTrue);
    });

    test('an authenticated failure result also clears sensitive rows', () async {
      var cleared = false;

      final result = await runAuthenticatedRepositoryRequest(
        () async => ReposRepository.parseUserRepositoryResponse(false, []),
        () => cleared = true,
      );

      expect(result.result, isFalse);
      expect(cleared, isTrue);
    });

    test('authenticated count includes only owned private repositories', () {
      final profileUser = User.empty()
        ..login = 'carsmallguo'
        ..public_repos = 4;
      final authenticatedUser = User.empty()
        ..login = 'CarSmallGuo'
        ..public_repos = 4
        ..owned_private_repos = 3
        ..total_private_repos = 9;

      expect(
        UserHeaderBottom.repositoryCount(profileUser, authenticatedUser),
        7,
      );
      expect(
        UserHeaderBottom.repositoryCount(profileUser, null),
        4,
      );
    });

    test('authenticated count preserves partial GitHub user payloads', () {
      final profileUser = User.empty()
        ..login = 'CarSmallGuo'
        ..public_repos = 4;
      final publicOnly = User.empty()
        ..login = 'CarSmallGuo'
        ..public_repos = 4;
      final privateOnly = User.empty()
        ..login = 'CarSmallGuo'
        ..owned_private_repos = 3;

      expect(
        UserHeaderBottom.repositoryCount(profileUser, publicOnly),
        4,
      );
      expect(
        UserHeaderBottom.repositoryCount(profileUser, privateOnly),
        7,
      );
    });

    test('a different profile never receives authenticated repository data', () {
      final profileUser = User.empty()
        ..login = 'CarGuo'
        ..public_repos = 6;
      final authenticatedUser = User.empty()
        ..login = 'CarSmallGuo'
        ..public_repos = 4
        ..owned_private_repos = 3;

      expect(
        UserHeaderBottom.isAuthenticatedUserProfile(
          profileUser,
          authenticatedUser,
        ),
        isFalse,
      );
      expect(
        UserHeaderBottom.repositoryCount(profileUser, authenticatedUser),
        6,
      );
    });
  });
}
