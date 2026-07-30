import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// [SafePreBuilder] 用来接管 `flutter_markdown_plus` 对 `<pre>` 块的默认渲染，
/// 消除内嵌横滚容器与外层竖向 [SingleChildScrollView] 之间的垂直手势竞争。
///
/// **背景（roadmap §3.1 pt.3 已知缺口 a）**：
/// 上游 [flutter_markdown_plus/lib/src/builder.dart#L344-L357](https://pub.dev/packages/flutter_markdown_plus)
/// 里针对 `<pre>` 硬编码为 `Scrollbar > SingleChildScrollView(scrollDirection: horizontal)`。
/// `Scrollbar` 在竖向 drag 命中 code block 区域时会通过内部
/// `_TrackTapGestureRecognizer` / 拖 thumb 手势对 vertical drag 做拦截，
/// 直接导致外层 GSY [SingleChildScrollView]（DiscussionDetail body scroll）
/// 无法接管，用户手指落在 code block 内滑动时页面卡住。
///
/// **方案 C 的最小改动**：注册 `builders['pre']` 完全绕开 hardcoded 分支，
/// 用**无 Scrollbar** 的 [SingleChildScrollView] 承载横滚代码块，
/// 让 vertical drag 直接由外层竖向 [Scrollable] 接管；
/// 视觉上：牺牲 code block 的 scrollbar 拇指提示（放弃程度极低——
/// GitHub 官方 mobile app 的 code block 同样无 scrollbar），
/// 换来页面在评论/正文里 code block 位置的可滚性。
///
/// **保留的行为**：
/// - `<pre>` 外层仍会由 flutter_markdown_plus 内建的 tag=='pre' 分支
///   自动套 [MarkdownStyleSheet.codeblockDecoration]（见 builder.dart L470-L475），
///   本 builder 无需重复处理装饰；
/// - 语法高亮通过传入的 [SyntaxHighlighter] 复用 GSY 现有的 `GSYHighlighter`
///   → `DartSyntaxHighlighter`，输出与原分支一致的 [TextSpan] 结构；
/// - `codeblockPadding` 从 [MarkdownStyleSheet] 上取，与原分支一致。
class SafePreBuilder extends MarkdownElementBuilder {
  SafePreBuilder({
    required this.styleSheet,
    required this.syntaxHighlighter,
  });

  final MarkdownStyleSheet styleSheet;
  final SyntaxHighlighter syntaxHighlighter;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final TextSpan highlighted = syntaxHighlighter.format(text.text);
    final TextSpan rootSpan = TextSpan(
      style: preferredStyle,
      children: <InlineSpan>[highlighted],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: styleSheet.codeblockPadding,
      physics: const ClampingScrollPhysics(),
      child: Text.rich(rootSpan),
    );
  }
}
