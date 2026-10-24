import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/comment_markdown.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';

/// Only immutable rendering data crosses the isolate boundary, not models or UI.
@immutable
class DiffInlineComment {
  const new({
    required this.line,
    required this.author,
    required this.body,
  });

  /// Head-side line; outdated/removed-side comments have no inline destination.
  final int? line;
  final String author;
  final String? body;
}

@immutable
class DiffHtmlRequest {
  new({
    required this.patch,
    Iterable<DiffInlineComment> comments = const [],
  }) : comments = List.unmodifiable(comments);

  final String? patch;
  final List<DiffInlineComment> comments;
}

/// 2026-10-24 FPR-103: the complete CPU preparation belongs to one native
/// background job, including comment Markdown and the final HTML wrapper.
/// `compute` uses the current event loop on web; it is not a web CPU offload.
Future<String> renderDiffHtml(DiffHtmlRequest request) =>
    compute(_renderDiffHtml, request, debugLabel: 'Render diff HTML');

String _renderDiffHtml(DiffHtmlRequest request) {
  return HtmlUtils.generateCode2HTml(
    HtmlUtils.parseDiffSource(
      request.patch,
      false,
      addLineExtras: _buildAddLineExtras(request.comments),
    ),
    backgroundColor: GSYColors.webDraculaBackgroundColorString,
    lang: '',
    userBR: false,
  );
}

Map<int, String>? _buildAddLineExtras(List<DiffInlineComment> comments) {
  if (comments.isEmpty) return null;
  final buckets = <int, StringBuffer>{};
  for (final comment in comments) {
    // Keep the original A/3 head-line contract: originalLine/displayLine must
    // not anchor outdated comments to unrelated lines in the current patch.
    final line = comment.line;
    if (line == null) continue;
    final buffer = buckets.putIfAbsent(line, () => StringBuffer());
    final author = _htmlEscape(comment.author);
    final body = renderCommentBodyToInlineHtml(comment.body);
    buffer.write(
      '<div class="gsy-review-comment" '
      'style="background:#fff8e1;color:#222;border-left:3px solid #d97706;'
      'padding:6px 10px;margin:2px 0;font-family:sans-serif;'
      'font-size:12px;white-space:normal;">',
    );
    buffer.write(
      '<div style="font-weight:bold;color:#0366d6;'
      'margin-bottom:4px;">@$author</div>',
    );
    buffer.write('<div>$body</div>');
    buffer.write('</div>');
  }
  if (buckets.isEmpty) return null;
  return buckets.map((line, buffer) => MapEntry(line, buffer.toString()));
}

String _htmlEscape(String input) => input
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
