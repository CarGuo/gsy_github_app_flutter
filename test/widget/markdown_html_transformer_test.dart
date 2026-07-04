import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/widget/markdown/markdown_html_transformer.dart';

void main() {
  group('transformInlineHtmlToMarkdown - GitHub HTML 白名单', () {
    test('空字符串直接返回', () {
      expect(transformInlineHtmlToMarkdown(''), '');
    });

    test('纯 Markdown 不含 HTML 应保持原样', () {
      const md = '# Title\n\nHello **world** with [link](https://x.com)';
      expect(transformInlineHtmlToMarkdown(md), md);
    });

    test('<a href> 转成 markdown 链接语法', () {
      const html =
          '<a href="/CarGuo/gsy/new/master?f=x" target="_blank">Add Copilot custom instructions</a>';
      final result = transformInlineHtmlToMarkdown(html);
      expect(result,
          contains('[Add Copilot custom instructions](/CarGuo/gsy/new/master?f=x)'));
      expect(result.contains('<a'), isFalse);
    });

    test('<a> 无 href 时保留文本', () {
      const html = '<a>bare text</a>';
      expect(transformInlineHtmlToMarkdown(html), 'bare text');
    });

    test('<a> href 存在但文本空白时用 href 兜底', () {
      const html = '<a href="https://x.com"></a>';
      expect(transformInlineHtmlToMarkdown(html),
          contains('[https://x.com](https://x.com)'));
    });

    test('<img src alt> 转成 markdown 图片语法', () {
      const html = '<img src="/foo/bar.png" alt="logo">';
      expect(transformInlineHtmlToMarkdown(html), contains('![logo](/foo/bar.png)'));
    });

    test('<img> 缺 src 时舍弃', () {
      const html = '<img alt="bad">';
      expect(transformInlineHtmlToMarkdown(html).contains('<img'), isFalse);
    });

    test('<b> <strong> 转成 **加粗**', () {
      expect(transformInlineHtmlToMarkdown('<b>x</b>'), '**x**');
      expect(transformInlineHtmlToMarkdown('<strong>y</strong>'), '**y**');
    });

    test('<i> <em> 转成 *斜体*', () {
      expect(transformInlineHtmlToMarkdown('<i>x</i>'), '*x*');
      expect(transformInlineHtmlToMarkdown('<em>y</em>'), '*y*');
    });

    test('<s> <strike> <del> 转成 ~~删除线~~', () {
      expect(transformInlineHtmlToMarkdown('<s>a</s>'), '~~a~~');
      expect(transformInlineHtmlToMarkdown('<strike>b</strike>'), '~~b~~');
      expect(transformInlineHtmlToMarkdown('<del>c</del>'), '~~c~~');
    });

    test('<u> <ins> 无原生 markdown，用斜体近似', () {
      expect(transformInlineHtmlToMarkdown('<u>x</u>'), '*x*');
      expect(transformInlineHtmlToMarkdown('<ins>y</ins>'), '*y*');
    });

    test('<code> <kbd> <tt> <samp> <var> 转成 `行内代码`', () {
      expect(transformInlineHtmlToMarkdown('<code>x</code>'), '`x`');
      expect(transformInlineHtmlToMarkdown('<kbd>Enter</kbd>'), '`Enter`');
      expect(transformInlineHtmlToMarkdown('<tt>t</tt>'), '`t`');
      expect(transformInlineHtmlToMarkdown('<samp>s</samp>'), '`s`');
      expect(transformInlineHtmlToMarkdown('<var>v</var>'), '`v`');
    });

    test('<sub> <sup> 降级为纯文本（GFM 无原生上下标，避免与删除线冲突）', () {
      // GFM 不支持 ~x~ 上下标语法；退回纯文本，可读性完整
      expect(transformInlineHtmlToMarkdown('H<sub>2</sub>O'), 'H2O');
      expect(transformInlineHtmlToMarkdown('E=mc<sup>2</sup>'), 'E=mc2');
    });

    test('<br> 转成两空格加换行', () {
      expect(transformInlineHtmlToMarkdown('a<br>b'), 'a  \nb');
    });

    test('<hr> 转成 markdown 水平线', () {
      final r = transformInlineHtmlToMarkdown('a<hr>b');
      expect(r, contains('---'));
    });

    test('<h1>-<h6> 转成 # 标题', () {
      final r1 = transformInlineHtmlToMarkdown('<h1>T</h1>');
      expect(r1, contains('# T'));
      final r3 = transformInlineHtmlToMarkdown('<h3>X</h3>');
      expect(r3, contains('### X'));
      final r6 = transformInlineHtmlToMarkdown('<h6>Y</h6>');
      expect(r6, contains('###### Y'));
    });

    test('<p> 段落用空行分隔', () {
      final r = transformInlineHtmlToMarkdown('<p>a</p><p>b</p>');
      expect(r, contains('a'));
      expect(r, contains('b'));
      expect(r.contains('<p>'), isFalse);
    });

    test('<blockquote> 转成 > 引用', () {
      final r = transformInlineHtmlToMarkdown('<blockquote>hi</blockquote>');
      expect(r, contains('> hi'));
    });

    test('<ul>+<li> 转成 markdown 无序列表', () {
      final r =
          transformInlineHtmlToMarkdown('<ul><li>a</li><li>b</li></ul>');
      expect(r, contains('- a'));
      expect(r, contains('- b'));
    });

    test('<ol>+<li> 转成 markdown 有序列表', () {
      final r =
          transformInlineHtmlToMarkdown('<ol><li>a</li><li>b</li></ol>');
      expect(r, contains('1. a'));
      expect(r, contains('2. b'));
    });

    test('嵌套列表保留缩进', () {
      final r = transformInlineHtmlToMarkdown(
          '<ul><li>a<ul><li>a1</li></ul></li></ul>');
      expect(r, contains('- a'));
      expect(r, contains('  - a1'));
    });

    test('<details>+<summary> 转成加粗 summary + 展开内容', () {
      final r = transformInlineHtmlToMarkdown(
          '<details><summary>Click me</summary>hidden body</details>');
      expect(r, contains('**Click me**'));
      expect(r, contains('hidden body'));
    });

    test('<table><thead><tbody> 转成 GFM 表格', () {
      const html = '<table>'
          '<thead><tr><th>A</th><th>B</th></tr></thead>'
          '<tbody><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></tbody>'
          '</table>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('| A | B |'));
      expect(r, contains('| --- | --- |'));
      expect(r, contains('| 1 | 2 |'));
      expect(r, contains('| 3 | 4 |'));
    });

    test('<dl><dt><dd> 转成 term/definition 段落', () {
      final r = transformInlineHtmlToMarkdown(
          '<dl><dt>term</dt><dd>definition</dd></dl>');
      expect(r, contains('**term**'));
      expect(r, contains(': definition'));
    });

    test('<div> <span> <small> <q> 视为透传容器', () {
      expect(transformInlineHtmlToMarkdown('<div>a</div>'), contains('a'));
      expect(transformInlineHtmlToMarkdown('<span>b</span>'), contains('b'));
      expect(transformInlineHtmlToMarkdown('<small>c</small>'), contains('c'));
      expect(transformInlineHtmlToMarkdown('<q>d</q>'), contains('d'));
    });

    test('未知白名单外标签退回文本内容，不泄漏尖括号', () {
      const html = '<foo>inner</foo>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, 'inner');
      expect(r.contains('<'), isFalse);
    });

    test('Copilot 真实 fixture：多个内嵌 <a> 应全部识别', () {
      const html =
          'You can help me by [creating a pull request](https://x). '
          '<a href="/CarGuo/gsy/new/master?f=.github/instructions/*.md" '
          'class="Link--inTextBlock" target="_blank" rel="noopener noreferrer">'
          'Add Copilot custom instructions</a> file for this repository. '
          '<a href="https://docs.github.com/en/copilot" '
          'class="Link--inTextBlock" target="_blank">Learn how to get started</a>';
      final r = transformInlineHtmlToMarkdown(html);
      // 原始 markdown 链接不被吃
      expect(r, contains('[creating a pull request](https://x)'));
      // HTML 链接被转成 markdown 语法
      expect(
          r,
          contains(
              '[Add Copilot custom instructions](/CarGuo/gsy/new/master?f=.github/instructions/*.md)'));
      expect(r, contains('[Learn how to get started](https://docs.github.com/en/copilot)'));
      // 没有裸露 <a
      expect(r.contains('<a'), isFalse);
      expect(r.contains('</a>'), isFalse);
    });

    test('混合场景：markdown 段落中夹 HTML 段', () {
      const input = '# Title\n\nSome **md** with <kbd>Ctrl</kbd>+<kbd>C</kbd>';
      final r = transformInlineHtmlToMarkdown(input);
      expect(r, contains('# Title'));
      expect(r, contains('**md**'));
      expect(r, contains('`Ctrl`'));
      expect(r, contains('`C`'));
    });

    test('损坏 HTML 应吞掉异常并返回可用字符串', () {
      const bad = '<a href="x" <b>bad';
      final r = transformInlineHtmlToMarkdown(bad);
      // 不 crash + 至少能捞出 "bad" 文本，绝不能把裸尖括号泄漏成整段乱码
      expect(r, isNotNull);
      expect(r, contains('bad'));
    });
  });

  group('transformInlineHtmlToMarkdown - 安全与边界（reviewer 复审补齐）', () {
    test('<a> href 含右括号：URL 用尖括号语法包裹防伪造', () {
      // 攻击面：`[y](x)fake)` 会被 markdown 解析成 URL=x，
      // 使得作者把 "fake" 后缀伪装成 URL 一部分。
      const html = '<a href="https://a.com/x)fake">y</a>';
      final r = transformInlineHtmlToMarkdown(html);
      // URL 部分必须被 <> 尖括号包裹
      expect(r, contains('<https://a.com/x)fake>'));
      expect(r, contains('[y]'));
    });

    test('<a> href 含空格：用尖括号语法承载', () {
      const html = '<a href="/path with space">t</a>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('</path with space>'));
    });

    test('<a> 文本含 ] 必须转义防语法逃逸', () {
      const html = '<a href="/x">foo]bar</a>';
      final r = transformInlineHtmlToMarkdown(html);
      // 转义后：[foo\]bar](/x)
      expect(r, contains(r'foo\]bar'));
    });

    test('<img alt> 含 ] 必须转义', () {
      const html = '<img alt="foo]bar" src="/x.png">';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains(r'foo\]bar'));
    });

    test('<img src> 含空格：用尖括号语法承载', () {
      const html = '<img alt="a" src="/x y.png">';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('</x y.png>'));
    });

    test('<code> 内含反引号：使用 n+1 个反引号定界', () {
      // CommonMark §6.1：内含 1 个反引号 → 用 2 个反引号定界（fence 长度 = maxRun+1）
      // 仅当内容首尾是反引号才额外加 space padding
      const html = '<code>a`b</code>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('``a`b``'));
    });

    test('<code> 内含双反引号：使用 3 个反引号定界', () {
      const html = '<code>a``b</code>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('```a``b```'));
    });

    test('<code> 内容以反引号开头/结尾：加空白 padding', () {
      const html = '<code>`x`</code>';
      final r = transformInlineHtmlToMarkdown(html);
      // 双反引号定界 + 首尾 padding
      expect(r, contains('`` `x` ``'));
    });

    test('<pre> 内含 ``` 三反引号：fence 长度动态放大到 4', () {
      const html = '<pre>```\ncode\n```</pre>';
      final r = transformInlineHtmlToMarkdown(html);
      // fence 必须至少 4 个反引号
      expect(r, contains('````'));
      expect(r, contains('```\ncode\n```'));
    });

    test('<pre> 普通内容用标准 3 反引号 fence', () {
      const html = '<pre>hello\nworld</pre>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('```\nhello\nworld\n```'));
    });

    test('表格 cell 含 | 必须转义防表格逃逸', () {
      const html = '<table><thead><tr><th>A</th><th>B</th></tr></thead>'
          '<tbody><tr><td>x|y</td><td>z</td></tr></tbody></table>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains(r'x\|y'));
    });

    test('表格 cell 含换行必须替换为空格（GFM 不允许多行 cell）', () {
      const html = '<table><thead><tr><th>A</th></tr></thead>'
          '<tbody><tr><td>line1<br>line2</td></tr></tbody></table>';
      final r = transformInlineHtmlToMarkdown(html);
      // cell 内不允许裸换行
      final lines = r.split('\n');
      final tableRow = lines.firstWhere((l) => l.contains('line1'),
          orElse: () => '');
      expect(tableRow, isNot(equals('')));
      expect(tableRow, isNot(contains('line1  \nline2')));
    });

    test('<blockquote> 深嵌套 300 层不 crash（栈保护生效）', () {
      final sb = StringBuffer();
      const depth = 300;
      for (var i = 0; i < depth; i++) {
        sb.write('<blockquote>');
      }
      sb.write('deep');
      for (var i = 0; i < depth; i++) {
        sb.write('</blockquote>');
      }
      // 不应抛异常
      final r = transformInlineHtmlToMarkdown(sb.toString());
      expect(r, isNotNull);
      // 至少可读文本还在
      expect(r, contains('deep'));
    });

    test('通用标签深嵌套 300 层不 crash（深度上限退回文本）', () {
      final sb = StringBuffer();
      const depth = 300;
      for (var i = 0; i < depth; i++) {
        sb.write('<div>');
      }
      sb.write('deep');
      for (var i = 0; i < depth; i++) {
        sb.write('</div>');
      }
      final r = transformInlineHtmlToMarkdown(sb.toString());
      expect(r, contains('deep'));
    });

    test('纯文本含 `1 < 2` 不触发 HTML 解析（short-circuit）', () {
      const input = '1 < 2 and 3 > 2, no tag here';
      // short-circuit：`<` 后面不是字母 / `/` / `!`，直接原样返回
      expect(transformInlineHtmlToMarkdown(input), input);
    });

    test('<ol start="5"> 序号从 5 开始', () {
      const html = '<ol start="5"><li>a</li><li>b</li></ol>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('5. a'));
      expect(r, contains('6. b'));
    });

    test('<a> 内嵌 <code>：链接文本内保留 markdown 行内代码', () {
      const html = '<a href="/x"><code>fn()</code></a>';
      final r = transformInlineHtmlToMarkdown(html);
      expect(r, contains('[`fn()`](/x)'));
    });
  });
}
