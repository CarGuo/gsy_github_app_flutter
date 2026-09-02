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

/// 结构化异常上报入口：让 catch 侧不再拼 `'msg: $e'` 字符串，
/// exception 走 talker 的 typed 分支，方便 sink 端按类型聚合。
///
/// 用法：`catch (e, s) { printError('login epic 网络失败', e, s); }`
///
/// 对比 `printLog('login epic 网络失败: $e', s)` 的优势：
/// - talker.error 拿到 typed [error] 参数，`SocketException` / `MissingPluginException`
///   / `TypeError` 可按类型自动分组，运维排查时不用靠字符串搜索
/// - 上下文 [context] 是给人看的场景描述，跟 [error] 分开传，日志聚合不糊
///
/// 兼容既有 [printLog]：非 catch 场景仍用 `printLog(msg)` / `printLog(msg, stack)`。
printError(String context, Object error, [StackTrace? stackTrace]) {
  talker.error(context, error, stackTrace);
  if (kDebugMode) {
    print('$context: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}
