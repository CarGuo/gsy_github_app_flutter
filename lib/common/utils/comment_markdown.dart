// `markdown` 是 `flutter_markdown_plus` 的传递依赖（pubspec.lock 已锁），
// 复用它避免为 comment body 单开一份 md 引擎；不改 pubspec.yaml 是刻意
// 决策，见下方 dartdoc "设计取舍 2"。
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;

/// A/4：把 GitHub PR / Issue **评论 body** 从 Markdown 源文本转成
/// **可以内联进 diff webview** 的安全 HTML 片段。
///
/// A/3 之前只做了 `_htmlEscape + \n->  <br>`，代价是 fixture PR #938 里
/// Copilot 挂在 build.gradle L84 的 ```suggestion 代码块被打成一坨
/// 转义后的纯文本，可读性差。本包装解决的是"评论体真正的 markdown 语义"。
///
/// 设计取舍
/// --------
/// 1. **只做 md → HTML，不做 md → widget**：内联的目标是塞进
///    [HtmlUtils.parseDiffSource] 生成的 webview HTML 里，走浏览器渲染。
///    App 层已有 [GSYMarkdownWidget]（走 flutter_markdown_plus）承担
///    Flutter 侧渲染，与本函数分工明确
/// 2. **复用已在 pubspec.lock 里的 `markdown` 包（`flutter_markdown_plus`
///    的传递依赖）**：不新增依赖，不改 pubspec.yaml，不引入 web 端 md 库
///    （像 marked.js / markdown-it 需要额外 CDN 或本地资产）
/// 3. **`inlineSyntaxes` + `blockSyntaxes` 手动挑选**：GitHub GFM 全量太大
///    （table / strikethrough / task list / emoji …），XSS 面也大。
///    这里仅开启 PR review 评论**实际使用率最高**的三样：
///    - fenced code block（```suggestion 三反引号围栏）
///    - inline code（\`bar\`）
///    - autolinks（GitHub 会自动把裸 URL 转链接）
///    其余 GFM 语法降级为纯文本（不解析 = 原样输出转义后的字符），
///    人类阅读仍然可懂，且 XSS 面最小
/// 4. **XSS 底线靠 `ExtensionSet.none` + `encodeHtml: true`**：
///    `package:markdown` 的 `commonMark` / `gitHubWeb` / `gitHubFlavored`
///    默认 extension set 里都包含 `InlineHtmlSyntax`，**会主动放行**
///    用户 raw HTML（`<script>` / `<img onerror>` 之类）。这是 XSS 高危。
///    本包装显式用 `ExtensionSet.none`，只从 `withDefaultInlineSyntaxes`
///    默认集合里拿 inline 核心（emphasis / inline-code / escape / link），
///    再手动加 GFM 的 `AutolinkExtensionSyntax`。`encodeHtml: true` 保证
///    `<` / `>` / `&` 被转义
/// 5. **失败降级**：任何异常路径回落到"escape 后原样 + `\n → <br>`"，
///    保证 webview 至少能看到内容
///
/// 已知不做
/// --------
/// - 不做 mention（`@user`）转链接：webview 层无路由能力，会成为死链
/// - 不做 emoji shortcode（`:smile:`）：需要额外映射表
/// - 不做 checkbox（`- [x]`）：交互态在 webview 里无处安放
///
/// 与 A/3 兼容
/// -----------
/// 返回值仍然是"可以直接嵌入 `<div class=\"gsy-review-comment\">` 内层"
/// 的字符串。调用方 [_buildAddLineExtras] 只需把原来的
/// `_htmlEscape(body).replaceAll('\n', '<br>')` 换成本函数。
///
/// [source] 为 GitHub API 返回的 comment body 原文（未 escape 的 markdown）。
/// 返回 HTML 片段（**不含**外层容器）。
String renderCommentBodyToInlineHtml(String? source) {
  if (source == null) return '';
  final String trimmed = source.trim();
  if (trimmed.isEmpty) return '';
  try {
    // **XSS 底线预处理**：把可能被 markdown 认作"HTML 标签起始"的
    // `<letter` / `</letter` / `<!` / `<?` 序列前置一个反斜杠（CommonMark
    // 标准转义符），markdown 解析后会作为字面 `<` 输出，再经 encodeHtml
    // 转成 `&lt;`。这样彻底关闭 raw HTML 通路，但**保留** fenced code
    // block 内 `<foo>` 的原样显示（fenced code 走反引号语义，不再走 raw
    // HTML 识别）。
    //
    // 为什么不用 `ExtensionSet.none` 就够：`ExtensionSet.commonMark` 里的
    // `InlineHtmlSyntax` 与标准 block 集里的 `HtmlBlockSyntax` **两处**都
    // 会放行 raw HTML；即便扫掉 InlineHtmlSyntax，HtmlBlockSyntax 依然
    // 命中 `<script>` 这种块级标签起始。源头 escape 是最鲁棒的做法。
    final String safeSource = _escapeRawHtmlStarts(trimmed);
    final String html = md.markdownToHtml(
      safeSource,
      // 不用 gitHubWeb / gitHubFlavored，避免 InlineHtmlSyntax 等再次
      // 引入 raw HTML 放行通路
      extensionSet: md.ExtensionSet.none,
      encodeHtml: true,
      inlineSyntaxes: [
        // 裸 URL / 邮箱 自动转 <a>（GFM 扩展，非 CommonMark 默认）
        md.AutolinkExtensionSyntax(),
      ],
      blockSyntaxes: [
        // fenced code block （```lang\n...\n``` 与 ~~~）
        const md.FencedCodeBlockSyntax(),
      ],
    );
    return html;
  } catch (_) {
    // 兜底：任何解析异常回落到 A/3 的 escape + <br> 行为
    return _fallbackEscape(trimmed);
  }
}

/// 把可能被 markdown 认作 raw HTML 标签起始的 `<x` `</x` `<!` `<?` 序列
/// 前置反斜杠。CommonMark 规范里 `\<` 是 punctuation escape，解析后
/// 就是字面文本 `<`，再经 `encodeHtml: true` 变成 `&lt;` 输出。
///
/// 该函数**不**处理 fenced code block 或 inline code block 内部的
/// `<`——那些区域 markdown 会走代码语法，本来就不做 raw HTML 识别，
/// 内部 `<` 会自然被 `encodeHtml` escape 成 `&lt;`。
///
/// 因此这里可以放心对整段全局替换，不会破坏代码块渲染。
String _escapeRawHtmlStarts(String input) {
  // 匹配 `<字母` / `</字母` / `<!` / `<?`
  final RegExp htmlStart = RegExp(r'<(/?[a-zA-Z]|!|\?)');
  return input.replaceAllMapped(htmlStart, (m) => r'\<' + m.group(1)!);
}

/// 与 [pull_request_files_page._htmlEscape] 相同语义的兜底 escape。
/// 抽出来供 [renderCommentBodyToInlineHtml] 失败路径复用；
/// 5 个 HTML 特殊字符 + `\n → <br>`。
String _fallbackEscape(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('\n', '<br>');
}
