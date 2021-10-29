import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/app.dart';
import 'package:gsy_github_app_flutter/env/config_wrapper.dart';
import 'package:gsy_github_app_flutter/env/env_config.dart';
import 'package:gsy_github_app_flutter/page/error_page.dart';

import 'env/dev.dart';

void main() {
  ///屏幕刷新率和显示率不一致时的优化
  GestureBinding.instance?.resamplingEnabled = true;
  runZonedGuarded(() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      Zone.current.handleUncaughtError(details.exception, details.stack!);
      ///此处仅为展示，正规的实现方式参考 _defaultErrorWidgetBuilder 通过自定义 RenderErrorBox 实现
      return ErrorPage(
          details.exception.toString() + "\n " + details.stack.toString(), details);
    };
    runApp(ConfigWrapper(
      child: Flutter(),
      config: EnvConfig.fromJson(config),
    ));
  }, (Object obj, StackTrace stack) {
    print();
    print(exit);
  });
}
