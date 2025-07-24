import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
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

  // Constants for better performance
  static const double _imageSize = 90.0;
  static const double _spacingLarge = 40.0;
  static const double _spacingMedium = 11.0;
  static const double _spacingSmall = 40.0;
  static const String _errorText = "Error Occur";
  static const String _reportText = "Report";
  static const String _backText = "Back";

  void addError(FlutterErrorDetails details) {
    try {
      final map = <String, dynamic>{'error': details.toString()};
      LogsInterceptors.addLogic(
          sErrorName, details.exception.runtimeType.toString());
      LogsInterceptors.addLogic(sErrorStack, map);
    } catch (e) {
      printLog(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQueryData.fromView(View.of(context));
    final double width = mediaQuery.size.width;
    
    return Container(
      color: GSYColors.primaryValue,
      child: Center(
        child: Container(
          alignment: Alignment.center,
          width: width,
          height: width,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            gradient: RadialGradient(
              tileMode: TileMode.mirror, 
              radius: 0.1, 
              colors: [
                Colors.white.withAlpha(10),
                GSYColors.primaryValue.withAlpha(100),
              ],
            ),
            borderRadius: BorderRadius.circular(width / 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Image(
                image: AssetImage(GSYICons.DEFAULT_USER_ICON),
                width: _imageSize,
                height: _imageSize,
              ),
              const SizedBox(height: _spacingMedium),
              const Material(
                color: GSYColors.primaryValue,
                child: Text(
                  _errorText,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(height: _spacingLarge),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildButton(
                    text: _reportText,
                    onPressed: _handleReportError,
                  ),
                  const SizedBox(width: _spacingSmall),
                  _buildButton(
                    text: _backText,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: GSYColors.white.withAlpha(100),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  void _handleReportError() {
    String content = widget.errorMessage;
    textEditingController.text = content;
    CommonUtils.showEditDialog(
      context, 
      context.l10n.home_reply, 
      (title) {}, 
      (res) => content = res,
      () {
        if (content.isEmpty) return;
        
        CommonUtils.showLoadingDialog(context);
        IssueRepository.createIssueRequest(
          "CarGuo", 
          "gsy_github_app_flutter", 
          {
            "title": context.l10n.home_reply,
            "body": content
          },
        ).then((result) {
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      titleController: TextEditingController(),
      valueController: textEditingController,
      needTitle: false,
    );
  }
}
