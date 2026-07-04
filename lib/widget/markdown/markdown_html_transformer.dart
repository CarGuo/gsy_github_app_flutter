// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// GitHub 评论/issue/PR body 里常常混合 Markdown 与内嵌的 HTML 白名单标签
/// （`<a>`、`<img>`、`<details>`、`<kbd>` 等）。flutter_markdown_plus 底层的
/// markdown 解析器**不识别 inline HTML**，会把原始 `<a href="x">y</a>`
/// 之类字面输出到页面，用户看到的就是一段裸标签文本。
///
/// 这个转换器负责在把字符串喂给 GSYMarkdownWidget **之前**，把 GitHub
/// GFM 白名单（https://github.github.com/gfm/#raw-html）里的常见标签
/// 前置转成 Markdown 等价语法。这样后续渲染管线保持不变，样式、链接
/// 点击、图片相对路径处理都复用现有 pipeline。
///
/// 设计取舍（详见 ADR-0004）：
/// 1. 保留纯文本节点原样，不吃 Markdown 语法
/// 2. 无法识别的白名单外标签退回 textContent，绝不让 `<xxx>` 字面泄漏
/// 3. 属性优先（img 用 src/alt，a 用 href），失败降级到 textContent
/// 4. 关键分支（a/img/code/pre/table）严格做 Markdown 语法转义，
///    防御 GitHub 评论作者构造恶意载荷（URL spoofing / 代码块逃逸 /
///    表格逃逸 / 深嵌套栈爆）
/// 5. 递归深度上限 200，超限退回 textContent 保命

const int _kMaxDepth = 200;

/// GitHub GFM 允许的 raw HTML 白名单标签集合。
/// 参考：https://github.github.com/gfm/#raw-html
const Set<String> kGithubHtmlWhitelist = {
  'a', 'b', 'blockquote', 'br', 'code', 'dd', 'del', 'details', 'div',
  'dl', 'dt', 'em', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i',
  'img', 'ins', 'kbd', 'li', 'ol', 'p', 'pre', 'q', 's', 'samp',
  'small', 'span', 'strike', 'strong', 'sub', 'summary', 'sup',
  'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr', 'tt', 'u',
  'ul', 'var'
};

/// 前置把内嵌 HTML 白名单标签转成 Markdown 等价语法。
String transformInlineHtmlToMarkdown(String input) {
  if (input.isEmpty) return input;
  // 快速短路：至少要出现一个疑似标签起始（<a-z / </...）才走 HTML 解析
  // 避免把 `1 < 2` 这类纯 markdown 送去无谓地跑一遍 parser
  if (!RegExp(r'<[a-zA-Z/!]').hasMatch(input)) return input;

  try {
    final fragment = html_parser.parseFragment(input);
    final buffer = StringBuffer();
    final ctx = _RenderCtx();
    for (final node in fragment.nodes) {
      _writeNode(node, buffer, ctx);
    }
    return buffer.toString();
  } catch (_) {
    return input;
  }
}

class _RenderCtx {
  int listDepth = 0;
  bool inOrderedList = false;
  int blockquoteDepth = 0;
  bool insidePre = false;
  bool insideInlineCode = false;
  int recursion = 0;

  _RenderCtx copyWith({
    int? listDepth,
    bool? inOrderedList,
    int? blockquoteDepth,
    bool? insidePre,
    bool? insideInlineCode,
  }) {
    return _RenderCtx()
      ..listDepth = listDepth ?? this.listDepth
      ..inOrderedList = inOrderedList ?? this.inOrderedList
      ..blockquoteDepth = blockquoteDepth ?? this.blockquoteDepth
      ..insidePre = insidePre ?? this.insidePre
      ..insideInlineCode = insideInlineCode ?? this.insideInlineCode
      ..recursion = recursion;
  }
}

/// 转义 Markdown 链接/图片语法里的文本部分。
/// `[label](url)` 与 `![alt](src)` 中的 `label`/`alt` 若含 `]` `[` `\`
/// 会破坏语法。反斜杠转义是 CommonMark 标准。
String _escapeMdLinkText(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');
}

/// 处理 Markdown 链接语法里的 URL 部分。GFM 允许 `<url with space>`
/// 尖括号语法承载空白与部分特殊字符；含 `<` `>` `)` 或空白时用它。
String _escapeMdUrl(String url) {
  final needsAngle =
      url.contains(RegExp(r'[\s<>()]'));
  if (!needsAngle) return url;
  // 尖括号内仍需转义 <> 本身
  final safe = url.replaceAll('<', '%3C').replaceAll('>', '%3E');
  return '<$safe>';
}

/// 反引号包裹行内代码。若内容含 n 个连续反引号，用 n+1 个反引号定界，
/// 并两端加空格避免边界吞噬（CommonMark §6.1）。
String _wrapInlineCode(String content) {
  int maxRun = 0;
  int cur = 0;
  for (int i = 0; i < content.length; i++) {
    if (content.codeUnitAt(i) == 0x60) {
      cur++;
      if (cur > maxRun) maxRun = cur;
    } else {
      cur = 0;
    }
  }
  final fence = '`' * (maxRun + 1);
  // 两端加空格避免与紧邻反引号误合并
  final needsPad = content.startsWith('`') || content.endsWith('`');
  final inner = needsPad ? ' $content ' : content;
  return '$fence$inner$fence';
}

/// 生成动态长度的三反引号围栏，避免与 code block 内的 ```
/// 冲突提前闭合。
String _codeFence(String content) {
  int maxRun = 0;
  int cur = 0;
  for (int i = 0; i < content.length; i++) {
    if (content.codeUnitAt(i) == 0x60) {
      cur++;
      if (cur > maxRun) maxRun = cur;
    } else {
      cur = 0;
    }
  }
  final len = maxRun >= 3 ? maxRun + 1 : 3;
  return '`' * len;
}

/// 表格 cell 里的 `|` `\n` 必须转义/替换，否则 GFM 表格解析失败。
String _escapeTableCell(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll('|', r'\|')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ');
}

void _writeNode(dom.Node node, StringBuffer buffer, _RenderCtx ctx) {
  if (node is dom.Text) {
    buffer.write(node.text);
    return;
  }
  if (node is! dom.Element) return;

  // 递归深度上限保护，超限退回纯文本
  ctx.recursion++;
  if (ctx.recursion > _kMaxDepth) {
    buffer.write(node.text);
    ctx.recursion--;
    return;
  }

  try {
    _dispatch(node, buffer, ctx);
  } finally {
    ctx.recursion--;
  }
}

void _dispatch(dom.Element node, StringBuffer buffer, _RenderCtx ctx) {
  final tag = node.localName?.toLowerCase() ?? '';

  switch (tag) {
    case 'a':
      final href = node.attributes['href'];
      final text = _childrenToInlineString(node, ctx);
      if (href == null || href.isEmpty) {
        buffer.write(text);
      } else {
        final label = text.trim().isEmpty ? href : text;
        buffer.write(
            '[${_escapeMdLinkText(label)}](${_escapeMdUrl(href)})');
      }
      return;

    case 'img':
      final src = node.attributes['src'] ?? '';
      final alt = node.attributes['alt'] ?? '';
      if (src.isNotEmpty) {
        buffer.write(
            '![${_escapeMdLinkText(alt)}](${_escapeMdUrl(src)})');
      }
      return;

    case 'br':
      buffer.write('  \n');
      return;

    case 'hr':
      buffer.write('\n\n---\n\n');
      return;

    case 'b':
    case 'strong':
      buffer.write('**');
      _writeChildren(node, buffer, ctx);
      buffer.write('**');
      return;

    case 'i':
    case 'em':
      buffer.write('*');
      _writeChildren(node, buffer, ctx);
      buffer.write('*');
      return;

    case 's':
    case 'strike':
    case 'del':
      buffer.write('~~');
      _writeChildren(node, buffer, ctx);
      buffer.write('~~');
      return;

    case 'ins':
    case 'u':
      buffer.write('*');
      _writeChildren(node, buffer, ctx);
      buffer.write('*');
      return;

    case 'code':
    case 'tt':
    case 'samp':
    case 'var':
    case 'kbd':
      if (ctx.insidePre) {
        // 在 <pre> 内 <code> 直接透传子节点文本，外层已经加了 fence
        buffer.write(node.text);
      } else {
        buffer.write(_wrapInlineCode(node.text));
      }
      return;

    case 'pre':
      // 采用完整 textContent 作为围栏内容，避免子标签污染
      final content = node.text;
      final fence = _codeFence(content);
      buffer.write('\n\n$fence\n');
      buffer.write(content);
      if (!content.endsWith('\n')) buffer.write('\n');
      buffer.write('$fence\n\n');
      return;

    case 'sub':
      // GFM 不支持 ~x~ 上下标（会与删除线冲突）。降级为纯文本以保可读性，
      // 前后不加符号避免语义歧义
      _writeChildren(node, buffer, ctx);
      return;
    case 'sup':
      // 同上，退回纯文本
      _writeChildren(node, buffer, ctx);
      return;

    case 'q':
      // HTML <q> 语义为引号，输出 ASCII 双引号
      buffer.write('"');
      _writeChildren(node, buffer, ctx);
      buffer.write('"');
      return;

    case 'small':
    case 'span':
    case 'div':
      _writeChildren(node, buffer, ctx);
      return;

    case 'p':
      buffer.write('\n\n');
      _writeChildren(node, buffer, ctx);
      buffer.write('\n\n');
      return;

    case 'blockquote':
      buffer.write('\n');
      final inner = StringBuffer();
      _writeChildren(
          node, inner, ctx.copyWith(blockquoteDepth: ctx.blockquoteDepth + 1));
      // 只对当前层加一次 `> `，内层递归时自己再加自己的层级；
      // 这样总的复杂度是 O(N)，不再是 O(D·N)
      final lines = inner.toString().split('\n');
      for (int i = 0; i < lines.length; i++) {
        buffer.write('> ');
        buffer.write(lines[i]);
        if (i != lines.length - 1) buffer.write('\n');
      }
      buffer.write('\n');
      return;

    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      final level = int.parse(tag.substring(1));
      buffer.write('\n\n');
      buffer.write('#' * level);
      buffer.write(' ');
      _writeChildren(node, buffer, ctx);
      buffer.write('\n\n');
      return;

    case 'ul':
      buffer.write('\n');
      _writeListChildren(
        node,
        buffer,
        ctx.copyWith(
          listDepth: ctx.listDepth + 1,
          inOrderedList: false,
        ),
      );
      buffer.write('\n');
      return;
    case 'ol':
      buffer.write('\n');
      final start = int.tryParse(node.attributes['start'] ?? '') ?? 1;
      _writeListChildren(
        node,
        buffer,
        ctx.copyWith(
          listDepth: ctx.listDepth + 1,
          inOrderedList: true,
        ),
        startIndex: start,
      );
      buffer.write('\n');
      return;

    case 'details':
      final summary = node.querySelector('summary');
      final summaryText =
          summary != null ? _childrenToInlineString(summary, ctx) : '';
      buffer.write('\n\n');
      if (summaryText.isNotEmpty) {
        buffer.write('**');
        buffer.write(summaryText);
        buffer.write('**\n\n');
      }
      for (final child in node.nodes) {
        if (child is dom.Element &&
            child.localName?.toLowerCase() == 'summary') {
          continue;
        }
        _writeNode(child, buffer, ctx);
      }
      buffer.write('\n\n');
      return;
    case 'summary':
      buffer.write('**');
      _writeChildren(node, buffer, ctx);
      buffer.write('**\n');
      return;

    case 'table':
      _writeTable(node, buffer, ctx);
      return;

    case 'thead':
    case 'tbody':
    case 'tfoot':
    case 'tr':
    case 'th':
    case 'td':
      _writeChildren(node, buffer, ctx);
      return;

    case 'dl':
      buffer.write('\n');
      _writeChildren(node, buffer, ctx);
      buffer.write('\n');
      return;
    case 'dt':
      buffer.write('\n**');
      _writeChildren(node, buffer, ctx);
      buffer.write('**\n');
      return;
    case 'dd':
      buffer.write(': ');
      _writeChildren(node, buffer, ctx);
      buffer.write('\n');
      return;

    default:
      _writeChildren(node, buffer, ctx);
      return;
  }
}

void _writeChildren(dom.Element el, StringBuffer buffer, _RenderCtx ctx) {
  for (final child in el.nodes) {
    _writeNode(child, buffer, ctx);
  }
}

String _childrenToInlineString(dom.Element el, _RenderCtx ctx) {
  final buf = StringBuffer();
  for (final child in el.nodes) {
    _writeNode(child, buf, ctx);
  }
  return buf.toString().replaceAll('\n', ' ').trim();
}

void _writeListChildren(
  dom.Element el,
  StringBuffer buffer,
  _RenderCtx ctx, {
  int startIndex = 1,
}) {
  int idx = startIndex;
  for (final child in el.nodes) {
    if (child is! dom.Element) continue;
    if (child.localName?.toLowerCase() != 'li') continue;
    final indent = '  ' * (ctx.listDepth - 1);
    final marker = ctx.inOrderedList ? '$idx.' : '-';
    buffer.write('$indent$marker ');
    final inner = StringBuffer();
    _writeChildren(child, inner, ctx);
    final text = inner.toString().trimRight();
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (i == 0) {
        buffer.write(lines[i].trimLeft());
      } else {
        buffer.write('\n$indent  ${lines[i]}');
      }
    }
    buffer.write('\n');
    idx++;
  }
}

void _writeTable(dom.Element table, StringBuffer buffer, _RenderCtx ctx) {
  final rows = <List<String>>[];
  final headerRows = <List<String>>[];

  for (final section in table.children) {
    final tag = section.localName?.toLowerCase();
    if (tag == 'thead') {
      for (final tr in section.children) {
        if (tr.localName?.toLowerCase() == 'tr') {
          headerRows.add(_extractRowCells(tr, ctx));
        }
      }
    } else if (tag == 'tbody' || tag == 'tfoot') {
      for (final tr in section.children) {
        if (tr.localName?.toLowerCase() == 'tr') {
          rows.add(_extractRowCells(tr, ctx));
        }
      }
    } else if (tag == 'tr') {
      final cells = _extractRowCells(section, ctx);
      final hasTh = section.children
          .any((c) => c.localName?.toLowerCase() == 'th');
      if (hasTh && headerRows.isEmpty && rows.isEmpty) {
        headerRows.add(cells);
      } else {
        rows.add(cells);
      }
    }
  }

  if (headerRows.isEmpty && rows.isEmpty) return;

  List<String> header;
  List<List<String>> body;
  if (headerRows.isNotEmpty) {
    header = headerRows.first;
    body = rows;
  } else {
    header = rows.first;
    body = rows.skip(1).toList();
  }

  buffer.write('\n\n');
  buffer.write('| ${header.join(' | ')} |\n');
  buffer.write('| ${List.filled(header.length, '---').join(' | ')} |\n');
  for (final row in body) {
    final padded = List<String>.from(row);
    while (padded.length < header.length) {
      padded.add('');
    }
    buffer.write('| ${padded.take(header.length).join(' | ')} |\n');
  }
  buffer.write('\n');
}

List<String> _extractRowCells(dom.Element tr, _RenderCtx ctx) {
  final cells = <String>[];
  for (final cell in tr.children) {
    final tag = cell.localName?.toLowerCase();
    if (tag == 'th' || tag == 'td') {
      cells.add(_escapeTableCell(_childrenToInlineString(cell, ctx)));
    }
  }
  return cells;
}
