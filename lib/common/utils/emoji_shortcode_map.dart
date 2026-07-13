/// GitHub 用户 status emoji 常用 shortcode → unicode 映射
///
/// GitHub 的 `user.status.emoji` 字段返回的是 `:tada:` 这类 shortcode，
/// 官方 web 端会通过 emoji.js 完整字典渲染，但完整字典（1800+ 条）体积过大且
/// 大多在真实 status 中不会出现。本文件手工挑选约 60 条：
///
/// - **GitHub emoji picker 默认置顶那一档**（GitHub 服务端 API `/emojis` 里
///   排在前列的常见 status emoji：working / focus / away / sick / holiday 等）
/// - 常规 chat 场景高频（tada / heart / rocket / fire / bug / sparkles ...）
///
/// 未命中时 UI 层会 fallback 到 shortcode 原文本，保证不丢信息，只是稍丑。
///
/// 未来若发现真机日志里出现大量未命中，可参考
/// https://api.github.com/emojis 追加。**不引入 pub 包**，避免为一处 chip
/// 拉进整套 emoji 表和 Web asset。
const Map<String, String> emojiShortcodeMap = {
  // ==== 状态高频（GitHub status picker 默认档） ====
  ':computer:': '\u{1F4BB}',
  ':dart:': '\u{1F3AF}',
  ':coffee:': '\u2615',
  ':house:': '\u{1F3E0}',
  ':bus:': '\u{1F68C}',
  ':airplane:': '\u2708\uFE0F',
  ':island:': '\u{1F3DD}\uFE0F',
  ':palm_tree:': '\u{1F334}',
  ':beach:': '\u{1F3D6}\uFE0F',
  ':umbrella:': '\u2602\uFE0F',
  ':sunny:': '\u2600\uFE0F',
  ':zzz:': '\u{1F4A4}',
  ':sleeping:': '\u{1F634}',
  ':thermometer:': '\u{1F321}\uFE0F',
  ':mask:': '\u{1F637}',
  ':face_with_thermometer:': '\u{1F912}',
  ':nauseated_face:': '\u{1F922}',
  ':thought_balloon:': '\u{1F4AD}',
  ':speech_balloon:': '\u{1F4AC}',
  ':spiral_calendar:': '\u{1F5D3}\uFE0F',
  ':calendar:': '\u{1F4C5}',
  ':date:': '\u{1F4C6}',
  ':clock:': '\u{1F551}',
  ':hourglass:': '\u231B',
  ':hourglass_flowing_sand:': '\u23F3',

  // ==== 编码 / 工作 ====
  ':octocat:': '\u{1F419}', // GitHub 私有 emoji，用 :octopus: (🐙) 近似替代
  ':rocket:': '\u{1F680}',
  ':fire:': '\u{1F525}',
  ':bug:': '\u{1F41B}',
  ':sparkles:': '\u2728',
  ':zap:': '\u26A1',
  ':hammer:': '\u{1F528}',
  ':wrench:': '\u{1F527}',
  ':gear:': '\u2699\uFE0F',
  ':nut_and_bolt:': '\u{1F529}',
  ':pencil2:': '\u270F\uFE0F',
  ':memo:': '\u{1F4DD}',
  ':bookmark:': '\u{1F516}',
  ':books:': '\u{1F4DA}',
  ':book:': '\u{1F4D6}',
  ':mag:': '\u{1F50D}',
  ':lock:': '\u{1F512}',
  ':key:': '\u{1F511}',

  // ==== 情绪 / 反馈 ====
  ':tada:': '\u{1F389}',
  ':heart:': '\u2764\uFE0F',
  ':star:': '\u2B50',
  ':star2:': '\u{1F31F}',
  ':thumbsup:': '\u{1F44D}',
  ':thumbsdown:': '\u{1F44E}',
  ':clap:': '\u{1F44F}',
  ':pray:': '\u{1F64F}',
  ':muscle:': '\u{1F4AA}',
  ':wave:': '\u{1F44B}',
  ':eyes:': '\u{1F440}',
  ':thinking:': '\u{1F914}',
  ':smile:': '\u{1F604}',
  ':joy:': '\u{1F602}',
  ':heart_eyes:': '\u{1F60D}',
  ':sob:': '\u{1F62D}',
  ':rage:': '\u{1F621}',
  ':warning:': '\u26A0\uFE0F',
  ':white_check_mark:': '\u2705',
  ':x:': '\u274C',

  // ==== 常见旅行 / 生活 ====
  ':pizza:': '\u{1F355}',
  ':hamburger:': '\u{1F354}',
  ':cake:': '\u{1F370}',
  ':christmas_tree:': '\u{1F384}',
  ':jack_o_lantern:': '\u{1F383}',
};

/// 将 GitHub shortcode 解析为可显示的字符串。
///
/// 语义：
/// - 输入 `null` / 空串: 返回 `null`（UI 侧据此隐藏 emoji 位）
/// - 命中映射: 返回对应 unicode 序列
/// - 未命中: 返回 shortcode 原文本（不丢信息，视觉上是 `:foo:`）
String? resolveEmojiShortcode(String? shortcode) {
  if (shortcode == null || shortcode.isEmpty) return null;
  return emojiShortcodeMap[shortcode] ?? shortcode;
}
