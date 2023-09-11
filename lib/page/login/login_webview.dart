import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';

// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class LoginWebView extends StatefulWidget {
  final String url;
  final String title;

  LoginWebView(this.url, this.title);

  @override
  _LoginWebViewState createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
  late final WebViewController controller;

  late final PlatformWebViewControllerCreationParams params;

  @override
  void initState() {
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    controller = WebViewController.fromPlatformCreationParams(params);
    if (controller.platform is AndroidWebViewController) {
      //AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(true);
    }
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
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
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("gsygithubapp://authed")) {
              var code = Uri.parse(request.url).queryParameters["code"];
              print("code ${code}");
              Navigator.of(context).pop(code);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
        widget.url,
      ));

    super.initState();
  }

  _renderTitle() {
    if (widget.url.length == 0) {
      return new Text(widget.title);
    }
    return new Row(children: [
      new Expanded(
          child: new Container(
        child: new Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )),
      GSYCommonOptionWidget(url: widget.url),
    ]);
  }

  final FocusNode focusNode = new FocusNode();

  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: _renderTitle(),
      ),
      body: new Stack(
        children: <Widget>[
          TextField(
            focusNode: focusNode,
          ),
          WebViewWidget(
            controller: controller,
          ),
          if (isLoading)
            new Center(
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
                            GSYLocalizations.i18n(context)!.loading_text,
                            style: GSYConstant.middleText)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
