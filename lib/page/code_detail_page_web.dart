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
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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

  const new({
    super.key,
    this.title,
    this.userName,
    this.reposName,
    this.path,
    this.data,
    this.lang,
    this.branch,
    this.htmlUrl,
  });

  @override
  _CodeDetailPageState createState() => _CodeDetailPageState();
}

class _CodeDetailPageState extends State<CodeDetailPageWeb> {
  bool isLand = false;

  late _CodeDocument _document;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _replaceDocument();
  }

  @override
  void didUpdateWidget(covariant CodeDetailPageWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 2026-10-24 FPR-111: a document owns one fetch/load future. Orientation,
    // theme and title rebuilds must not restart it or reset WebView scroll.
    final sourceChanged =
        oldWidget.data != widget.data ||
        (widget.data == null &&
            (oldWidget.userName != widget.userName ||
                oldWidget.reposName != widget.reposName ||
                oldWidget.path != widget.path ||
                oldWidget.branch != widget.branch ||
                oldWidget.lang != widget.lang));
    if (sourceChanged) _replaceDocument();
  }

  void _replaceDocument() {
    // 2026-10-24 FPR-111 review: changing a delegate on the same native view
    // does not identify the navigation that emitted an error. A source owns
    // its controller/native WebView; ordinary rebuilds retain that same owner.
    final document = _CodeDocument();
    _document = document;
    _loadFuture = _loadDocument(document, widget);
  }

  bool _isCurrent(_CodeDocument document) =>
      mounted && identical(_document, document);

  Future<void> _loadDocument(
    _CodeDocument document,
    CodeDetailPageWeb input,
  ) async {
    final controller = document.controller;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (!_isCurrent(document)) return;
    final uri = await _getData(input);
    // A late repository result belongs to its original document, not a newer
    // source or a page that has already left the navigator.
    if (!_isCurrent(document)) return;
    document.expectedUri = uri;
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          // Track permitted in-document links too. App loadRequest is already
          // covered by expectedUri; Android need not emit this callback for it.
          if (_isCurrent(document) && request.isMainFrame) {
            final target = Uri.tryParse(request.url);
            if (request.url.isNotEmpty && target != null) {
              document.expectedUri = target;
              if (document.error != null) {
                setState(() => document.error = null);
              }
            }
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          // The plugin also reports subresource failures. A missing image must
          // not hide a successfully rendered code/release document.
          if (!_isCurrent(document) || error.isForMainFrame != true) {
            return;
          }
          // URL is supplemental native-event evidence, not the delegate's
          // captured generation. Unknown URLs still belong to this distinct
          // current native view (including content-process termination).
          final url = error.url;
          if (url != null &&
              url.isNotEmpty &&
              Uri.tryParse(url) != document.expectedUri) {
            return;
          }
          // Apple Foundation NSURLErrorCancelled: identify its real domain,
          // not an unqualified numeric code or localized description.
          if (error is WebKitWebResourceError &&
              error.domain == 'NSURLErrorDomain' &&
              error.errorCode == -999) {
            return;
          }
          setState(() => document.error = error);
        },
      ),
    );
    if (!_isCurrent(document)) return;
    await controller.loadRequest(uri);
  }

  Future<Uri> _getData(CodeDetailPageWeb input) async {
    if (input.data != null) {
      return Uri.dataFromString(
        input.data!,
        mimeType: 'text/html',
        encoding: Encoding.getByName("utf-8"),
      );
    }
    var res = await ReposRepository.getReposFileDirRequest(
      input.userName!,
      input.reposName!,
      path: input.path,
      branch: input.branch,
      text: true,
      isHtml: true,
    );
    if (res != null && res.result) {
      String data2 = HtmlUtils.resolveHtmlFile(res, input.lang ?? "java");
      return Uri.dataFromString(
        data2,
        mimeType: 'text/html',
        encoding: Encoding.getByName("utf-8"),
      );
    }
    // FPR-111: failed fetches are terminal results, not an endless loading UI.
    throw StateError('code_document_request_failed');
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: GSYTitleBar(widget.title)),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, result) {
          if (result.connectionState == ConnectionState.done &&
              result.hasError) {
            return Center(child: Text(context.l10n.network_error));
          }
          if (result.connectionState != ConnectionState.done &&
              _document.error == null) {
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
                    Flexible(
                      child: Text(
                        context.l10n.loading_text,
                        style: GSYConstant.middleText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // Keep the actual platform view mounted when reporting a native
          // failure. An error callback must not destroy the current document.
          return Stack(
            children: [
              WebViewWidget(
                key: ObjectKey(_document),
                controller: _document.controller,
              ),
              if (_document.error != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(child: Text(context.l10n.network_error)),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          isLand ? Icons.screen_lock_landscape : Icons.screen_lock_portrait,
        ),
        onPressed: () {
          setState(() {
            if (isLand) {
              isLand = !isLand;
              SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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

class _CodeDocument {
  final controller = WebViewController();
  Uri? expectedUri;
  WebResourceError? error;
}
