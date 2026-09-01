class DataResult {
  Object? data;
  bool result;
  Function? next;

  /// 2026-09 加：把网络层拿到的 HTTP 状态码/[Code] 常量向上传递。
  ///
  /// 这样上层（例如登录 epic / reducer）就能区分：
  /// - `401` / `403`：token 无效或权限不够 → 提示 "Token 无效或已失效"
  /// - `-1` / `-2` / `-4`：网络错误/超时/连接被拒 → 提示 "网络异常"
  /// - 其它：兜底 "登录失败"
  ///
  /// 之前所有失败都塞成 `DataResult(null, false)`，上层拿不到语义，
  /// 只能给一个含糊的 "网络或 Token 有问题"，遇到 401 也误导用户去查网络。
  int? code;

  DataResult(this.data, this.result, {this.next, this.code});
}
