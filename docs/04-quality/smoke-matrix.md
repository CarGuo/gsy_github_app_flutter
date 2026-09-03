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

复用路径描述：[tool/ai/smoke/open_home_dynamic.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.md)
（2026-09-02 起 adb 坐标 `.sh` 全部废弃，改为 `mcp_dart widget_inspector` +
`get_runtime_errors` + 平台原生截图工具）。

## 大屏 / 横屏 / 折叠屏自适应导航

适用改动：

- [lib/common/style/gsy_responsive.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart)（断点 / hinge / narrowHeight）
- [lib/common/style/gsy_adaptive_shell.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)（`GSYAdaptiveDestination` / `GSYAdaptiveNavigationDelegate` / `GSYAdaptiveNavigation` 单例）
- [lib/widget/gsy_tabbar_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart)（compact 走 `GSYTab.TabBar` / medium+expanded 走 Rail 的双骨架实际使用方）
- [lib/page/home/home_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart)（`tabItems` + `railDestinations` 双声明）
- 任何改到主 tab 结构、断点阈值、Rail 视觉的 PR

基础用例（真机 Pixel 系或 720dp+ 折叠展开态）：

1. 竖屏启动 → 首页展示底部导航条（compact 断点，实际渲染器是自定义 [GSYTab.TabBar](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabs.dart)，不是 Material `BottomNavigationBar`）
2. 旋转到横屏 / resize 到 ≥600dp → 首页左侧出现 `NavigationRail`，PageView 内容随选中 rail 项切换
3. Rail 上依次选中 3 个 destination，PageView 页面正确刷新（动态 / 趋势 / 我的）
4. 从横屏旋回竖屏 → Rail 消失，`GSYTab.TabBar` 复位，当前选中态保留
5. 极窄横屏（如 Pixel 5 landscape 360×720）Rail 图标不溢出，可垂直滚动
6. 抽象层单测：`flutter test test/common/style/gsy_adaptive_shell_test.dart` 与 `flutter test test/common/style/gsy_responsive_test.dart` 全绿

已归档证据：

- [tool/dbg/adaptive_p0_rotate/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p0_rotate)：P0 阶段旋转不错位截图（[01_portrait_home.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p0_rotate/01_portrait_home.png) → [04_landscape_repo.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p0_rotate/04_landscape_repo.png)）
- [tool/dbg/adaptive_p1_rail/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_rail)：P1 首版 Rail 落地证据（竖屏 / 横屏动态 / 横屏趋势 / 横屏我的 / 回竖屏共 5 张）
- [tool/dbg/adaptive_p1_iso/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_iso)：**P1 抽象隔离改造后**回归截图，用于确认引入 delegate 后 Rail/Tab 行为与 `adaptive_p1_rail` 一致（[01_portrait_tabs.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_iso/01_portrait_tabs.png) 竖屏 Tab / [02_landscape_rail.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_iso/02_landscape_rail.png) 横屏 Rail 首屏 / [03_landscape_rail_trend.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_iso/03_landscape_rail_trend.png) 切趋势 / [04_landscape_rail_my.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_iso/04_landscape_rail_my.png) 切我的）

已知缺口（下轮改动前请先扫）：

- **MyPage 顶部 5 列 stats 横屏溢出**：在 720dp 横屏下 MyPage 顶部 followers/following/... 5 列会撑出右边界。当前 P1 为了不阻塞抽象隔离，把 tabView 全局宽度限制回退了，MyPage 卡片自身的分栏推迟到 P2 单独治理。回归时如果 `04_landscape_rail_my.png` 右侧仍有溢出，属于**已知缺口**，不算 P1 回归失败。
- **≥840dp 平板 / Chromebook 真机**：目前只在 emulator resize 到 1200×800 走过，没有实机；下轮 P2 前需要在实体平板上再跑一遍。
- **rail 高亮对比度**：部分主题色（尤其 dark theme + 深色主色）下 rail selected 与 unselected 视觉可辨识度偏弱，需要美术侧介入前不做代码改动。

修改抽象层时的强制流程：

1. 先改 [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart)（契约测试），再改实现
2. 每次装机走 `adb install -r`，**禁止** `flutter install`（会清 `TOKEN_KEY`）
3. 截图必须放到 `tool/dbg/adaptive_*/` 或 `tool/dbg/<feature>_<date>/`，**绝对路径**写进完成汇报
4. 关联决策记录：[ADR-0005 大屏 / 横屏 / 折叠屏自适应导航抽象](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)
5. 关联路线图：[roadmap §四点五](file:///d:/workspace/project/gsy_github_app_flutter/docs/00-overview/roadmap.md)

