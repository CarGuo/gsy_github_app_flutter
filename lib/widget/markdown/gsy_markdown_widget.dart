import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/widget/markdown/syntax_high_lighter.dart';

/**
 * 代码详情
 * Created by guoshuyu
 * Date: 2018-07-24
 */

class GSYMarkdownWidget extends StatelessWidget {
  static const int DARK_WHITE = 0;

  static const int DARK_LIGHT = 1;

  static const int DARK_THEME = 2;

  final String? markdownData;

  final int style;

  GSYMarkdownWidget({this.markdownData = "", this.style = DARK_WHITE});

  _getCommonSheet(BuildContext context, Color codeBackground) {
    MarkdownStyleSheet markdownStyleSheet =
        MarkdownStyleSheet.fromTheme(Theme.of(context));
    return markdownStyleSheet
        .copyWith(
            codeblockDecoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: codeBackground,
                border:
                    new Border.all(color: GSYColors.subTextColor, width: 0.3)))
        .copyWith(
            blockquoteDecoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: GSYColors.subTextColor,
                border:
                    new Border.all(color: GSYColors.subTextColor, width: 0.3)),
            blockquote: GSYConstant.smallTextWhite);
  }

  _getStyleSheetDark(BuildContext context) {
    return _getCommonSheet(context, Color.fromRGBO(40, 44, 52, 1.00)).copyWith(
      p: GSYConstant.smallTextWhite,
      h1: GSYConstant.largeLargeTextWhite,
      h2: GSYConstant.largeTextWhiteBold,
      h3: GSYConstant.normalTextMitWhiteBold,
      h4: GSYConstant.middleTextWhite,
      h5: GSYConstant.smallTextWhite,
      h6: GSYConstant.smallTextWhite,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: GSYConstant.middleTextWhiteBold,
      code: GSYConstant.smallSubText,
    );
  }

  _getStyleSheetWhite(BuildContext context) {
    return _getCommonSheet(context, Color.fromRGBO(40, 44, 52, 1.00)).copyWith(
      p: GSYConstant.smallText,
      h1: GSYConstant.largeLargeText,
      h2: GSYConstant.largeTextBold,
      h3: GSYConstant.normalTextBold,
      h4: GSYConstant.middleText,
      h5: GSYConstant.smallText,
      h6: GSYConstant.smallText,
      strong: GSYConstant.middleTextBold,
      code: GSYConstant.smallSubText,
    );
  }

  _getStyleSheetTheme(BuildContext context) {
    return _getCommonSheet(context, Color.fromRGBO(40, 44, 52, 1.00)).copyWith(
      p: GSYConstant.smallTextWhite,
      h1: GSYConstant.largeLargeTextWhite,
      h2: GSYConstant.largeTextWhiteBold,
      h3: GSYConstant.normalTextMitWhiteBold,
      h4: GSYConstant.middleTextWhite,
      h5: GSYConstant.smallTextWhite,
      h6: GSYConstant.smallTextWhite,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: GSYConstant.middleTextWhiteBold,
      code: GSYConstant.smallSubText,
    );
  }

  _getBackgroundColor(context) {
    Color background = GSYColors.white;
    switch (style) {
      case DARK_LIGHT:
        background = GSYColors.primaryLightValue;
        break;
      case DARK_THEME:
        background = Theme.of(context).primaryColor;
        break;
    }
    return background;
  }

  _getStyle(BuildContext context) {
    var styleSheet = _getStyleSheetWhite(context);
    switch (style) {
      case DARK_LIGHT:
        styleSheet = _getStyleSheetDark(context);
        break;
      case DARK_THEME:
        styleSheet = _getStyleSheetTheme(context);
        break;
    }
    return styleSheet;
  }

  _getMarkDownData(String markdownData) {
    ///优化图片显示
    RegExp exp = new RegExp(r'!\[.*\]\((.+)\)');
    RegExp expImg = new RegExp("<img.*?(?:>|\/>)");
    RegExp expSrc = new RegExp("src=[\'\"]?([^\'\"]*)[\'\"]?");

    String mdDataCode = markdownData;
    try {
      Iterable<Match> tags = exp.allMatches(markdownData);
      if (tags.length > 0) {
        for (Match m in tags) {
          String? imageMatch = m.group(0);
          if (imageMatch != null && !imageMatch.contains(".svg")) {
            String match = imageMatch.replaceAll("\)", "?raw=true)");
            if (!match.contains(".svg") && match.contains("http")) {
              ///增加点击
              String src = match
                  .replaceAll(new RegExp(r'!\[.*\]\('), "")
                  .replaceAll(")", "");
              String actionMatch = "[$match]($src)";
              match = actionMatch;
            } else {
              match = "";
            }
            mdDataCode = mdDataCode.replaceAll(m.group(0)!, match);
          }
        }
      }

      ///优化img标签的src资源
      tags = expImg.allMatches(markdownData);
      if (tags.length > 0) {
        for (Match m in tags) {
          String? imageTag = m.group(0);
          String? match = imageTag;
          if (imageTag != null) {
            Iterable<Match> srcTags = expSrc.allMatches(imageTag);
            for (Match srcMatch in srcTags) {
              String? srcString = srcMatch.group(0);
              if (srcString != null && srcString.contains("http")) {
                String newSrc = srcString.substring(
                        srcString.indexOf("http"), srcString.length - 1) +
                    "?raw=true";

                ///增加点击
                match = "[![]($newSrc)]($newSrc)";
              }
            }
          }
          mdDataCode = mdDataCode.replaceAll(imageTag!, match!);
        }
      }
    } catch (e) {
      print(e.toString());
    }
    return mdDataCode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(context),
      padding: EdgeInsets.all(5.0),
      child: SingleChildScrollView(
        child: new MarkdownBody(
          styleSheet: _getStyle(context),
          syntaxHighlighter: new GSYHighlighter(),
          data: _getMarkDownData(markdownData!),
          imageBuilder: (Uri? uri, String? title, String? alt) {
            if (uri == null || uri.toString().isEmpty) return const SizedBox();
            final StringList parts = uri.toString().split('#');
            double? width;
            double? height;
            if (parts.length == 2) {
              final StringList dimensions = parts.last.split('x');
              if (dimensions.length == 2) {
                var [ws, hs] = dimensions;
                width = double.parse(ws);
                height = double.parse(hs);
              }
            }
            return kDefaultImageBuilder(uri, "", width, height);
          },
          onTapLink: (String text, String? href, String title) {
            CommonUtils.gsyLaunchUrl(context, href);
          },
        ),
      ),
    );
  }
}

class GSYHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    String showSource = source.replaceAll("&lt;", "<");
    showSource = showSource.replaceAll("&gt;", ">");
    return new DartSyntaxHighlighter().format(showSource);
  }
}

Widget kDefaultImageBuilder(
  Uri uri,
  String? imageDirectory,
  double? width,
  double? height,
) {
  if (uri.scheme.isEmpty) {
    return SizedBox();
  }
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return Image.network(uri.toString(), width: width, height: height);
  } else if (uri.scheme == 'data') {
    return _handleDataSchemeUri(uri, width, height);
  } else if (uri.scheme == "resource") {
    return Image.asset(uri.path, width: width, height: height);
  } else {
    Uri fileUri = imageDirectory != null
        ? Uri.parse(imageDirectory + uri.toString())
        : uri;
    if (fileUri.scheme == 'http' || fileUri.scheme == 'https') {
      return Image.network(fileUri.toString(), width: width, height: height);
    } else {
      return Image.file(File.fromUri(fileUri), width: width, height: height);
    }
  }
}

Widget _handleDataSchemeUri(
    Uri uri, final double? width, final double? height) {
  final String mimeType = uri.data!.mimeType;
  if (mimeType.startsWith('image/')) {
    return Image.memory(
      uri.data!.contentAsBytes(),
      width: width,
      height: height,
    );
  } else if (mimeType.startsWith('text/')) {
    return Text(uri.data!.contentAsString());
  }
  return const SizedBox();
}
