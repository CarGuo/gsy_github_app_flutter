import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/model/code_search_item.dart';

void main() {
  group('CodeSearchItem.fromJson - 常规映射', () {
    test('完整 payload 全字段落位', () {
      final item = CodeSearchItem.fromJson({
        'name': 'main.dart',
        'path': 'lib/main.dart',
        'html_url': 'https://github.com/CarGuo/gsy_github_app_flutter/blob/main/lib/main.dart',
        'repository': {
          'full_name': 'CarGuo/gsy_github_app_flutter',
          'owner': {
            'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
          },
        },
      });
      expect(item.name, 'main.dart');
      expect(item.path, 'lib/main.dart');
      expect(item.htmlUrl,
          'https://github.com/CarGuo/gsy_github_app_flutter/blob/main/lib/main.dart');
      expect(item.repositoryFullName, 'CarGuo/gsy_github_app_flutter');
      expect(item.repositoryOwnerAvatar,
          'https://avatars.githubusercontent.com/u/1?v=4');
    });

    test('primary constructor final 字段应赋值成功且可读取', () {
      final item = CodeSearchItem(
        name: 'a.dart',
        path: 'src/a.dart',
        htmlUrl: 'https://example.com/a.dart',
        repositoryFullName: 'foo/bar',
      );
      expect(item.name, 'a.dart');
      expect(item.repositoryOwnerAvatar, isNull,
          reason: '默认命名参数缺省时应为 null');
    });
  });

  group('CodeSearchItem.fromJson - 健壮性', () {
    test('缺少 repository 时四个字符串字段回退空串，avatar 保持 null', () {
      final item = CodeSearchItem.fromJson(<String, dynamic>{});
      expect(item.name, '');
      expect(item.path, '');
      expect(item.htmlUrl, '');
      expect(item.repositoryFullName, '');
      expect(item.repositoryOwnerAvatar, isNull);
    });

    test('repository 存在但 owner 缺失时 avatar 为 null', () {
      final item = CodeSearchItem.fromJson({
        'name': 'x',
        'repository': {'full_name': 'a/b'},
      });
      expect(item.repositoryFullName, 'a/b');
      expect(item.repositoryOwnerAvatar, isNull);
    });

    test('owner.avatar_url 为非字符串时走 toString', () {
      final item = CodeSearchItem.fromJson({
        'repository': {
          'owner': {'avatar_url': 12345},
        },
      });
      expect(item.repositoryOwnerAvatar, '12345');
    });

    test('顶层 String 字段收到非字符串时走 toString 兜底', () {
      final item = CodeSearchItem.fromJson({
        'name': 123,
        'path': true,
        'html_url': null,
        'repository': {
          'full_name': 456,
        },
      });
      expect(item.name, '123');
      expect(item.path, 'true');
      expect(item.htmlUrl, '');
      expect(item.repositoryFullName, '456');
    });
  });
}
