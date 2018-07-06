
///错误编码
class Code {
  //网络错误
  static const NETWORK_ERROR = 1;
//网络超时
  static const NETWORK_TIMEOUT = 2;
//网络返回数据格式化一次
  static const NETWORK_JSON_EXCEPTION = 3;

  static const SUCCESS = 200;

  static errorHandleFunction(code) {
    /*switch (code) {
      case 401:
      //授权逻辑
        if (Actions.currentScene !== 'LoginPage') {
          Actions.reset("LoginPage");
        }
        return "未授权或授权失败"; //401 Unauthorized
      case 403:
        Toast(I18n('noPower'));
        return "403权限错误";
      case 404:
      //Toast(I18n('notFound'));
        return "404错误";
      case 410:
        Toast(I18n('gone410'));
        return "410错误";
      case NETWORK_TIMEOUT:
      //超时
        Toast(I18n('netTimeout'));
        return I18n('netTimeout');
      default:
        if (statusText) {
          Toast(statusText);
        } else {
          Toast(I18n('errorUnKnow'));
        }
        return "其他异常"
    }*/
  }
}


