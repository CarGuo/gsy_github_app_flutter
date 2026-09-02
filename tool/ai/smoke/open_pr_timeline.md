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

关键前置：GSY 在 [app.dart#L25-L32](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L25-L32)
把 `GlobalKey<NavigatorState> navKey` 声明为 **顶层 final 变量**，
挂在 `MaterialApp(navigatorKey: navKey)` 上；同时 [app.dart#L229-L341](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L229-L341)
里提供了一批 `kDebugMode` 保护的**顶层 smoke 入口**——release 构建下这批函数早退并只打 log，
不承担业务逻辑。这套东西合起来意味着：**vm_service `evaluate` 里一行就能跳到任何目标页**。

### 主路径（首选）：一行调用顶层 smoke 入口

```
mcp_dart vm_service evaluate
  targetId: <library id of package:gsy_github_app_flutter/app.dart>
  expression: 'gsySmokeGoIssueDetail("CarGuo", "gsy_github_app_flutter", "938")'
```

`<library id>` 通过 `mcp_dart` `vm_service` 拉 `Isolate` → `libraries[]`
里找 `uri == "package:gsy_github_app_flutter/app.dart"` 那条拿 `id` 即可
（注意：Dart 里"root library"术语专指 isolate 入口 library，本项目入口是
`main.dart`；这里我们需要的是 `app.dart` 的 library id，两个概念不同）。
拿到之后，任何 `gsySmokeGoXxx` 都是"一次 evaluate、一行 expression"的事儿。

现有顶层入口清单（都在 [lib/app.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart) 底部）：

- `gsySmokeGoIssueDetail(owner, repo, number)` → issue / PR 详情
- `gsySmokeGoReposDetail(owner, repo)` → 仓库详情
- `gsySmokeGoDiscussionDetail(owner, repo, number)` → Discussion 详情
- `gsySmokeGoPerson(userName)` → 个人页

**新加入口**：直接在 [app.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart)
底部照现有 pattern 加一个 `Future<Object?> gsySmokeGoXxx(...)` 就行，无需改其它文件。

### 降级 A（旧姿势）：抓 Element `objectId` + `_element!.buildContext`

只有当 debug 构建**因为某种原因没有对应的 `gsySmokeGoXxx` 入口**（例如你在写新入口之前想先跑一次冒烟）
才需要走这条路。步骤：

1. 用 `mcp_dart` `widget_inspector get_selected_widget` 或 `get_widget_tree`
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

   如果 eval 的作用域拿不到 `NavigatorUtils`（未 import），改用 `evaluateInFrame`，
   并从 `Isolate.libraries[]` 里查
   `uri == "package:gsy_github_app_flutter/common/utils/navigator_utils.dart"`
   那条拿 `libraryId`，再 evaluate（**不要**用 `Isolate.rootLibrary` —— 那个字段
   指向 isolate 入口 `main.dart`，从它拿不到 `navigator_utils.dart` 的
   `libraryId`；术语辨析同上文 `<library id>` 段）。

3. eval 返回 `Future<dynamic>`，可再 eval 一次 `widget_inspector` 拿新 widget tree
   验证已到 `IssueDetailPage`。

### 降级 B（最后的最后）：人肉点

人肉在 iOS Simulator / Android Emulator 上点，走"首页 → 搜索 →
CarGuo/gsy_github_app_flutter → ISSUE tab → #938 → 向下滚 timeline"。
仅当主路径 + 降级 A 都不可用时使用；**必须在完成汇报里注明"这一步为什么无法自动化"**。

## 步骤

1. `flutter run -d <deviceId>` 起 debug 构建，等 stdout 打印 `Dart VM Service on ... is available at: <uri>`。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 拿"改动前"基线，应为 `No runtime errors found.`。
4. **触发路由（主路径）**：`mcp_dart` `vm_service evaluate`，`targetId` 用
   `package:gsy_github_app_flutter/app.dart` 的 library id，`expression` 写
   `gsySmokeGoIssueDetail("CarGuo", "gsy_github_app_flutter", "938")`。
   如果主路径走不通，走降级 A 或 B（并汇报原因）。
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
