import 'package:event_bus/event_bus.dart';
import 'package:gsy_github_app_flutter/common/event/HttpErrorEvent.dart';
///错误编码
class Code {
  ///网络错误
  static const NETWORK_ERROR = -1;

  ///网络超时
  static const NETWORK_TIMEOUT = -2;

  ///网络返回数据格式化一次
  static const NETWORK_JSON_EXCEPTION = -3;

  static const SUCCESS = 200;

  static final EventBus eventBus = new EventBus();

  static errorHandleFunction(code, message, noTip) {
    if(noTip) {
      return message;
    }
    eventBus.fire(new HttpErrorEvent(code, message));
    return message;
  }
}
