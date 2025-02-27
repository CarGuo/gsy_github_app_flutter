import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/log_interceptor.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/page/error_page.dart';
import 'package:gsy_github_app_flutter/test/demo_tab_page.dart';
import 'package:gsy_github_app_flutter/widget/flutter_json_widget.dart';


///请求数据调
class DebugDataPage extends StatefulWidget {
  const DebugDataPage({super.key});

  @override
  _DebugDataPageState createState() => _DebugDataPageState();
}

class _DebugDataPageState extends State<DebugDataPage> {
  int tabIndex = 0;

  /// tab
  _renderTab(String text, index) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[Text(text, style: const TextStyle(fontSize: 11))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabWidget(
        type: TabType.top,

        /// 返回数据和请求数据
        tabItems: [
          _renderTab("Responses", 0),
          _renderTab("Request", 1),
          _renderTab("Error", 2),
          _renderTab("ErrorWidget", 3),
        ],
        title: const Text(
          "Debug",
          style: TextStyle(color: GSYColors.white),
        ),
        tabViews: [
          DebugDataList(LogsInterceptors.sResponsesHttpUrl,
              LogsInterceptors.sHttpResponses),
          DebugDataList(
              LogsInterceptors.sRequestHttpUrl, LogsInterceptors.sHttpRequest),
          DebugDataList(
              LogsInterceptors.sHttpErrorUrl, LogsInterceptors.sHttpError),
          DebugDataList(ErrorPageState.sErrorName, ErrorPageState.sErrorStack),
        ],
        indicatorColor: GSYColors.primaryValue,
        onTap: (index) {
          setState(() {
            tabIndex = index;
          });
        });
  }
}

class DebugDataList extends StatefulWidget {
  final List<Map?> dataList;

  final List<String?> titles;

  const DebugDataList(this.titles, this.dataList, {super.key});

  @override
  _DebugDataListState createState() => _DebugDataListState();
}

class _DebugDataListState extends State<DebugDataList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: GSYColors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, i) {
          var index = widget.dataList.length - i - 1;
          return InkWell(
            child: Card(
              child: Row(
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 5),
                    height: 24,
                    width: 24,
                    decoration: const BoxDecoration(
                      color: GSYColors.primaryValue,
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      index.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text(
                      widget.titles[index] ?? "",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ))
                ],
              ),
            ),
            onLongPress: () {
              try {
                Clipboard.setData(
                    ClipboardData(text: "${widget.titles[index]}"));
                Fluttertoast.showToast(msg: "复制链接成功");
              } catch (e) {
                if (kDebugMode) {
                  print(e);
                }
              }
            },
            onDoubleTap: () {
              try {
                Clipboard.setData(
                    ClipboardData(text: "${widget.dataList[index]}"));
                Fluttertoast.showToast(msg: "复制数据成功");
              } catch (e) {
                if (kDebugMode) {
                  print(e);
                }
              }
            },
            onTap: () {
              showBottomSheet(
                  context: context,
                  builder: (context) {
                    return Material(
                      color: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(top: 30),
                            color: Colors.white,
                            child: SingleChildScrollView(
                                child:
                                    JsonViewerWidget(widget.dataList[index] as Map<String, dynamic>)),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: Container(
                              alignment: Alignment.topCenter,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 30,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  });
            },
          );
        },
        itemCount: widget.titles.length,
      ),
    );
  }
}
