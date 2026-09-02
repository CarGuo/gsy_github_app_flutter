# open_pr_timeline

PR timeline 冒烟路径描述。**这是一个 Flutter 项目**，点击 / 触发 / 验证一律走
[mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)，
不基于 adb / 坐标 / 屏幕像素。2026-09-02 拍板。

## 目标

验证 [issue_timeline_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_timeline_item.dart)
的事件行渲染是否正常，包括新事件（`ready_for_review` / `review_requested` /
`assigned` / `merged` / `closed` / `reviewed` body 卡片 / 未知事件兜底）。

## Fixture（写死，不允许换）

- 仓库：[CarGuo/gsy_github_app_flutter](https://github.com/CarGuo/gsy_github_app_flutter)
- PR：`#938`（Copilot Android APK 优化）
  - `reviewed / state=commented`，body 788 字符
  - 同时覆盖 `ready_for_review` / `review_requested` / `assigned` / `merged`
    / `closed` / 未知事件兜底

## Flutter 项目触发路由的一等公民：`mcp_dart` `vm_service` `evaluate`

关键前置：GSY 在 [app.dart#L99-L163](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L99-L163)
已经把 `GlobalKey<NavigatorState> navKey` 挂在 `MaterialApp(navigatorKey: navKey, ...)` 上。
这意味着**可以通过 VM Service `evaluate` 直接调用 `NavigatorUtils.goIssueDetail`**，
不需要造深链、不需要人肉点、更不需要 adb 坐标。

具体命令（`mcp_dart` `vm_service` `evaluate`，targetId 用当前 running isolate）：

```dart
// 1. 拿到根 Navigator 的 context（用 navKey 的 currentContext）
//    → 通过 top-level library 反射 `package:gsy_github_app_flutter/app.dart` 里
//      HttpErrorListener mixin 挂上去的 navKey。
//    实操上更简单的入口：走已导出的顶层函数 / static 方法。见下面 §Isolate eval 具体做法。

// 2. 调用 NavigatorUtils.goIssueDetail 触发跳转：
NavigatorUtils.goIssueDetail(
  navKey.currentContext!,
  'CarGuo', 'gsy_github_app_flutter', '938',
);
```

### Isolate eval 具体做法

`mcp_dart` `vm_service` 的 `evaluate` 需要一个 `targetId`。对 Flutter app 而言最稳的做法：

1. 先用 `mcp_dart` `widget_inspector` `get_selected_widget` 或 `get_widget_tree`
   拿到任意 `Element` 的 `objectId`（例如 `MaterialApp` 或 `MyHomePage` 的元素）。
2. 用该 `objectId` 作为 `targetId` 触发 eval：

   ```
   evaluate(
     targetId: <element_object_id>,
     expression: '''
       (() {
         final ctx = _element!.buildContext;
         return NavigatorUtils.goIssueDetail(
           ctx, "CarGuo", "gsy_github_app_flutter", "938",
         );
       })()
     '''
   )
   ```

   如果 eval 的作用域拿不到 `NavigatorUtils`（未 import），改用 `evaluateInFrame` +
   `Isolate.rootLibrary` 拿到 `package:gsy_github_app_flutter/common/utils/navigator_utils.dart`
   的 `libraryId`，再 evaluate。

3. eval 返回 `Future<dynamic>`，可以再 eval 一次 `widget_inspector` 拿新 widget tree
   验证已到 `IssueDetailPage`。

### 降级（仅当上面 eval 因作用域 / library 未加载失败时用）

- **降级 A（推荐）**：给 [app.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart)
  加一个 debug-only 顶层函数（`kDebugMode` 保护），比如 `void gsySmokeGoIssueDetail(String owner, String repo, String num) => NavigatorUtils.goIssueDetail(navKey.currentContext!, owner, repo, num);`
  ——**只保留在 debug 构建里**，release 编译时被 tree-shake 掉。这项动作**需作者拍板一次**再落地，落地后所有场景 md 都可以共享这个入口。
- **降级 B**：人肉在 iOS Simulator / Android Emulator 上点，走"首页 → 搜索 →
  CarGuo/gsy_github_app_flutter → ISSUE tab → #938 → 向下滚 timeline"。仅当
  eval 与降级 A 都不可用时使用；必须在完成汇报里注明"这一步为什么无法自动化"。

## 步骤

1. `flutter run -d <deviceId>` 起 debug 构建，等 stdout 打印 `Dart VM Service on ... is available at: <uri>`。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 拿"改动前"基线，应为 `No runtime errors found.`。
4. **触发路由**：用上面§Isolate eval 具体做法调用 `NavigatorUtils.goIssueDetail`。
   如果 eval 走不通，走降级 A 或 B（并汇报原因）。
5. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=true` 拿完整
   widget 树，命中：
   - `textPreview` 含 `Copilot 提交了评审意见`（或英文 `Copilot reviewed`）
   - 该行下方存在一个 `Card` widget 承载 review body（788 字符）
   - `EventTimelineItem` / `IssueTimelineItem` 类型实例数 >= 1
6. 截图（仅作人眼补充证据，**不承担业务验证职责**）：
   - iOS：`xcrun simctl io <UDID> screenshot /tmp/gsy_smoke_pr_timeline_<ts>.png`
   - Android：`adb exec-out screencap -p > /tmp/gsy_smoke_pr_timeline_<ts>.png`
7. `mcp_dart` `get_runtime_errors` 再拉一次，应仍为 `No runtime errors found.`。

## 完成汇报里必须写清

- 平台 + 设备 id（例：iOS Simulator iPhone 17 Pro `D62B...`）
- `mcp_dart` DTD/VM Service URI
- 触发路由用的具体路径（eval / 降级 A / 降级 B）
- `widget_inspector` 命中 `textPreview` 摘录
- 截图**绝对路径**
- 无法覆盖的分支列表（例：`base_ref_force_pushed` 真机 fixture 空 → 靠 `test/model/*.dart` 单测覆盖）

## 反例（禁止）

- ❌ 用 `adb shell input tap X Y` / 坐标脚本触发跳转（Flutter app 不该基于像素点，用 `vm_service eval`）
- ❌ 只截图不连 DTD 拿 `get_runtime_errors`
- ❌ 把"人肉点"当默认路径（GSY 已挂全局 `navKey`，一等公民是 eval）
- ❌ 新造 fixture PR 或用 gh cli 造评论
