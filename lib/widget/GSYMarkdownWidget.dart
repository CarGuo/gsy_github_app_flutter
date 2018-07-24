import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
        child: SingleChildScrollView(
      child: new MarkdownBody(data: markdownData),
    ));
  }
}
