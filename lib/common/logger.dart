import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    /// You can enable/disable all talker processes with this field
    enabled: true,

    /// You can enable/disable saving logs data in history
    useHistory: true,

    /// Length of history that saving logs data
    maxHistoryItems: 100,

    /// You can enable/disable console logs
    useConsoleLogs: true,
  ),
);

printLog(Object msg, [StackTrace? stackTrace]) {
  if (msg is Error) {
    talker.error("Catch Running Error：", msg, stackTrace ?? msg.stackTrace);
  } else if (msg is Exception) {
    talker.error("Catch Running Exception：", msg, stackTrace);
  } else if (msg is StackTrace) {
    talker.error("Catch Running Stack：", null, msg);
  } else if (stackTrace != null) {
    talker.error(msg, null, stackTrace);
  }
  if (kDebugMode) {
    print(msg);
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}
