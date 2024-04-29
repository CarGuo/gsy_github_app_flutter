import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// webview版本
/// Created by guoshuyu
/// on 2018/7/27.

class GSYWebView extends StatefulWidget {
  final String url;
  final String? title;

  const GSYWebView(this.url, this.title, {super.key});

  @override
  _GSYWebViewState createState() => _GSYWebViewState();
}

class _GSYWebViewState extends State<GSYWebView> {
  _renderTitle() {
    if (widget.url.isEmpty) {
      return Text(widget.title!);
    }
    return Row(children: [
      Expanded(
          child: Text(
            widget.title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
      GSYCommonOptionWidget(url: widget.url),
    ]);
  }

  final FocusNode focusNode = FocusNode();

  bool isLoading = true;

  late final WebViewController controller;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..addJavaScriptChannel("name", onMessageReceived: (message) {
        if (kDebugMode) {
          print(message.message);
        }
        FocusScope.of(context).requestFocus(focusNode);
      })
      ..loadRequest(Uri.parse(widget.url));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      appBar: AppBar(
        title: _renderTitle(),
      ),
      body: Stack(
        children: <Widget>[
          TextField(
            focusNode: focusNode,
          ),
          WebViewWidget(
            controller: controller,
          ),
          if (isLoading)
            Center(
              child: Container(
                width: 200.0,
                height: 200.0,
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SpinKitDoubleBounce(
                        color: Theme.of(context).primaryColor),
                    Container(width: 10.0),
                    Text(
                        GSYLocalizations.i18n(context)!.loading_text,
                        style: GSYConstant.middleText),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}

///测试 html 代码，不管
const testhtml = "<!DOCTYPE html>"
    "<html>"
    "<head>"
    "<meta charset=\"utf-8\">"
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1,user-scalable=no\" />"
    "<title>Local Title</title>"
    "<script>"
    "function callJS(){"
    "alert(\"Android调用了web js\");"
    "}"
    "function callInterface(){"
    "JSCallBackInterface.callback(\"我是web的js哟\");"
    "}"
    "function callInterface2(){"
    "document.location = \"js://Authority?pra1=111&pra2=222\";"
    "}"
    "function clickPrompt(){"
    "Print.postMessage('Hello');"
    "}"
    "</script>"
    "</head>"
    "<body>"
    "<button type=\"button\" id=\"buttonxx\" onclick=\"callInterface()\">点我调用原生android方法</button>"
    "<button type=\"button\" id=\"buttonxx2\" onclick=\"callInterface2()\">点我调用原生android方法2</button>"
    "<button type=\"button\" id=\"buttonxx3\" onclick=\"clickPrompt()\">点我调用原生android方法3</button>"
    "<input></input>"
    "</body>"
    "</html>";
