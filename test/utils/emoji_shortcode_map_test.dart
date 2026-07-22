import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';

void main() {
  group('resolveEmojiShortcode 基本语义', () {
    test('null 输入返回 null', () {
      expect(resolveEmojiShortcode(null), isNull);
    });

    test('空串返回 null', () {
      expect(resolveEmojiShortcode(''), isNull);
    });

    test('未命中返回 shortcode 原文本（不丢信息）', () {
      const unknown = ':this_shortcode_definitely_not_in_table:';
      expect(resolveEmojiShortcode(unknown), unknown);
    });
  });

  group('GitHub Discussions 默认 category emoji 契约（回归防线）', () {
    // 来源：https://docs.github.com/en/discussions 默认 6 大分类。
    // 真机 fixture 666ghj/BettaFish 讨论列表实际会同时出现 :bulb: / :mega:，
    // 2026-07-21 一次真机 smoke 曾因缺表项导致 chip 显示为 ":bulb: Ideas" 原文本。
    // 此表任一条被删都会让 UI 回归到 shortcode 原文本，故用契约测试锁死。
    //
    // 关于 General：GitHub 近版本官方默认已从 💬 :speech_balloon: 迁到 #️⃣ :hash:；
    // 但用户创建 repo 时若沿用早期默认或自定义分类，:speech_balloon: 仍会出现。
    // 两条都需要能命中，不能锁死单一值。
    const expected = <String, String>{
      ':mega:': '\u{1F4E3}', // Announcements 📣
      ':bulb:': '\u{1F4A1}', // Ideas 💡
      ':pray:': '\u{1F64F}', // Q&A 🙏
      ':ballot_box:': '\u{1F5F3}\uFE0F', // Polls 🗳️
      ':raised_hands:': '\u{1F64C}', // Show and tell 🙌
    };

    expected.forEach((shortcode, unicode) {
      test('$shortcode → $unicode', () {
        expect(resolveEmojiShortcode(shortcode), unicode);
      });
    });

    test('General 的两个官方 shortcode 都必须命中（不锁死单一值）', () {
      // #️⃣ 现行默认；💬 历史默认。任一被上游返回都不应回落到原文本。
      expect(resolveEmojiShortcode(':hash:'), '#\uFE0F\u20E3');
      expect(resolveEmojiShortcode(':speech_balloon:'), '\u{1F4AC}');
    });

    test('返回值不得等于原 shortcode（sanity check，主契约仍以严格等值断言为准）', () {
      final keys = <String>[
        ...expected.keys,
        ':hash:',
        ':speech_balloon:',
      ];
      for (final shortcode in keys) {
        expect(resolveEmojiShortcode(shortcode), isNot(shortcode),
            reason: '$shortcode 应被解析为 Unicode，而不是原样返回');
      }
    });
  });
}
