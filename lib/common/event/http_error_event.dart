/// Created by guoshuyu
/// Date: 2018-08-16
///
/// 2026-09 修：`message` 从 non-null String 改成 `String?`。
/// 触发原因：Dio 5+ 之后，`DioException.message` 声明为可空 String?，
/// 例如底层是 `SocketException` / `HandshakeException` / 未知平台通道错误时，
/// dio 不会硬造一个 message。之前 [Code.errorHandleFunction] 直接把
/// `e.message` 传进 [HttpErrorEvent] 构造函数，null 会撞到 non-null 校验，
/// 抛 `type 'Null' is not a subtype of type 'String'`，**让错误处理自己炸掉**，
/// 结果 UI 层看到的就是 "登录一直转 / 无响应"。修完 message 允许为 null，
/// 消费方按 null 安全兜底文案即可。
library;

class HttpErrorEvent {
  final int? code;

  final String? message;

  new(this.code, this.message);
}
