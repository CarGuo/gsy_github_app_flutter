import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/utils/comment_markdown.dart';

/// A/4 单测：验证 [renderCommentBodyToInlineHtml] 的行为契约。
///
/// 覆盖点（按重要性排序）：
/// 1. **fenced code block**（fixture PR #938 的 ```suggestion 场景）
/// 2. **inline code**
/// 3. **autolinks**（GitHub 会自动把裸 URL 转链接）
/// 4. **XSS 底线**：裸 `<script>` 会被 escape 成字面
/// 5. **纯文本 fallback**：没有任何 markdown 语法时依然安全输出
/// 6. **边界**：null / 空串 / 仅空白 → 空串
void main() {
  test('null / 空串 / 仅空白 → 空串', () {
    expect(renderCommentBodyToInlineHtml(null), '');
    expect(renderCommentBodyToInlineHtml(''), '');
    expect(renderCommentBodyToInlineHtml('   \n  '), '');
  });

  test('fenced code block 三反引号被渲染为 <pre><code>', () {
    // fixture #938 的 Copilot suggestion 就是这种形式
    const src = '```suggestion\n'
        'implementation("androidx.appcompat:appcompat:1.6.1")\n'
        '```';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('<pre>'), isTrue, reason: '应该有 <pre>');
    expect(out.contains('<code'), isTrue, reason: '应该有 <code>');
    expect(out.contains('appcompat:1.6.1'), isTrue,
        reason: '代码内容应原样保留');
    // 语言 tag 应以 class="language-suggestion" 形式落到 <code>
    expect(out.contains('language-suggestion'), isTrue,
        reason: 'suggestion 语言 tag 应保留在 class 里');
  });

  test('inline code 单反引号被渲染为 <code>', () {
    const src = '请把 `foo()` 改成 `bar()`';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('<code>foo()</code>'), isTrue);
    expect(out.contains('<code>bar()</code>'), isTrue);
  });

  test('autolinks：裸 URL 被转为 <a>', () {
    const src = 'see https://example.com/x for details';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('<a href="https://example.com/x">'), isTrue,
        reason: '裸 URL 应转 <a>');
    expect(out.contains('example.com/x</a>'), isTrue);
  });

  test('XSS 底线：裸 <script> 被 escape 而非执行', () {
    const src = '<script>alert(1)</script>';
    final out = renderCommentBodyToInlineHtml(src);
    // 关键：输出里绝对不能出现真的可执行 <script> 起始标签
    expect(out.contains('<script>'), isFalse,
        reason: '<script> 起始标签必须被 escape');
    // 应该以字面形式出现（&lt;script&gt;）
    expect(out.contains('&lt;script&gt;'), isTrue,
        reason: '<script> 应被 escape 成字面');
  });

  test('XSS 底线：<img onerror> 等属性型载荷也被 escape', () {
    const src = '<img src=x onerror=alert(1)>';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('<img'), isFalse,
        reason: '裸 <img> 也必须被 escape 掉');
    expect(out.contains('onerror'), isTrue,
        reason: '文本内容 onerror 会保留为纯字符（属可接受）');
    // 关键：不能有可执行的 <img ... onerror=...> 组合
    expect(out.contains('<img src=x onerror'), isFalse);
  });

  test('纯文本 fallback：无 markdown 语法时也能安全输出', () {
    const src = 'Hello, world. 你好，世界。';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('Hello, world'), isTrue);
    expect(out.contains('你好'), isTrue);
    // 应被裹在 <p> 里（inlineOnly=false 时块级默认段落）
    expect(out.contains('<p>'), isTrue);
  });

  test('多段落之间保留结构（换行 → <p> 或 <br>）', () {
    const src = 'first paragraph\n\nsecond paragraph';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('first paragraph'), isTrue);
    expect(out.contains('second paragraph'), isTrue);
    // 两段应被分成两个 <p>
    final pCount = '<p>'.allMatches(out).length;
    expect(pCount, greaterThanOrEqualTo(2),
        reason: '空行分隔应生成多个 <p>');
  });

  test('fixture PR #938 Copilot suggestion 完整语义还原', () {
    // 模拟 Copilot 挂在 build.gradle L84 的真实 body 形态：
    // 一段前言 + ```suggestion 代码块
    const src = 'Consider using the AndroidX AppCompat library:\n\n'
        '```suggestion\n'
        'implementation("androidx.appcompat:appcompat:1.6.1")\n'
        '```';
    final out = renderCommentBodyToInlineHtml(src);
    expect(out.contains('Consider using'), isTrue);
    expect(out.contains('<pre>'), isTrue);
    expect(out.contains('language-suggestion'), isTrue);
    expect(out.contains('appcompat:1.6.1'), isTrue);
    // 前言应在代码块之前
    final idxIntro = out.indexOf('Consider');
    final idxPre = out.indexOf('<pre>');
    expect(idxPre, greaterThan(idxIntro));
  });
}
