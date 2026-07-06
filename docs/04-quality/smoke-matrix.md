# 手工回归矩阵

## 目的

仓库当前缺少自动化测试基线，因此需要一份最小可执行的手工回归矩阵。
它的目标不是覆盖全部功能，而是覆盖最容易因局部改动而回归的主链路。

## 使用方式

- 改动前：确认本次变更影响哪些功能域
- 改动后：至少执行对应功能域的基础用例
- 改共享层时：除目标功能外，额外抽查一个高频功能

## 全局基础项

每次涉及共享层或根装配时，至少验证：

1. 应用能正常启动
2. 首页或欢迎页能进入
3. 路由跳转正常
4. 多语言和主题没有明显异常

## 登录

适用改动：

- `lib/page/login/`
- `lib/redux/login_redux.dart`
- `user_repository`
- OAuth 配置或导航相关改动

基础用例：

1. 进入登录页
2. 点击 OAuth 登录按钮
3. 能正常打开登录 WebView
4. 登录完成后能回到应用并进入首页
5. 退出登录后能回到登录页

重点观察：

- WebView 跳转是否正常
- OAuth 回调后是否正确更新全局登录态

## 仓库详情

适用改动：

- `lib/page/repos/`
- `repos_repository`
- `issue_repository`
- 相关模型、网络层改动

基础用例：

1. 从列表页进入仓库详情
2. 信息页正常展示
3. Readme 页能加载
4. Issue 页能切换并加载
5. 文件列表页能切换并加载
6. 切换分支后，信息页、Readme、文件列表表现正常

重点观察：

- 跨 tab 状态是否同步
- 分支切换是否触发联动刷新

## 趋势页

适用改动：

- `lib/page/trend/`
- `ReposRepository.getTrendRequest`
- 趋势筛选、滚动、刷新相关改动

基础用例：

1. 进入趋势页
2. 首次加载能显示列表或空态
3. 切换时间筛选
4. 切换语言筛选
5. 下拉刷新
6. 点击列表项进入仓库详情并返回

重点观察：

- 首次加载与刷新是否重复触发
- 筛选切换后列表是否正确刷新

## 通知页

适用改动：

- `lib/page/notify/`
- `user_repository` 通知相关接口
- Signals 或分页刷新逻辑相关改动

基础用例：

1. 进入通知页
2. 默认列表正常加载
3. 在 未读 / 参与 / 全部 之间切换
4. 下拉刷新
5. 上拉加载更多
6. 将单条未读标记为已读
7. 执行“全部标记为已读”
8. 点击 Issue 类型通知跳转详情并返回

重点观察：

- 切 tab 时列表是否正确刷新
- 标记已读后列表是否正确更新
- 返回后是否触发强制刷新

## 共享网络层

适用改动：

- `lib/common/net/`
- `lib/common/repositories/`
- 认证、拦截器、公共响应解析

基础用例：

1. 验证登录链路
2. 验证趋势页加载
3. 验证仓库详情加载
4. 验证通知页加载

重点观察：

- 是否出现全局 toast 异常
- 是否出现统一鉴权失效
- REST 与 GraphQL 路径是否都正常

## 共享状态或根装配

适用改动：

- `lib/app.dart`
- `lib/provider/`
- `lib/redux/`

基础用例：

1. 应用启动正常
2. 首页进入正常
3. 登录态切换正常
4. 主题或语言切换正常
5. 趋势页、通知页、仓库详情页各抽查一个

## 执行原则

- 不要求每次全量回归
- 但改共享链路时，不能只测当前页面
- 如果某次改动跨越多个功能域，应把对应模块基础用例全部跑一遍

## 首页动态 / 事件识别

适用改动：

- `lib/common/utils/event_utils.dart`（事件 switch、`_translateAction`、UnknownEvent 兜底）
- `lib/page/dynamic/`
- `lib/widget/gsy_event_item.dart`
- 事件相关多语言 arb key（`event_dynamic_*`、`event_action_*`）

基础用例（真机走一遍首页动态 tab，滚到当前登录用户 received feed 前 40 条）：

1. 应用启动 → 落在动态 tab
2. 下拉刷新，列表最新一条时间戳能变成刚才的 push
3. 上拉加载更多，能拉到第 2 页数据（时间跨度到 1-2 天前）
4. 至少能同时看到以下事件族在真机上正确渲染：
   - `PushEvent`：带 head SHA short
   - `IssuesEvent` opened：`在 {repo} 打开 issue #{n}` + issue title 摘要
   - `ForkEvent`：`将 {src} fork 到 {dst}`
   - `WatchEvent` started：`关注了 {repo}`
   - `CreateEvent`：`创建了仓库 {repo}` 或类似
5. 触摸任何一条卡片能进对应详情页并返回，不抛异常

重点观察：

- **UnknownEvent 兜底**：不应出现完全空白的卡片（仅头像 + 时间戳、没有任何文字）
- **actionDes 富文本**：Issue 标题、PR 标题、Push commit message 不要出现原始 markdown 符号或 `<br>` 等 HTML 尾巴
- **`_translateAction` 冷 action**：如果 feed 里出现 `auto_merge_enabled` / `dequeued` / `enqueued` 等新词条，应显示英文原文（当前还未收编到词典），可以据此判断哪些 action 值得优先补入

已知稀有事件真机命中说明：

- `DiscussionEvent` / `DiscussionCommentEvent` / `SponsorshipEvent` / `PullRequestReviewThreadEvent`
  这四类事件在多数账号的 `/users/{u}/received_events` feed 里出现频率极低（fixture 账号
  CarSmallGuo 拉最近 5 页 299 条只出现 1 条 DiscussionEvent，且被 GSY 首页分页策略
  跳过，见后文"分页可疑丢事件"条目）。
  这些事件的识别正确性由以下两条证据链保证，**不强求真机截图**：
  - `test/utils/event_utils_test.dart` 已覆盖 15 case（含全部四类），
    对 `getActionAndDes` 的 switch 分支做等价类抽样
  - 真机上其他 `getActionAndDes` switch 分支下的事件（`IssuesEvent` /
    `ForkEvent` / `WatchEvent` / `PushEvent`）已在同一屏正确渲染，
    截图见 [tool/dbg/b_10_back_to_hfye.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/b_10_back_to_hfye.png)
    与 [tool/dbg/b_13_load_more.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/b_13_load_more.png)

复用脚本：[tool/ai/smoke/open_home_dynamic.sh](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.sh)
（重启 app → 停在首页动态 tab → 下拉刷新 → 上拉加载 → 慢速下滑抓 5 张证据截图）。

