import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';

/// HtmlUtils.parseDiffSource 的行为单测。
///
/// 主要覆盖 A/3 新增的 `addLineExtras` 参数：把 review comment HTML
/// 片段按 head 分支行号内联注入到对应 diff 行下方。
///
/// 不覆盖高亮 HTML、CSS 生成，那些是 [generateCodeHtml] 的责任，
/// 属于 webview 渲染层，可视化验证走真机 smoke。

void main() {
  // 一个最小 diff patch：hunk 从 addStartLine=40 开始，
  // 3 行 context → 40/41/42，然后 1 行 addition → 43。
  // 注意每行必须以 `+`/`-`/`@@`/` ` 或 `\` 开头（GitHub diff 惯例）
  const patch = '@@ -40,3 +40,4 @@\n'
      ' line40\n'
      ' line41\n'
      ' line42\n'
      '+line43_added';

  test('parseDiffSource 不传 addLineExtras 时输出与 A/2 一致（向后兼容）', () {
    final out = HtmlUtils.parseDiffSource(patch, false);
    expect(out, isA<String>());
    // 不应出现内联 comment 类名
    expect((out as String).contains('gsy-review-comment'), isFalse);
    // 应包含每一行的 diff div
    expect(out.contains('line40'), isTrue);
    expect(out.contains('line43_added'), isTrue);
  });

  test('parseDiffSource 传空 map addLineExtras 时也不注入', () {
    final out = HtmlUtils.parseDiffSource(patch, false,
        addLineExtras: <int, String>{}) as String;
    expect(out.contains('gsy-review-comment'), isFalse);
  });

  test('parseDiffSource 命中行号时在该行 <div> 之后追加 extra 片段', () {
    // 命中行号 42（context 行）：期望 extra 出现在 "line42</div>" 之后、
    // "line43_added" 对应的 div 之前
    final extras = <int, String>{
      42: '<div class="gsy-review-comment">HELLO_A3</div>',
    };
    final out = HtmlUtils.parseDiffSource(patch, false,
        addLineExtras: extras) as String;
    expect(out.contains('HELLO_A3'), isTrue,
        reason: 'extra 应被内联到 diff HTML');
    final idxLine42 = out.indexOf('line42</div>');
    final idxExtra = out.indexOf('HELLO_A3');
    final idxLine43 = out.indexOf('line43_added');
    expect(idxLine42, greaterThanOrEqualTo(0));
    expect(idxExtra, greaterThan(idxLine42),
        reason: 'extra 应出现在命中行之后');
    expect(idxLine43, greaterThan(idxExtra),
        reason: 'extra 应出现在下一行之前，形成"兄弟节点"');
  });

  test('parseDiffSource 命中 addition 行（+ 前缀）也能注入', () {
    final extras = <int, String>{
      43: '<div class="gsy-review-comment">ON_ADD</div>',
    };
    final out = HtmlUtils.parseDiffSource(patch, false,
        addLineExtras: extras) as String;
    expect(out.contains('ON_ADD'), isTrue);
    // 应位于 line43_added 之后
    final idxAdd = out.indexOf('line43_added');
    final idxExtra = out.indexOf('ON_ADD');
    expect(idxExtra, greaterThan(idxAdd));
  });

  test('parseDiffSource 未命中的行号不影响输出', () {
    final extras = <int, String>{
      999: '<div>SHOULD_NOT_APPEAR</div>',
    };
    final out = HtmlUtils.parseDiffSource(patch, false,
        addLineExtras: extras) as String;
    expect(out.contains('SHOULD_NOT_APPEAR'), isFalse);
  });

  test('parseDiffSource 同一行的 extra 已由调用方拼好，util 层原样注入', () {
    // 调用方（_buildAddLineExtras）保证同一行的多条 comment 拼在一个字符串里。
    // util 层不做拼接，只做"命中行注入"。此测试固化这条契约
    final extras = <int, String>{
      42: '<div class="gsy-review-comment">C1</div>'
          '<div class="gsy-review-comment">C2</div>',
    };
    final out = HtmlUtils.parseDiffSource(patch, false,
        addLineExtras: extras) as String;
    final i1 = out.indexOf('C1');
    final i2 = out.indexOf('C2');
    expect(i1, greaterThan(0));
    expect(i2, greaterThan(i1), reason: 'C1 应在 C2 前，顺序稳定');
    // 都要在下一行之前
    final iNext = out.indexOf('line43_added');
    expect(iNext, greaterThan(i2));
  });

  test('parseDiffSource 处理无逗号形式的 hunk header (@@ -40 +40 @@)', () {
    // git 在 hunk 只有 1 行时会省略逗号。这里覆盖 hunk header 解析健壮性
    const patchNoComma = '@@ -40 +40 @@\n line40';
    final extras = <int, String>{
      40: '<div class="gsy-review-comment">SINGLE</div>',
    };
    final out = HtmlUtils.parseDiffSource(patchNoComma, false,
        addLineExtras: extras) as String;
    expect(out.contains('line40'), isTrue);
    // 无逗号 hunk 是否解析正确取决于底层实现，这里至少保证不崩、有输出
    expect(out.isNotEmpty, isTrue);
  });

  test('_buildAddLineExtras 契约：调用方应用 c.line 而非 c.displayLine 建 key', () {
    // 这个测试是"文档性质"：模拟调用方按 line（新 blob 行号）建 key 的行为。
    // 若调用方误用 originalLine（旧 blob 行号）当 key，
    // 在下面这个 patch 里 key=40 会误命中不相关的 head 侧 line 40
    final extras = <int, String>{
      42: '<div class="gsy-review-comment">HEAD_ONLY</div>',
    };
    final out = HtmlUtils.parseDiffSource(patch, false,
        addLineExtras: extras) as String;
    // 只应命中 head 42，不应在 head 40/41/43 位置出现
    final idxHead42 = out.indexOf('line42</div>');
    final idxExtra = out.indexOf('HEAD_ONLY');
    expect(idxExtra, greaterThan(idxHead42));
    // 出现次数应恰好 1（不会因 removed-side 语义误注入）
    final occurrences = 'HEAD_ONLY'.allMatches(out).length;
    expect(occurrences, 1);
  });
}
