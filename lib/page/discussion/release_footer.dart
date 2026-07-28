/// Discussion "linked to a release" footer 识别与抽离。
///
/// GitHub 在把一个 discussion 关联到某个 release 时，会在 `bodyHTML` 末尾
/// 自动追加一段固定结构（探针实测 BettaFish #511 → v3.0.0，见
/// `build/smoke/disc_511_page.html` line 1619）：
///
/// ```html
/// <hr><em>This discussion was created from the release
/// <a href="https://github.com/{owner}/{repo}/releases/tag/{tag}">{title}</a>.</em>
/// ```
///
/// 直接把这段交给 markdown 渲染只能得到"分割线 + 斜体链接"的普通展现，
/// 无法突出"这是与某 release 绑定的讨论"这一强语义。本文件提供纯 Dart
/// 抽取函数 [extractReleaseFooter]：识别到就把 footer 段从 body 里剥离，
/// 让详情页把剩余 body 交给 markdown、footer 单独渲染成一张卡片。
///
/// 设计约束：
/// - **无 Flutter 依赖**：便于单测；UI 卡片的组装留给 discussion_detail_page.dart
/// - **保守匹配**：只吞真正的 release footer，不误伤正文里出现的
///   `releases/tag/...` 链接（正文里可能有多个 releases 链接，我们只吞
///   末尾这段严格的 `<hr><em>This discussion was created from the release
///   <a href="...releases/tag/...">TITLE</a>.</em>`）
/// - **幂等**：未命中时返回 `(bodyHTML, null)` 原样透传
library;

/// 一次成功识别的 release footer 信息。
///
/// - [tag]：release tag（如 `v3.0.0`），从 href 里 `/releases/tag/` 之后抽出
/// - [title]：release 展示名（如"微舆v3.0.0"），来自 `<a>...</a>` 之间的文本，
///   已按 HTML entity 解码常见几个（`&amp;` / `&lt;` / `&gt;` / `&quot;` / `&#39;`）
/// - [releaseUrl]：完整的 release 网页地址，`<a href="...">` 原值
class ReleaseFooterInfo {
  const ReleaseFooterInfo({
    required this.tag,
    required this.title,
    required this.releaseUrl,
  });

  final String tag;
  final String title;
  final String releaseUrl;

  @override
  bool operator ==(Object other) =>
      other is ReleaseFooterInfo &&
      other.tag == tag &&
      other.title == title &&
      other.releaseUrl == releaseUrl;

  @override
  int get hashCode => Object.hash(tag, title, releaseUrl);

  @override
  String toString() =>
      'ReleaseFooterInfo(tag: $tag, title: $title, releaseUrl: $releaseUrl)';
}

/// 从 [bodyHTML] 末尾抽离 release-linked footer 结构。
///
/// 返回 `(strippedBody, info)`：
/// - 命中：`strippedBody` 是剥离 footer 段后的 body（去掉尾部空白）；
///   `info` 是解析出的 [ReleaseFooterInfo]
/// - 未命中：`strippedBody == bodyHTML`（原样），`info == null`
///
/// 保守正则策略：
/// - 必须在 body 末尾（允许尾部空白 / 换行）
/// - `<hr>` 与 `<em>` 之间允许空白 / 换行 / 属性（`<hr/>` / `<hr />` 都吃）
/// - `<a href>` 必须走 `https://github.com/{owner}/{repo}/releases/tag/{tag}`
///   形态，`{tag}` 不含空格 / `"` / `<`
/// - title 允许非贪婪任意字符（含中文），但不含 `<`（避免吞下一个标签）
({String strippedBody, ReleaseFooterInfo? info}) extractReleaseFooter(
    String bodyHTML) {
  if (bodyHTML.isEmpty) {
    return (strippedBody: bodyHTML, info: null);
  }

  final RegExp pattern = RegExp(
    r'''\s*<hr\s*/?>\s*<em>\s*This discussion was created from the release\s*<a\s+href=(?:"([^"]+)"|'([^']+)')\s*>([^<]+)</a>\s*\.\s*</em>\s*$''',
    caseSensitive: false,
    multiLine: false,
  );

  final Match? m = pattern.firstMatch(bodyHTML);
  if (m == null) {
    return (strippedBody: bodyHTML, info: null);
  }

  final String href = (m.group(1) ?? m.group(2) ?? '').trim();
  final String titleRaw = (m.group(3) ?? '').trim();
  if (href.isEmpty || titleRaw.isEmpty) {
    return (strippedBody: bodyHTML, info: null);
  }

  final String? tag = _extractTagFromReleaseUrl(href);
  if (tag == null || tag.isEmpty) {
    return (strippedBody: bodyHTML, info: null);
  }

  final String title = _decodeMinimalEntities(titleRaw);
  final String stripped = bodyHTML.substring(0, m.start).trimRight();

  return (
    strippedBody: stripped,
    info: ReleaseFooterInfo(tag: tag, title: title, releaseUrl: href),
  );
}

/// 从 release URL 里抽 tag：
///
/// 只接受 `https://github.com/{owner}/{repo}/releases/tag/{tag}` 形态；
/// `{tag}` 可能含 `.` / `-` / 中文；到下一个 `/` 或 `?` 或 `#` 或 end 为止。
String? _extractTagFromReleaseUrl(String url) {
  const String marker = '/releases/tag/';
  final int idx = url.indexOf(marker);
  if (idx < 0) return null;
  final int start = idx + marker.length;
  if (start >= url.length) return null;
  int end = url.length;
  for (int i = start; i < url.length; i++) {
    final int c = url.codeUnitAt(i);
    // '/' 47, '?' 63, '#' 35
    if (c == 47 || c == 63 || c == 35) {
      end = i;
      break;
    }
  }
  return url.substring(start, end);
}

/// 只解码 GitHub 生成 anchor 文本时最常见的几个 HTML entity。
///
/// GitHub 的 discussion HTML 是走 Ruby 侧渲染的，实际观察到 title 里最多
/// 出现 `&amp;` / `&lt;` / `&gt;` / `&quot;` / `&#39;`；不引入完整 entity
/// 解码库，避免 42KB 依赖为一个尾巴功能爆包。
String _decodeMinimalEntities(String s) {
  return s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}
