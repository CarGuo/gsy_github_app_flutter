import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';

/**
 * 代码详情
 * Created by guoshuyu
 * Date: 2018-07-24
 */

class GSYMarkdownWidget extends StatelessWidget {
  static const int DARK_WHITE = 0;

  static const int DARK_LIGHT = 1;

  static const int DARK_THEME = 2;

  final String markdownData;

  final int style;

  GSYMarkdownWidget({this.markdownData = "", this.style = DARK_WHITE});

  _getCommonSheet(BuildContext context, Color codeBackground) {
    MarkdownStyleSheet markdownStyleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return markdownStyleSheet
        .copyWith(
            codeblockDecoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: codeBackground,
                border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)))
        .copyWith(
            blockquoteDecoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: Color(GSYColors.subTextColor),
                border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)),
            blockquote: GSYConstant.smallTextWhite);
  }

  _getStyleSheetDark(BuildContext context) {
    return _getCommonSheet(context, Color(GSYColors.primaryValue)).copyWith(
      p: GSYConstant.smallTextWhite,
      h1: GSYConstant.largeLargeTextWhite,
      h2: GSYConstant.largeTextWhite,
      h3: GSYConstant.normalTextWhite,
      h4: GSYConstant.middleTextWhite,
      h5: GSYConstant.smallTextWhite,
      h6: GSYConstant.smallTextWhite,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: GSYConstant.middleTextWhite,
      code: GSYConstant.subSmallText,
    );
  }

  _getStyleSheetWhite(BuildContext context) {
    return _getCommonSheet(context, Color(GSYColors.primaryValue)).copyWith(
      p: GSYConstant.smallText,
      h1: GSYConstant.largeLargeText,
      h2: GSYConstant.largeText,
      h3: GSYConstant.normalText,
      h4: GSYConstant.middleText,
      h5: GSYConstant.smallText,
      h6: GSYConstant.smallText,
      strong: GSYConstant.middleText,
      code: GSYConstant.subSmallText,
    );
  }

  _getStyleSheetTheme(BuildContext context) {
    return _getCommonSheet(context, Color(GSYColors.subTextColor)).copyWith(
      p: GSYConstant.smallTextWhite,
      h1: GSYConstant.largeLargeTextWhite,
      h2: GSYConstant.largeTextWhite,
      h3: GSYConstant.normalTextWhite,
      h4: GSYConstant.middleTextWhite,
      h5: GSYConstant.smallTextWhite,
      h6: GSYConstant.smallTextWhite,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: GSYConstant.middleTextWhite,
      code: GSYConstant.subSmallText,
    );
  }

  _getBackgroundColor() {
    Color background = Color(GSYColors.white);
    switch (style) {
      case DARK_LIGHT:
        background = Color(GSYColors.primaryLightValue);
        break;
      case DARK_THEME:
        background = Color(GSYColors.primaryValue);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(),
      padding: EdgeInsets.all(5.0),
      child: SingleChildScrollView(
        child: new MarkdownBody(
          styleSheet: _getStyle(context),
          syntaxHighlighter: new GSYHighlighter(),
          data: markdownData,
          onTapLink: (String source) {
            CommonUtils.launchUrl(context, source);
          },
        ),
      ),
    );
  }
}

class GSYHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    return new TextSpan(
      text: source,
      style: GSYConstant.smallTextWhite,
    );
  }
}
