import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/page/discussion/release_footer.dart';

void main() {
  group('extractReleaseFooter - 基础命中', () {
    test('BettaFish #511 真实 fixture（v3.0.0，中文 title）', () {
      const body =
          '<p dir="auto">正文段落一</p>\n<p dir="auto">正文段落二</p>\n<hr><em>This discussion was created from the release <a href="https://github.com/666ghj/BettaFish/releases/tag/v3.0.0">微舆v3.0.0</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info, isNotNull);
      expect(r.info!.tag, 'v3.0.0');
      expect(r.info!.title, '微舆v3.0.0');
      expect(r.info!.releaseUrl,
          'https://github.com/666ghj/BettaFish/releases/tag/v3.0.0');
      expect(r.strippedBody,
          '<p dir="auto">正文段落一</p>\n<p dir="auto">正文段落二</p>');
    });

    test('`<hr />` 自闭合形态也能吃', () {
      const body =
          '<p>x</p><hr /><em>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/v1">v1</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info?.tag, 'v1');
      expect(r.strippedBody, '<p>x</p>');
    });

    test('前后允许多余空白 / 换行', () {
      const body =
          '<p>x</p>\n\n  <hr>  \n  <em>  This discussion was created from the release  <a href="https://github.com/o/r/releases/tag/v9">Ver 9</a>  .  </em>  \n  ';
      final r = extractReleaseFooter(body);
      expect(r.info, isNotNull);
      expect(r.info!.tag, 'v9');
      expect(r.info!.title, 'Ver 9');
      expect(r.strippedBody, '<p>x</p>');
    });

    test('caseSensitive: false —— HR / EM 大写也吃', () {
      const body =
          '<p>x</p><HR><EM>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/v2">v2</a>.</EM>';
      final r = extractReleaseFooter(body);
      expect(r.info?.tag, 'v2');
    });
  });

  group('extractReleaseFooter - href / tag 抽取', () {
    test('tag 是纯数字点号形态', () {
      const body =
          '<hr><em>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/1.2.3-beta.4">1.2.3-beta.4</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info?.tag, '1.2.3-beta.4');
    });

    test('URL 带 query string / fragment 时，tag 只取到分隔符前', () {
      const body =
          '<hr><em>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/v3?foo=bar#hash">v3</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info?.tag, 'v3');
      expect(r.info?.releaseUrl,
          'https://github.com/o/r/releases/tag/v3?foo=bar#hash');
    });

    test('HTML entity 的 title 会做最小解码', () {
      const body =
          '<hr><em>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/v4">A &amp; B &lt;dev&gt;</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info?.title, 'A & B <dev>');
    });
  });

  group('extractReleaseFooter - 未命中场景', () {
    test('body 里没有 footer → 原样返回、info=null', () {
      const body = '<p>纯正文，没有 hr em release 链接</p>';
      final r = extractReleaseFooter(body);
      expect(r.info, isNull);
      expect(r.strippedBody, body);
    });

    test('href 不是 releases/tag/ 形态（例如指向 releases 首页）→ 不吃', () {
      const body =
          '<hr><em>This discussion was created from the release <a href="https://github.com/o/r/releases">v0</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info, isNull);
      expect(r.strippedBody, body);
    });

    test('footer 后面还挂了别的段落（不在 body 末尾）→ 不吃', () {
      const body =
          '<hr><em>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/v5">v5</a>.</em><p>后面还有一段用户加的话</p>';
      final r = extractReleaseFooter(body);
      expect(r.info, isNull);
      expect(r.strippedBody, body);
    });

    test('body 里正文有 releases/tag 链接，但没有 <hr><em> 前缀 → 不吃', () {
      const body =
          '<p>参考 <a href="https://github.com/o/r/releases/tag/v6">v6</a> 的说明</p>';
      final r = extractReleaseFooter(body);
      expect(r.info, isNull);
      expect(r.strippedBody, body);
    });

    test('多次出现 releases/tag，但只有真正的 footer 才被剥离', () {
      const body =
          '<p>看这里：<a href="https://github.com/o/r/releases/tag/v7">v7</a></p>\n<hr><em>This discussion was created from the release <a href="https://github.com/o/r/releases/tag/v8">v8</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info?.tag, 'v8');
      expect(r.strippedBody,
          '<p>看这里：<a href="https://github.com/o/r/releases/tag/v7">v7</a></p>');
    });

    test('文案不匹配（英文变体）→ 不吃，避免误伤', () {
      const body =
          '<hr><em>This is discussion for release <a href="https://github.com/o/r/releases/tag/v9">v9</a>.</em>';
      final r = extractReleaseFooter(body);
      expect(r.info, isNull);
    });

    test('空 body → info=null，原样返回空串', () {
      final r = extractReleaseFooter('');
      expect(r.info, isNull);
      expect(r.strippedBody, '');
    });
  });

  group('ReleaseFooterInfo 值语义', () {
    test('相同字段 == / hashCode 一致', () {
      const a = ReleaseFooterInfo(
          tag: 'v1', title: 't', releaseUrl: 'https://x/releases/tag/v1');
      const b = ReleaseFooterInfo(
          tag: 'v1', title: 't', releaseUrl: 'https://x/releases/tag/v1');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
