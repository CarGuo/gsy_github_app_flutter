import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/model/search_user_ql.dart';

void main() {
  group('SearchUserQL.fromMap - 常规映射', () {
    test('完整 payload 解析并取第一门语言', () {
      final u = SearchUserQL.fromMap({
        'followers': {'totalCount': 128},
        'name': 'CarGuo',
        'avatarUrl': 'https://avatars.githubusercontent.com/u/1',
        'bio': 'GSY',
        'login': 'CarGuo',
        'lang': {
          'nodes': [
            {
              'languages': {
                'nodes': [
                  {'name': 'Dart'},
                  {'name': 'Java'},
                ],
              },
            },
          ],
        },
      });
      expect(u.followers, 128);
      expect(u.name, 'CarGuo');
      expect(u.avatarUrl, contains('avatars.githubusercontent.com'));
      expect(u.bio, 'GSY');
      expect(u.login, 'CarGuo');
      expect(u.lang, 'Dart', reason: '只取 languages.nodes[0].name');
    });

    test('fromMap 返回值静态类型必须是 SearchUserQL（防止倒退回 dynamic）', () {
      final SearchUserQL u = SearchUserQL.fromMap({'login': 'CarGuo'});
      expect(u.login, 'CarGuo');
      final SearchUserQL Function(Map) f = SearchUserQL.fromMap;
      expect(f, isNotNull);
    });
  });

  group('SearchUserQL.fromMap - 健壮性', () {
    test('followers 字段缺失时为 null', () {
      final u = SearchUserQL.fromMap({'login': 'CarGuo'});
      expect(u.followers, isNull);
      expect(u.login, 'CarGuo');
    });

    test('lang.nodes 为空数组时 lang 保持 null', () {
      final u = SearchUserQL.fromMap({
        'lang': {'nodes': []},
      });
      expect(u.lang, isNull);
    });

    test('lang.nodes[0].languages 缺失时 lang 保持 null', () {
      final u = SearchUserQL.fromMap({
        'lang': {
          'nodes': [
            {'other': 'x'},
          ],
        },
      });
      expect(u.lang, isNull);
    });

    test('languages.nodes 为空数组时 lang 保持 null', () {
      final u = SearchUserQL.fromMap({
        'lang': {
          'nodes': [
            {
              'languages': {'nodes': []},
            },
          ],
        },
      });
      expect(u.lang, isNull);
    });

    test('守卫全过但最内层 name 缺失时 lang 保持 null', () {
      final u = SearchUserQL.fromMap({
        'lang': {
          'nodes': [
            {
              'languages': {
                'nodes': [
                  <String, dynamic>{},
                ],
              },
            },
          ],
        },
      });
      expect(u.lang, isNull);
    });

    test('空 map 不 crash 且所有字段为 null', () {
      final u = SearchUserQL.fromMap({});
      expect(u.followers, isNull);
      expect(u.name, isNull);
      expect(u.avatarUrl, isNull);
      expect(u.bio, isNull);
      expect(u.login, isNull);
      expect(u.lang, isNull);
    });
  });

  group('SearchUserQL.fromMap - 类型防护（防止 GraphQL schema 漂移到 UI 才崩）', () {
    test('followers 是 double 时正确 toInt', () {
      final u = SearchUserQL.fromMap({
        'followers': {'totalCount': 128.0},
      });
      expect(u.followers, 128);
    });

    test('followers 直接是 int 而不是 {totalCount} 包裹时降级为 null，不 crash', () {
      final u = SearchUserQL.fromMap({'followers': 42});
      expect(u.followers, isNull,
          reason: 'GraphQL 契约要求 followers 是 {totalCount} 对象');
    });

    test('followers.totalCount 是 String 时按契约抛 TypeError', () {
      expect(
        () => SearchUserQL.fromMap({
          'followers': {'totalCount': '42'},
        }),
        throwsA(isA<TypeError>()),
        reason: 'GraphQL 契约保证 totalCount 是 num，收到 String 应该显式失败',
      );
    });

    test('name / avatarUrl / bio / login 是非 String 类型时按契约抛 TypeError', () {
      expect(() => SearchUserQL.fromMap({'name': 123}),
          throwsA(isA<TypeError>()));
      expect(() => SearchUserQL.fromMap({'avatarUrl': 123}),
          throwsA(isA<TypeError>()));
      expect(() => SearchUserQL.fromMap({'login': true}),
          throwsA(isA<TypeError>()));
    });

    test('lang 顶层不是 Map 而是 List 时降级为 null，不 NoSuchMethodError', () {
      final u = SearchUserQL.fromMap({'lang': []});
      expect(u.lang, isNull);
    });

    test('lang.nodes 不是 List 而是 Map 时降级为 null，不 crash', () {
      final u = SearchUserQL.fromMap({
        'lang': {'nodes': {}},
      });
      expect(u.lang, isNull);
    });

    test('lang.nodes[0] 不是 Map 而是 String 时降级为 null，不 crash', () {
      final u = SearchUserQL.fromMap({
        'lang': {
          'nodes': ['unexpected-string'],
        },
      });
      expect(u.lang, isNull);
    });
  });
}
