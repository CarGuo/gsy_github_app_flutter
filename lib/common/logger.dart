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

printLog(Object msg) {
  if (msg is Error) {
    talker.error("Catch Running Error：", msg);
  } else if (msg is Exception) {
    talker.error("Catch Running Exception：", msg);
  }
  if (kDebugMode) {
    print(msg);
  }
}
