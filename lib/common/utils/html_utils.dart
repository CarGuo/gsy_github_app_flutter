// ignore_for_file: unnecessary_string_escapes, prefer_adjacent_string_concatenation

import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/// Created by guoshuyu
/// on 2018/7/27.

class HtmlUtils {
  static generateCode2HTml(String? mdData,
      {String backgroundColor = GSYColors.miWhiteString,
      String lang = 'java',
      userBR = true}) {
    String currentData = (mdData != null && !mdData.contains("<code>"))
        ? "<body>\n<pre>\n<code lang='$lang'>\n$mdData</code>\n</pre>\n</body>\n"
        : "<body>\n<pre>\n${mdData!}</pre>\n</body>\n";
    return generateHtml(currentData,
        backgroundColor: backgroundColor, userBR: userBR);
  }

  static generateHtml(String? mdData,
      {String backgroundColor = GSYColors.webDraculaBackgroundColorString,
      userBR = true}) {
    if (mdData == null) {
      return "";
    }
    String mdDataCode = mdData;
    String regExCode =
        "<[\\s]*?code[^>]*?>[\\s\\S]*?<[\\s]*?\\/[\\s]*?code[\\s]*?>";
    String regExPre =
        "<[\\s]*?pre[^>]*?>[\\s\\S]*?<[\\s]*?\\/[\\s]*?pre[\\s]*?>";

    try {
      RegExp exp = RegExp(regExCode);
      Iterable<Match> tags = exp.allMatches(mdData);
      for (Match m in tags) {
        String match = m.group(0)!.replaceAll(RegExp("\n"), "\n\r<br>");
        mdDataCode = mdDataCode.replaceAll(m.group(0)!, match);
      }
    } catch (e) {
      printLog(e);
    }
    try {
      RegExp exp = RegExp(regExPre);
      Iterable<Match> tags = exp.allMatches(mdDataCode);
      for (Match m in tags) {
        if (!m.group(0)!.contains("<code>")) {
          String match = m.group(0)!.replaceAll(RegExp("\n"), "\n\r<br>");
          mdDataCode = mdDataCode.replaceAll(m.group(0)!, match);
        }
      }
    } catch (e) {
      printLog(e);
    }

    try {
      RegExp exp = RegExp("<pre>(([\\s\\S])*?)<\/pre>");
      Iterable<Match> tags = exp.allMatches(mdDataCode);
      for (Match m in tags) {
        if (!m.group(0)!.contains("<code>")) {
          String match = m.group(0)!.replaceAll(RegExp("\n"), "\n\r<br>");
          mdDataCode = mdDataCode.replaceAll(m.group(0)!, match);
        }
      }
    } catch (e) {
      printLog(e);
    }
    try {
      RegExp exp = RegExp("href=\"(.*?)\"");
      Iterable<Match> tags = exp.allMatches(mdDataCode);
      for (Match m in tags) {
        String capture = m.group(0)!;
        if (!capture.contains("http://") &&
            !capture.contains("https://") &&
            capture.indexOf("#") != 0) {
          mdDataCode =
              mdDataCode.replaceAll(m.group(0)!, "gsygithub://$capture");
        }
      }
    } catch (e) {
      printLog(e);
    }

    return generateCodeHtml(mdDataCode, false,
        backgroundColor: backgroundColor,
        actionColor: GSYColors.actionBlueString,
        userBR: userBR);
  }

  /// style for mdHTml
  ///
  /// A/4 修复"配色割裂 + 移动端不适配"：
  /// - **主题联动**：以 [backgroundColor] 判定深/浅主题。深色（dracula
  ///   `#282a36`）挂 highlight.js `atom-one-dark` 主题、正文文字 `#e5e7eb`；
  ///   浅色挂 `github` 主题、正文文字 `#24292f`。之前**固定挂浅色 `default`
  ///   主题**却把 body 设成深色 dracula，导致 hljs 输出的深色 token 在深底
  ///   上几乎不可见——这是"配色割裂"的直接根因
  /// - **移动端排版**：加 `-webkit-text-size-adjust:100%`、`padding:12px`、
  ///   `line-height:1.55`、`font-family: ui-monospace / SFMono-Regular /
  ///   Menlo / Consolas / monospace`、`font-size:14px`；`pre { overflow-x:
  ///   auto; -webkit-overflow-scrolling: touch; }`，长行可横向滑动而不撑破
  ///   viewport
  /// - **A/3 内联评论卡片**：`.gsy-review-comment` 保留浅底黄+橙色左边框，
  ///   在深底 diff 上刻意"贴纸感"以便凸显评论，与主题解耦——这是有意的
  static generateCodeHtml(mdHTML, wrap,
      {backgroundColor = GSYColors.white,
      String actionColor = GSYColors.actionBlueString,
      userBR = true}) {
    final bool isDark =
        backgroundColor == GSYColors.webDraculaBackgroundColorString;
    final String hljsTheme = isDark ? 'atom-one-dark' : 'github';
    final String textColor = isDark ? '#e5e7eb' : '#24292f';
    final String wrapCss = wrap
        ? 'word-wrap: break-word; white-space: pre-wrap;'
        : 'word-wrap: normal; white-space: pre;';
    return '''<html>
<head>
<meta charset="utf-8" />
<title></title>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0"/>
<meta name="apple-mobile-web-app-capable" content="yes" />
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/$hljsTheme.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/languages/go.min.js"></script>
<script>hljs.configure({'useBR': ${userBR.toString()}});hljs.initHighlightingOnLoad();</script>
<style>
html, body { margin:0; padding:0; -webkit-text-size-adjust:100%; }
body {
  background: $backgroundColor;
  color: $textColor;
  padding: 12px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 14px;
  line-height: 1.55;
}
a { color: $actionColor !important; word-break: break-all; }
.highlight pre, pre {
  $wrapCss
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  background: transparent;
}
code { font-family: inherit; }
.highlight { overflow: auto; background: transparent; }
table { border-collapse: collapse; width: 100%; }
thead, tr { background: ${GSYColors.miWhiteString}; }
td, th { padding: 5px 10px; font-size: 12px; }
tr:nth-child(even) { background: ${GSYColors.primaryLightValueString}; color: ${GSYColors.miWhiteString}; }
tr:nth-child(odd)  { background: ${GSYColors.miWhiteString}; color: ${GSYColors.primaryLightValueString}; }
th { font-size: 14px; color: ${GSYColors.miWhiteString}; background: ${GSYColors.primaryLightValueString}; }
.gsy-review-comment { max-width: 100%; box-sizing: border-box; }
</style>
</head>
<body>
$mdHTML
</body>
</html>''';
  }

  /// 解析 GitHub PR / commit diff 的 `patch` 字符串为高亮 HTML。
  ///
  /// [addLineExtras]：**A/3 内联评审评论**用。
  /// - key = diff **head 分支侧的行号**（即函数内 `curAddNumber`；
  ///   命中的行类型包括 `+` addition 行**和** ` ` context 行——命名里的
  ///   "add" 指"追加内联片段"这个动作，**不**限于 `+` 语法行。请勿望文生义
  /// - value = 已经预生成好的 HTML 片段（多条 comment 由调用方拼好）
  /// - 命中时会在**该行的 `<div>` 之后**追加一个兄弟节点，实现"评论跟在
  ///   源码行下方"的视觉
  ///
  /// 为什么不把 [PullReviewComment] 直接下推到本 util：
  /// - 本 util 不应依赖上层 model；保持 utils 分层干净
  /// - body 是 markdown，渲染需 [GSYMarkdownWidget] 或外部 markdown 转 HTML；
  ///   谁调用谁决定渲染方式，util 只做字符串拼接
  ///
  /// 兼容：不传 [addLineExtras] 时输出与 A/2 完全一致。
  static parseDiffSource(String? diffSource, bool wrap,
      {Map<int, String>? addLineExtras}) {
    if (diffSource == null) {
      return "";
    }
    List<String> lines = diffSource.split("\n");
    String source = "";
    int addStartLine = -1;
    int removeStartLine = -1;
    int addLineNum = 0;
    int removeLineNum = 0;
    int normalLineNum = 0;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      String? lineNumberStr = "";
      String classStr = "";
      int curAddNumber = -1;
      int curRemoveNumber = -1;

      if (line.indexOf("+") == 0) {
        classStr = "class=\"hljs-addition\";";
        curAddNumber = addStartLine + normalLineNum + addLineNum;
        addLineNum++;
      } else if (line.indexOf("-") == 0) {
        classStr = "class=\"hljs-deletion\";";
        curRemoveNumber = removeStartLine + normalLineNum + removeLineNum;
        removeLineNum++;
      } else if (line.indexOf("@@") == 0) {
        classStr = "class=\"hljs-literal\";";
        removeStartLine = getRemoveStartLine(line);
        addStartLine = getAddStartLine(line);
        addLineNum = 0;
        removeLineNum = 0;
        normalLineNum = 0;
      } else if (!(line.indexOf("\\") == 0)) {
        curAddNumber = addStartLine + normalLineNum + addLineNum;
        curRemoveNumber = removeStartLine + normalLineNum + removeLineNum;
        normalLineNum++;
      }
      lineNumberStr = getDiffLineNumber(
          curRemoveNumber == -1 ? "" : ("$curRemoveNumber"),
          curAddNumber == -1 ? "" : ("$curAddNumber"));
      source =
          "$source<div $classStr>${wrap ? "" : lineNumberStr! + getBlank(1)}$line</div>";
      // A/3：若本行命中 review comment（按 head 分支行号 curAddNumber 匹配），
      // 追加内联评论片段。只匹配 +/context 行；removed 行 (-) 走 originalLine
      // 侧、GitHub 官方 UI 也少见针对已删除行的 comment，先不覆盖。
      if (addLineExtras != null && curAddNumber != -1) {
        final String? extra = addLineExtras[curAddNumber];
        if (extra != null && extra.isNotEmpty) {
          source = "$source$extra";
        }
      }
    }
    return source;
  }

  static getRemoveStartLine(line) {
    try {
      return int.parse(
          line.substring(line.indexOf("-") + 1, line.indexOf(",")));
    } catch (e) {
      return 1;
    }
  }

  static getAddStartLine(line) {
    try {
      return int.parse(line.substring(
          line.indexOf("+") + 1, line.indexOf(",", line.indexOf("+"))));
    } catch (e) {
      return 1;
    }
  }

  static getDiffLineNumber(String removeNumber, String addNumber) {
    int minLength = 4;
    return getBlank(minLength - removeNumber.length) +
        removeNumber +
        getBlank(1) +
        getBlank(minLength - addNumber.length) +
        addNumber;
  }

  // ignore: avoid_types_as_parameter_names
  static getBlank(num) {
    String builder = "";
    for (int i = 0; i < num; i++) {
      builder += " ";
    }
    return builder;
  }

  static resolveHtmlFile(var res, String defaultLang) {
    if (res != null && res.result) {
      String startTag = "class=\"instapaper_body ";
      int startLang = res.data.indexOf(startTag);
      int? endLang = res.data.indexOf("\" data-path=\"");
      String? lang;
      if (startLang >= 0 && endLang! >= 0) {
        String? tmpLang =
            res.data.substring(startLang + startTag.length, endLang);
        if (tmpLang != null) {
          lang = formName(tmpLang.toLowerCase());
        }
      }
      lang ??= defaultLang;
      if ('markdown' == lang || 'md' == lang) {
        return generateHtml(res.data, backgroundColor: GSYColors.miWhiteString);
      } else {
        return generateCode2HTml(res.data,
            backgroundColor: GSYColors.webDraculaBackgroundColorString,
            lang: lang);
      }
    } else {
      return "<h1>Not Support</h1>";
    }
  }

  static formName(name) {
    switch (name) {
      case 'sh':
        return 'shell';
      case 'js':
        return 'javascript';
      case 'kt':
        return 'kotlin';
      case 'c':
      case 'cpp':
        return 'cpp';
      case 'md':
        return 'markdown';
      case 'html':
        return 'xml';
    }
    return name;
  }
}
