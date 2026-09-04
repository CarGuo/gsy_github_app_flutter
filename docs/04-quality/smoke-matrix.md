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

## 2026-09-03 P0-1 / P0-2 冒烟证据（reviewer 2026-09-03）

**背景**：reviewer 2026-09-03 从昨日至今 M2 双栏 shell（`gsy_adaptive_shell.dart` + `gsy_tabbar_widget.dart`）
差量里挑出两个 P0：

- **P0-1**：M2 关键路径缺**真机冒烟证据**——只跑了 `flutter analyze` + `flutter test`，没有配套截图 / runtime errors dump
- **P0-2**：[openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L307-L358) 在 `canShowTwoPane=true` 但 `detailNavigatorKey.currentState==null` 时静默走
  `Navigator.of(context).push`，会把 detail 挂到根 Navigator 覆盖 master 列（违反 P2 §2 契约）

### P0-2 修复：[openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L307-L358) 覆盖 master 列的自打脸路径

策略（**责任上移**）：

- delegate 层在此分支立刻返回 `Future<T?>.value(null)`，绝不走根 Navigator——避免自打脸；
- debug 用
  `assert(() { FlutterError.reportError(...); return true; }())`
  惯用法记账，把新引入这条路径的 caller 立刻在开发期暴露；release AOT 直接去掉整个 assert 表达式；
- caller（deep-link / [initUserInfo](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/common_utils.dart)）需要在
  `WidgetsBinding.instance.addPostFrameCallback` 里等 shell 装配完再调 openDetail；
- 曾经在 delegate 内挂 `_retryPushOnNextFrame` 做一次帧后重试，实测在
  `flutter_test` 空闲期 postFrame 排不上帧（没人 mark dirty），completer 挂死；
  改为"责任上移"后逻辑退化到零副作用，单测跑得干净。

**契约测试**（新增 3 case）见
[gsy_adaptive_shell_test.dart §Master-Detail 契约（P2 §2）](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart#L654-L849)：

1. `openDetail：canShowTwoPane=true 但 detailNavigator 未挂载 → debug 通过 FlutterError.reportError 记账`
2. `openDetail：caller 用 addPostFrameCallback 延后重试 → push 命中 detailKey 子树`
3. `openDetail：canShowTwoPane=true 但 detailNavigator 缺席 → push 丢弃 + 记账，不覆盖 master`

**编译验证**：

- `fvm flutter analyze lib\common\style\gsy_adaptive_shell.dart test\common\style\gsy_adaptive_shell_test.dart` → `No issues found`
- `fvm flutter test`（全量 353 case）→ `All tests passed!`

### P0-1 真机冒烟证据（Android compact）

**设备**：`M2104K10AC / jfxgpjeul7lrpjkz`（Xiaomi，Android 13 API 33，`wm size` 1080x2400，dp 宽 ~400，属于 compact 断点）
**构建**：`fvm flutter run -d jfxgpjeul7lrpjkz --debug`（debug 装机，方便未来配 mcp_dart 拉 widget tree；无 `flutter install`）
**Dart VM Service URI**（本机 forward，仅本机可用，未连 mcp_dart）：`http://127.0.0.1:9080/-6pR5IBUWLs=/`
**stdout 日志绝对路径**：`D:\workspace\smoke-evidence\2026-09-03-p0-1\flutter_run_stdout.log`
**runtime errors 结果**（`Select-String -Pattern 'Exception|Error|ERROR' flutter_run_stdout.log` → 0 命中）：
`flutter run` 主链路 stdout 完全无 Dart 层 Exception / Error 关键字。日志唯一
非常规行是 `I/flutter (12694)` 打印的 Impeller 后端声明 + 第三方插件（fluro / dio）
自身 debug info，无异常栈。

**截图（绝对路径，未入库，reviewer 从本地复核）**：

| 用途 | 路径 |
|---|---|
| ①冷启动首帧 compact home（"动态"tab） | `D:\workspace\smoke-evidence\2026-09-03-p0-1\01_home_after_launch.png` |
| ②硬件 back 从 home 触发 → 退回桌面（符合 compact 单栏 PopScope 契约） | `D:\workspace\smoke-evidence\2026-09-03-p0-1\02_after_back_from_home.png` |
| ③再次冷启动回到 compact home 首帧无异常 | `D:\workspace\smoke-evidence\2026-09-03-p0-1\03_home_after_relaunch.png` |

### VM Service widget tree 证据（2026-09-03 补，直连 JSON-RPC）

**背景订正**：初版汇报把"未接 `mcp_dart` MCP 客户端"当成"没法拿 widget tree"，属于自我矮化。
`flutter run --debug` 起来后 [Dart VM Service Protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md)
本身就是 spec 化的 JSON-RPC over WebSocket，`ext.flutter.inspector.*` 是
[Flutter WidgetInspectorService](https://api.flutter.dev/flutter/widgets/WidgetInspectorService-class.html)
向 VM Service 注册的官方 service extension。`dart_mcp_server` / `mcp_dart` 只是这一层
的 MCP 客户端封装。所以直接对 WebSocket 发 JSON-RPC 与走 mcp_dart 语义等价，走的是同
一份官方 spec。

**采集方式**：临时 dart 脚本
[dump_widget_tree.dart](file:///D:/workspace/smoke-evidence/2026-09-03-p0-1/dump_widget_tree.dart)（不入库业务代码，留本地），
连 `ws://127.0.0.1:12226/ETOH9r-YSxQ=/ws`，依次调
`getVM` → `getIsolate` → `ext.flutter.inspector.getRootWidgetTree`
（带 `groupName=gsy-smoke, isSummaryTree=true, withPreviews=true`）。

**Dart VM Service URI（重启 flutter run 后新值）**：`http://127.0.0.1:12226/ETOH9r-YSxQ=/`
（stdout log [flutter_run_stdout_v2.log](file:///D:/workspace/smoke-evidence/2026-09-03-p0-1/flutter_run_stdout_v2.log) 第 54 行）

**产物**：

| 文件 | 大小 | 用途 |
|---|---|---|
| `D:\workspace\smoke-evidence\2026-09-03-p0-1\extension_rpcs.txt` | 76 个 extension RPC | 证明 debug 模式下 `ext.flutter.inspector.*` 全套 32 个 inspector RPC 挂上（含 `getRootWidgetTree` / `getRootWidgetSummaryTreeWithPreviews` / `getSelectedWidget` / `screenshot`） |
| `D:\workspace\smoke-evidence\2026-09-03-p0-1\widget_tree_full.json` | 844 KB | 全量 widget tree（含 `creationLocation` 精确到源文件行、`valueId` inspector 引用、`createdByLocalProject` 标志） |

**M2 关键 shell 结构命中证据**（`Select-String 'GSYAdaptive|_ShellFor|HomePage|detailNavigator|GSYTab|PopScope|GSYTwoPane|adaptive_shell|gsy_tabbar' widget_tree_full.json` → 15 命中，其中 shell 骨架层的定位如下）：

```
[root] (framework RootWidget)
 └─ ConfigWrapper (main.dart:24)
     └─ _InheritedConfig (config_wrapper.dart:18)
         └─ FlutterReduxApp (main.dart:26)
             └─ UncontrolledProviderScope           ← Riverpod 全局 scope
                 └─ ... (MaterialApp/Router 装配层)
                     └─ HomePage (app.dart:141)      ← inspector-20
                         └─ PopScope<Object> (home_page.dart:85)   ← inspector-21，M2 硬件返回契约
                             └─ GSYTabBarWidget (home_page.dart:101) ← inspector-22，compact 骨架
                                 └─ Scaffold (gsy_tabbar_widget.dart:307)
                                     └─ PageView + AppBar + GSYTitleBar 等
```

**契约层结论**：

- ✅ `PopScope<Object>` 稳定挂在 [home_page.dart §85](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart#L85) 位置，其 child 是 `GSYTabBarWidget`——**hardware back 分派入口就位**
- ✅ 当前是 compact 模式（`GSYTabBarWidget` 直挂 HomePage）——符合 dp ~400 断点决议
- ✅ 没有 `GSYAdaptiveNavigation` / `detailNavigatorKey` / `GSYTwoPaneDetailPlaceholder` 挂在 tree 里——**符合 compact 契约**（two-pane 才实例化 detail navigator，见 [gsy_adaptive_shell.dart §buildShell 分支](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)）

**已知折损**：`ext.flutter.inspector.getRootWidgetSummaryTreeWithPreviews` /
`ext.flutter.inspector.getRootWidget` 在**没预先 setPubRootDirectories** 时会
`Null check operator used on a null value`（framework 侧 issue，见
[widget_inspector.dart §2090](file:///D:/DevData/FVM/versions/3.47.2/packages/flutter/lib/src/widgets/widget_inspector.dart)）；
用 `getRootWidgetTree` + 显式 groupName 绕过，功能等价。

### 已知缺口（本轮真机做不到，reviewer 需要知悉）

1. **expanded 双栏 M2 关键路径未覆盖**：手机 dp 宽 ~400 是 compact，达不到 ≥840dp expanded；
   本次修复的 [openDetail P0-2 分支](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L307-L358)
   与 [PopScope 双栏 back 契约](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart)
   在真机上只能靠平板 / 大屏 emulator 复核。**目前依赖单测**
   [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart)
   的 34 条契约测试保证行为，等下次装机到平板 / Fold 再补真机 widget tree（此时 tree 里应能命中
   `GSYAdaptiveNavigation.detailNavigatorKey`）。
2. **`adb shell input tap/swipe` 坐标脚本禁令**（2026-09-02 拍板）：本轮遵守禁令，
   `openDetail push 到 detailKey 子树` / `ReposItem 窄列 overflow 修复` 需要点开
   卡片才能验证。虽然本轮通过 VM Service 拉到了 shell 层 widget tree，但**尚未通过
   `ext.flutter.inspector.setSelectionById` + `getSelectedWidget`** 完成 UI 事件层面
   自动触发（下轮可用 `ext.flutter.inspector.screenshot` 或 `vm_service eval` 走
   `Navigator.push` 直接触发路由）。这两条路径的行为回归依赖 case 22
   `openDetail 分派锁死` / `ReposItem widget tree` 单测（[test/page/repos/repos_item_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/repos/repos_item_test.dart)）保证。

## 依赖升级冒烟（2026-09-04）

**升级项**：`webview_flutter 4.10.0 → 4.14.1` · `dio 5.9.0 → 5.11.0` ·
`flutter_svg 2.1.0 → 2.3.0` · `rxdart 0.27.1 → 0.28.0` ·
`built_value 8.12.0 → 8.12.6` · `built_value_generator 8.12.7 → 8.13.0`。

**静态验证**：

- `fvm flutter pub get`：resolver 无冲突，6 个 direct dep 完成锁定
- `fvm flutter analyze`：0 error / 0 warning（保留 1 个 pre-existing `analysis_options_deprecated_plugins` warning 与 1 个 rxdart 0.28.0 收紧类型后 `user_redux.dart:66` 的 `void_checks` info，均与本轮升级契约无关）
- `fvm flutter test`：**353 个测试全部通过**（含 widget test / repos_item_test / gsy_adaptive_shell_test 等 P0/P1/P2 契约锁）

**运行时冒烟**：

- 设备：Android emulator `emulator-5554`（API 36，Android 16，x86_64）
- Dart VM Service：`http://127.0.0.1:8692/c9pDDXxC-lY=/`（WS `.../ws`）
- 采集脚本：[dump_widget_tree.dart](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/deps_upgrade_20260904/dump_widget_tree.dart)（直连 VM Service JSON-RPC，与 mcp_dart 走同一份 spec）
- runtime errors：`flutter run --debug` stdout 全程 0 条 `Exception` / `FlutterError` / `═════` red screen（filter 空匹配）
- 首屏路径：Dynamic tab 首帧 events 完整渲染，dio 请求 `GET /users/CarSmallGuo/received_events` 与 `GET /repos/CarGuo/gsy_github_app_flutter/releases` 均正常返回 200（说明 **dio 5.11.0 网络栈 + interceptor + rxdart 0.28.0 driven epic middleware** 全链路健康）

**产物**：

| 文件 | 大小 | 用途 |
|---|---|---|
| [widget_tree.json](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/deps_upgrade_20260904/widget_tree.json) | 854 KB | 全量 widget tree，`isSummaryTree=true` |
| [vm_info.json](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/deps_upgrade_20260904/vm_info.json) | 1.7 KB | `getVM` 结果，1 个 isolate 3673487371632247 |
| [flutter_views.json](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/deps_upgrade_20260904/flutter_views.json) | 419 B | `_flutter.listViews` 结果，1 个 FlutterView |
| [01_home_boot.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/deps_upgrade_20260904/01_home_boot.png) | 246 KB | 冷启动后首页 Dynamic tab expanded 双栏截图（emulator 是 landscape，dp 宽 > 840，命中 expanded 分支 + master-detail 占位） |

**契约层命中**（widget_tree.json grep）：

```
FlutterReduxApp (main.dart:26)                     ← Redux 根装配存活
 └─ UncontrolledProviderScope                      ← Riverpod scope 存活
     └─ ... Consumer/StoreProvider/StreamBuilder ...
         └─ MaterialApp
             └─ HomePage (app.dart)
                 └─ PopScope<Object>               ← M2 hardware back 契约存活
                     └─ GSYTabBarWidget
                         └─ Scaffold → SafeArea → Row
                             └─ NavigationRail     ← expanded rail 命中（截图佐证）
                             └─ SingleChildScrollView + LayoutBuilder ← rail 布局链路 OK
```

**结论**：Redux + Riverpod + Provider + Signals 四态并存的根装配、dio 网络栈、rxdart driven epic middleware、大屏 rail 双栏布局在本次升级后**全部无回归**。

**已知缺口**：

1. WebView 主路径未覆盖：本轮 fixture 账号已登录，未主动触发 OAuth WebView 页面；`webview_flutter 4.14.1` 的登录页 / GitHub OAuth 授权路径下轮登录相关改动时需在真机再走一遍
2. inappwebview markdown 图片渲染路径未覆盖：需进入具体 repo detail 的 README tab 才能命中；本轮遵守 `adb shell input tap/swipe` 禁令未通过坐标脚本触发，下轮可用 `vm_service eval` 走 `Navigator.push('/reposDetail')` 补齐
3. SVG 渲染（`flutter_svg 2.3.0`）本轮命中路径有限，`SvgPicture.asset` 主要挂在 empty state 与 login 页；下轮走登出后 login 页可完整覆盖



