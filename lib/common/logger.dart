import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global logger instance with optimized settings
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: Config.DEBUG,
    useHistory: Config.DEBUG,
    maxHistoryItems: Config.DEBUG ? 100 : 10, // Reduce memory in production
    useConsoleLogs: Config.DEBUG,
  ),
);

/// Optimized logging function with better type checking
void printLog(Object msg) {
  // Only process logs in debug mode for performance
  if (!Config.DEBUG) return;

  switch (msg) {
    case Error():
      talker.error("Catch Running Error：", msg);
      break;
    case Exception():
      talker.error("Catch Running Exception：", msg);
      break;
    default:
      if (kDebugMode) {
        print(msg);
      }
  }
}
