import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';

/**
 * 代码详情
 * Created by guoshuyu
 * Date: 2018-07-24
 */
class GSYMarkdownWidget extends StatelessWidget {
  final String markdownData;

  GSYMarkdownWidget({this.markdownData = ""});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: SingleChildScrollView(
        child: new MarkdownBody(
          data: markdownData,
          onTapLink: (String source) {
            CommonUtils.launchUrl(context, source);
          },
        ),
      ),
    );
  }
}
