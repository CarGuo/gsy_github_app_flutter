import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/net/interceptors/log_interceptor.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';

class ErrorPage extends StatefulWidget {
  final String errorMessage;
  final FlutterErrorDetails details;

  const ErrorPage(this.errorMessage, this.details, {super.key});

  @override
  ErrorPageState createState() => ErrorPageState();
}

class ErrorPageState extends State<ErrorPage> {
  static List<Map<String, dynamic>?> sErrorStack = [];
  static List<String?> sErrorName = [];

  final TextEditingController textEditingController = TextEditingController();

  addError(FlutterErrorDetails details) {
    try {
      var map = <String, dynamic>{};
      map["error"] = details.toString();
      LogsInterceptors.addLogic(
          sErrorName, details.exception.runtimeType.toString());
      LogsInterceptors.addLogic(sErrorStack, map);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQueryData.fromView(View.of(context)).size.width;
    return Container(
      color: GSYColors.primaryValue,
      child: Center(
        child: Container(
          alignment: Alignment.center,
          width: width,
          height: width,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            gradient:
                RadialGradient(tileMode: TileMode.mirror, radius: 0.1, colors: [
              Colors.white.withAlpha(10),
              GSYColors.primaryValue.withAlpha(100),
            ]),
            borderRadius: BorderRadius.all(Radius.circular(width / 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Image(
                  image: AssetImage(GSYICons.DEFAULT_USER_ICON),
                  width: 90.0,
                  height: 90.0),
              const SizedBox(
                height: 11,
              ),
              const Material(
                color: GSYColors.primaryValue,
                child: Text(
                  "Error Occur",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: GSYColors.white.withAlpha(100),
                    ),
                    onPressed: () {
                      String content = widget.errorMessage;
                      textEditingController.text = content;
                      CommonUtils.showEditDialog(
                          context, context.l10n.home_reply, (title) {}, (res) {
                        content = res;
                      }, () {
                        if (content.isEmpty) {
                          return;
                        }
                        CommonUtils.showLoadingDialog(context);
                        IssueRepository.createIssueRequest(
                            "CarGuo", "gsy_github_app_flutter", {
                          "title": context.l10n.home_reply,
                          "body": content
                        }).then((result) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                      },
                          titleController: TextEditingController(),
                          valueController: textEditingController,
                          needTitle: false);
                    },
                    child: const Text("Report"),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                  TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(100)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Back")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
