import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 文件代码详情
/// Created by guoshuyu
/// Date: 2018-07-24

class CodeDetailPageWeb extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String? path;

  final String? data;

  final String? title;

  final String? branch;

  final String? htmlUrl;

  final String? lang;

  const CodeDetailPageWeb(
      {super.key,
      this.title,
      this.userName,
      this.reposName,
      this.path,
      this.data,
      this.lang,
      this.branch,
      this.htmlUrl});

  @override
  _CodeDetailPageState createState() => _CodeDetailPageState();
}

class _CodeDetailPageState extends State<CodeDetailPageWeb> {
  bool isLand = false;

  late final WebViewController controller;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    super.initState();
  }

  Future<Uri?> _getData() async {
    if (widget.data != null) {
      return Uri.dataFromString(widget.data!,
          mimeType: 'text/html', encoding: Encoding.getByName("utf-8"));
    }
    var res = await ReposRepository.getReposFileDirRequest(
        widget.userName!, widget.reposName!,
        path: widget.path, branch: widget.branch, text: true, isHtml: true);
    if (res != null && res.result) {
      String data2 = HtmlUtils.resolveHtmlFile(res, widget.lang ?? "java");
      return Uri.dataFromString(data2,
          mimeType: 'text/html', encoding: Encoding.getByName("utf-8"));
    }
    return null;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GSYTitleBar(widget.title),
      ),
      body: FutureBuilder<Uri?>(
        future: _getData(),
        builder: (context, result) {
          if (result.data == null) {
            return Center(
              child: Container(
                width: 200.0,
                height: 200.0,
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SpinKitDoubleBounce(color: Theme.of(context).primaryColor),
                    Container(width: 10.0),
                    Text(context.l10n.loading_text,
                        style: GSYConstant.middleText),
                  ],
                ),
              ),
            );
          }
          controller.loadRequest(result.data!);
          return WebViewWidget(
            controller: controller,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
            isLand ? Icons.screen_lock_landscape : Icons.screen_lock_portrait),
        onPressed: () {
          setState(() {
            if (isLand) {
              isLand = !isLand;
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
              ]);
            } else {
              isLand = !isLand;
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
              ]);
            }
          });
        },
      ),
    );
  }
}
