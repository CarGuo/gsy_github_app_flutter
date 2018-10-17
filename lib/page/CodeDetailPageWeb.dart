import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/HtmlUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/widget/webview/WebView.dart';

/**
 * 文件代码详情
 * Created by guoshuyu
 * Date: 2018-07-24
 */

class CodeDetailPageWeb extends StatefulWidget {
  final String userName;

  final String reposName;

  final String path;

  final String data;

  final String title;

  final String branch;

  final String htmlUrl;

  CodeDetailPageWeb({this.title, this.userName, this.reposName, this.path, this.data, this.branch, this.htmlUrl});

  @override
  _CodeDetailPageState createState() => _CodeDetailPageState(this.title, this.userName, this.reposName, this.path, this.data, this.branch, this.htmlUrl);
}

class _CodeDetailPageState extends State<CodeDetailPageWeb> {
  final String userName;

  final String reposName;

  final String path;

  final String branch;

  final String htmlUrl;

  String data ;

  final String title;

  _CodeDetailPageState(this.title, this.userName, this.reposName, this.path, this.data, this.branch, this.htmlUrl);

  @override
  void initState() {
    super.initState();
    if (data == null) {
      ReposDao.getReposFileDirDao(userName, reposName, path: path, branch: branch, text: true, isHtml: true).then((res) {
        if (res != null && res.result) {
          String data2 = HtmlUtils.resolveHtmlFile(res, "java");
          String url = new Uri.dataFromString(data2, mimeType: 'text/html', encoding: Encoding.getByName("utf-8")).toString();
          setState(() {
            this.data = url;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return new Scaffold(
        appBar: new AppBar(
          title: GSYTitleBar(
              title
          ),
        ),
        body: new Center(
          child: new Container(
            width: 200.0,
            height: 200.0,
            padding: new EdgeInsets.all(4.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new SpinKitDoubleBounce(color: Theme
                    .of(context)
                    .primaryColor),
                new Container(width: 10.0),
                new Container(child: new Text(CommonUtils
                    .getLocale(context)
                    .loading_text, style: GSYConstant.middleText)),
              ],
            ),
          ),
        ),
      );
    }

    if (Config.USE_NATIVE_WEBVIEW) {
      return Scaffold(
        appBar: AppBar(
          title: new Text(title),
        ),
        body: WebView(
          initialUrl: data,
          javaScriptMode: JavaScriptMode.unrestricted,
        ),
      );
    }

    return new WebviewScaffold(
      withJavascript: true,
      url: data,
      scrollBar:false,
      withLocalUrl: true,
      appBar: new AppBar(
        title: new Text(title),
      ),
    );

  }
}
