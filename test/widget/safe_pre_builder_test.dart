import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/widget/markdown/safe_pre_builder.dart';
import 'package:gsy_github_app_flutter/widget/markdown/syntax_high_lighter.dart'
    as gsy_hl;
import 'package:markdown/markdown.dart' as md;

class _TestHighlighter extends SyntaxHighlighter {
  new();

  @override
  TextSpan format(String source) {
    return TextSpan(text: source);
  }
}

class _GSYLikeHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    return gsy_hl.DartSyntaxHighlighter().format(source);
  }
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );

void main() {
  group('SafePreBuilder.visitText', () {
    testWidgets(
        'renders SingleChildScrollView(horizontal) without Scrollbar wrapper',
        (WidgetTester tester) async {
      final SafePreBuilder builder = SafePreBuilder(
        styleSheet:
            MarkdownStyleSheet(codeblockPadding: const EdgeInsets.all(8)),
        syntaxHighlighter: _TestHighlighter(),
      );

      final Widget? result =
          builder.visitText(md.Text('const x = 1;'), const TextStyle());
      expect(result, isNotNull);

      await tester.pumpWidget(_wrap(result!));

      // Scrollbar 必须被移除（方案 C 的核心断言）
      expect(find.byType(Scrollbar), findsNothing);

      // 横滚 SingleChildScrollView 必须仍然存在
      final Finder scv = find.byType(SingleChildScrollView);
      expect(scv, findsWidgets);

      // 内层 SingleChildScrollView 的方向必须是水平
      final SingleChildScrollView inner = tester.widgetList<SingleChildScrollView>(scv).last;
      expect(inner.scrollDirection, Axis.horizontal);
      expect(inner.physics, isA<ClampingScrollPhysics>());
    });

    testWidgets('preserves highlight span content from syntaxHighlighter',
        (WidgetTester tester) async {
      final SafePreBuilder builder = SafePreBuilder(
        styleSheet: MarkdownStyleSheet(),
        syntaxHighlighter: _GSYLikeHighlighter(),
      );

      const String code = 'int a = 42; // hello';
      final Widget? result = builder.visitText(md.Text(code), const TextStyle());
      expect(result, isNotNull);

      await tester.pumpWidget(_wrap(result!));

      final Finder textRich = find.byType(Text);
      expect(textRich, findsWidgets);

      // 至少能在 rich text 结构里找到原代码片段
      final RichText rich = tester.widget<RichText>(find.byType(RichText).first);
      final TextSpan root = rich.text as TextSpan;
      final String flat = root.toPlainText();
      expect(flat, contains('42'));
      expect(flat, contains('hello'));
    });

    testWidgets(
        'padding param on inner SingleChildScrollView follows styleSheet.codeblockPadding',
        (WidgetTester tester) async {
      const EdgeInsets pad = EdgeInsets.fromLTRB(12, 4, 12, 4);
      final SafePreBuilder builder = SafePreBuilder(
        styleSheet: MarkdownStyleSheet(codeblockPadding: pad),
        syntaxHighlighter: _TestHighlighter(),
      );
      final Widget? result = builder.visitText(md.Text('x'), null);
      await tester.pumpWidget(_wrap(result!));
      final SingleChildScrollView inner = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .last;
      expect(inner.padding, pad);
    });

    test('isBlockElement returns true so pre remains a block-level container',
        () {
      final SafePreBuilder builder = SafePreBuilder(
        styleSheet: MarkdownStyleSheet(),
        syntaxHighlighter: _TestHighlighter(),
      );
      expect(builder.isBlockElement(), isTrue);
    });
  });
}
