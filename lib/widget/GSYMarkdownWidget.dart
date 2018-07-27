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
  final String markdownData;

  final int style;

  GSYMarkdownWidget({this.markdownData = "", this.style = 0});

  _getCommonSheet(BuildContext context) {
    MarkdownStyleSheet markdownStyleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return markdownStyleSheet
        .copyWith(
            codeblockDecoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: Color(GSYColors.primaryValue),
                border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)))
        .copyWith(
            blockquoteDecoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: Color(GSYColors.subTextColor),
                border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)),
            blockquote: GSYConstant.smallTextWhite);
  }

  _getStyleSheetDark(BuildContext context) {
    return _getCommonSheet(context).copyWith(
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
    return _getCommonSheet(context).copyWith(
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: style == 0 ? Color(GSYColors.white) : Color(GSYColors.primaryLightValue),
      padding: EdgeInsets.all(5.0),
      child: SingleChildScrollView(
        child: new MarkdownBody(
          styleSheet: style == 0 ? _getStyleSheetWhite(context) : _getStyleSheetDark(context),
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
