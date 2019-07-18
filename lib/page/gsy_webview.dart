import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

/**
 * webview版本
 * Created by guoshuyu
 * on 2018/7/27.
 */
class GSYWebView extends StatelessWidget {
  final String url;
  final String title;
  final OptionControl optionControl = new OptionControl();

  GSYWebView(this.url, this.title);

  _renderTitle() {
    if (url == null || url.length == 0) {
      return new Text(title);
    }
    optionControl.url = url;
    return new Row(children: [
      new Expanded(
          child: new Container(
        child: new Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )),
      GSYCommonOptionWidget(optionControl),
    ]);
  }

  final FocusNode focusNode = new FocusNode();

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
          WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              javascriptChannels: Set.from([
                JavascriptChannel(
                    name: 'Print',
                    onMessageReceived: (JavascriptMessage message) {
                      print("FFFFFF");
                      print(message.message);
                      FocusScope.of(context).requestFocus(focusNode);
                    })
              ]))
        ],
      ),
    );
  }
}

///测试 html 代码，不管
final testhtml = "<!DOCTYPE html>"
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
