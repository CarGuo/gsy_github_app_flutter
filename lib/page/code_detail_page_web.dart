import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  CodeDetailPageWeb(
      {this.title,
      this.userName,
      this.reposName,
      this.path,
      this.data,
      this.branch,
      this.htmlUrl});

  @override
  _CodeDetailPageState createState() => _CodeDetailPageState();
}

class _CodeDetailPageState extends State<CodeDetailPageWeb> {
  Future<String> _getData() async {
    if (widget.data != null) {
      return widget.data;
    }
    var res = await ReposDao.getReposFileDirDao(
        widget.userName, widget.reposName,
        path: widget.path, branch: widget.branch, text: true, isHtml: true);
    if (res != null && res.result) {
      String data2 = HtmlUtils.resolveHtmlFile(res, "java");
      String url = new Uri.dataFromString(data2,
              mimeType: 'text/html', encoding: Encoding.getByName("utf-8"))
          .toString();
      return url;
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: GSYTitleBar(widget.title),
        ),
        body: FutureBuilder<String>(
          initialData: widget.data,
          future: _getData(),
          builder: (context, result) {
            if (result.data == null || result.data.isEmpty) {
              return new Center(
                child: new Container(
                  width: 200.0,
                  height: 200.0,
                  padding: new EdgeInsets.all(4.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new SpinKitDoubleBounce(
                          color: Theme.of(context).primaryColor),
                      new Container(width: 10.0),
                      new Container(
                          child: new Text(
                              GSYLocalizations.i18n(context).loading_text,
                              style: GSYConstant.middleText)),
                    ],
                  ),
                ),
              );
            }
            return WebView(
              initialUrl: result.data,
              javascriptMode: JavascriptMode.unrestricted,
            );
          },
        ));
  }
}
