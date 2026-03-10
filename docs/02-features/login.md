# 登录功能

## 相关文件

- `lib/page/login/login_page.dart`
- `lib/page/login/login_webview.dart`
- `lib/redux/login_redux.dart`
- `lib/common/repositories/user_repository.dart`
- `lib/common/net/address.dart`

## 当前实现

登录页同时保留了账号密码入口和 OAuth 入口，但当前用户名密码登录已被直接禁用，页面会提示 `login_deprecated`。
实际可用主链路是 OAuth 登录。

## 数据流

OAuth 登录链路：

1. `LoginPage` 点击 OAuth 按钮
2. 通过 `Address.getOAuthUrl()` 生成授权地址
3. 跳转到 `login_webview.dart`
4. 登录成功后拿到 `code`
5. 分发 Redux `OAuthAction`
6. `oauthEpic` 调用 `UserRepository.oauth`
7. 登录成功后分发 `LoginSuccessAction`
8. reducer 内跳转首页

## 状态管理

- 页面输入和交互：页面本地 state
- 登录结果与全局用户态：Redux

## 高风险点

- 不要把 OAuth 成功后的全局登录逻辑搬回页面层
- `use_build_context_synchronously` 已在现有代码中被局部忽略，修改时要注意异步后导航安全
- `ignoreConfig.dart` 缺失会直接影响 OAuth 流程

## 修改建议

- 登录页 UI 小改动：尽量只动 `lib/page/login/`
- 登录协议改动：同步检查 `login_redux.dart`、`user_repository.dart`、OAuth 地址构造
- 不要在无关任务中恢复账号密码登录链路，除非需求明确要求
