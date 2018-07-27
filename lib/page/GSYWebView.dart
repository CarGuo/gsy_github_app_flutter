import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

/**
 * webview版本
 * Created by guoshuyu
 * on 2018/7/27.
 */
class GSYWebView extends StatelessWidget {
  final String url;
  final String title;

  GSYWebView(this.url, this.title);

  @override
  Widget build(BuildContext context) {
    return new WebviewScaffold(
      withJavascript: true,
      url: url,
      withLocalUrl: true,
      appBar: new AppBar(
        title: new Text(title),
      ),
    );
  }
}
