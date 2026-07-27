import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';

void main() {
  group('mergeLinebrokenImageLinks - 换行断开的图片链接折回单行', () {
    test('基本换行：`]` 与 `(` 之间夹一个 \\n 应被折回单行', () {
      const input =
          '[![Image](https://example.com/a.png)]\n(https://example.com/detail)';
      const expected =
          '[![Image](https://example.com/a.png)](https://example.com/detail)';
      expect(mergeLinebrokenImageLinks(input), expected);
    });

    test('imgUrl 含 GitHub private-user-images 的 JWT query 也能命中', () {
      const input =
          '[![shot](https://private-user-images.githubusercontent.com/1/2.png?jwt=eyJhbGciOi.abc.def)]\n(https://github.com/CarGuo/gsy/discussions/511)';
      const expected =
          '[![shot](https://private-user-images.githubusercontent.com/1/2.png?jwt=eyJhbGciOi.abc.def)](https://github.com/CarGuo/gsy/discussions/511)';
      expect(mergeLinebrokenImageLinks(input), expected);
    });

    test('alt 含空格与中文时不影响匹配', () {
      const input =
          '[![截图 页面 1](https://example.com/a.png)]\n(https://example.com/x)';
      const expected =
          '[![截图 页面 1](https://example.com/a.png)](https://example.com/x)';
      expect(mergeLinebrokenImageLinks(input), expected);
    });

    test('hrefUrl 相对路径也能合并', () {
      const input = '[![logo](/img/a.png)]\n(/discussions/511)';
      const expected = '[![logo](/img/a.png)](/discussions/511)';
      expect(mergeLinebrokenImageLinks(input), expected);
    });

    test('已经是单行的图片链接应保持不变（幂等）', () {
      const input = '[![Image](https://example.com/a.png)](https://example.com/x)';
      expect(mergeLinebrokenImageLinks(input), input);
    });

    test(
        '不误吞：后续单独一行的普通 markdown 链接不应被并入上一段图片链接（这里指没有前一段 `[![...]]` 的情形）',
        () {
      const input = '这里没有图片。\n[a normal link](https://example.com)';
      expect(mergeLinebrokenImageLinks(input), input);
    });

    test('多段连续图片链接混合（一段换行 + 一段单行）都被规范化', () {
      const input =
          '[![a](https://x/a.png)]\n(https://x/1)\n\n段落间隔\n\n[![b](https://x/b.png)](https://x/2)';
      const expected =
          '[![a](https://x/a.png)](https://x/1)\n\n段落间隔\n\n[![b](https://x/b.png)](https://x/2)';
      expect(mergeLinebrokenImageLinks(input), expected);
    });

    test('中间有多个空格 / tab 也能合并', () {
      const input = '[![a](https://x/a.png)]  \t\n  \t(https://x/target)';
      const expected = '[![a](https://x/a.png)](https://x/target)';
      expect(mergeLinebrokenImageLinks(input), expected);
    });
  });
}
