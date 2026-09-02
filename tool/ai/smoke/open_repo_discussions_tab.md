# open_repo_discussions_tab

Discussions tab 冒烟路径描述。**这是一个 Flutter 项目**，点击 / 触发 / 验证一律走
[mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)，
不基于 adb / 坐标 / 屏幕像素。2026-09-02 拍板。

## 目标

验证：

- [discussion_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/discussion/widget/discussion_item.dart)
  列表项渲染（`GSYUserIconWidget` 头像 / category emoji Unicode 化 / 锁定态 chip）
- [discussion_detail_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart)
  详情页深色 header 卡片 + Markdown body 卡片 + skeleton_notice 提示

## Fixture（写死，不允许换）

- 仓库：`666ghj/BettaFish`（Discussions 已开启，数据活跃）
- Discussion `#680`（`b612sheryl`，`category=General`，中文标题 + 中文 body + 1 条评论）
- Discussion `#686`（`XavierCheng215`，`category=Q&A / 🙏`）用于对照另一种 category emoji

反例仓库（不要退到）：
`CarGuo/gsy_github_app_flutter`（未启用 Discussions，只能验证 "tab 条件隐藏"）。

## Flutter 项目触发路由的一等公民：`mcp_dart` `vm_service` `evaluate`

关键前置：GSY 在 [app.dart#L25-L32](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L25-L32)
把 `GlobalKey<NavigatorState> navKey` 声明为**顶层 final 变量**，同时
[app.dart#L229-L341](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L229-L341)
提供了一批 `kDebugMode` 保护的**顶层 smoke 入口**：`gsySmokeGoReposDetail` / `gsySmokeGoDiscussionDetail` 都是现成的。

### 主路径（首选）：一行调用顶层 smoke 入口

```
// 走仓库详情页
mcp_dart vm_service evaluate
  targetId: <library id of package:gsy_github_app_flutter/app.dart>
  expression: 'gsySmokeGoReposDetail("666ghj", "BettaFish")'

// 直达 discussion 详情
mcp_dart vm_service evaluate
  targetId: <library id of package:gsy_github_app_flutter/app.dart>
  expression: 'gsySmokeGoDiscussionDetail("666ghj", "BettaFish", 680)'
```

`<library id>` 通过 `mcp_dart` `vm_service` 拉 `Isolate` → `libraries[]`
找 `uri == "package:gsy_github_app_flutter/app.dart"` 那条拿 `id`
（注意：Dart 里"root library"专指 isolate 入口 library，本项目入口是
`main.dart`；这里要的是 `app.dart` 的 library id，两个概念不同）。

### 切换到 Discussions tab

仓库详情页里 tab 切换目前**没有**顶层 smoke 入口（`gsySmokeGoReposDetail` 只跳到默认第 0 个 tab），
所以要么直接用 `gsySmokeGoDiscussionDetail` 跳过 tab 直接去详情页，
要么在仓库详情页面上做一次 tab eval：

1. `widget_inspector` 定位 `RepositoryDetailPage` 的 `State`。
2. `evaluate` 触发切换：

   ```
   evaluate(
     targetId: <repo_detail_state_object_id>,
     expression: '_tabController.animateTo(3)'
   )
   ```

   `index` 具体值以 [repository_detail_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/repos/repository_detail_page.dart)
   里 tab 顺序为准，Discussions 通常是最后一位。

如需一步到位跳到"仓库详情 + Discussions tab"，未来可以扩展 [gsySmokeGoReposDetail](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L281-L296)
签名加上 `{int initialTab = 0}` 参数，并在 `RepositoryDetailPage` 里读取；
**默认不预先加**，冒烟频率上来了再动。

### 降级 A（旧姿势）：抓 Element `objectId` + `_element!.buildContext`

如果 debug 构建**因某种原因没有相应的 `gsySmokeGoXxx` 顶层入口**才走这条：

```
// 走仓库详情页（旧姿势）
evaluate(
  targetId: <material_app_element_object_id>,
  expression: '''
    NavigatorUtils.goReposDetail(
      _element!.buildContext,
      "666ghj", "BettaFish",
    )
  '''
)

// 直达 discussion 详情（旧姿势）
evaluate(
  targetId: <material_app_element_object_id>,
  expression: '''
    NavigatorUtils.goDiscussionDetail(
      _element!.buildContext,
      "666ghj", "BettaFish", 680,
    )
  '''
)
```

`targetId` 取法见 [open_pr_timeline.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_pr_timeline.md) §降级 A。

### 降级 B（最后的最后）：人肉点

人肉在模拟器上点，走"搜索 → 仓库 → 讨论 tab"。仅当主路径 + 降级 A 都不可用时使用；
**必须在完成汇报里说明"这一步为什么无法自动化"**。

## 步骤

1. `flutter run -d <deviceId>` 起 debug 构建。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 基线。
4. **触发路由到 discussions tab（主路径）**：eval 一次
   `gsySmokeGoReposDetail("666ghj", "BettaFish")` + eval 一次
   `TabController.animateTo(<discussions_index>)`（或一次
   `gsySmokeGoDiscussionDetail("666ghj", "BettaFish", 680)` 直达 #680）。
   走不通再降级。
5. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=true`，命中：
   - Discussion 列表 tab 下 `DiscussionItem` 实例数 >= 3
   - 至少 1 条 `textPreview` 含 category emoji Unicode（例：`💬`、`🙏`）
6. 打开 discussion `#680` 详情（同上 eval `gsySmokeGoDiscussionDetail`），再拉一次 tree，命中：
   - 详情页存在 `DiscussionDetailPage` widget
   - Markdown body 里含中文 `textPreview`
7. 截图（人眼补充证据）：iOS `xcrun simctl io <UDID> screenshot`，Android
   `adb exec-out screencap -p`。
8. `mcp_dart` `get_runtime_errors` 再拉一次。

## 完成汇报必填

见 [AGENTS.md 完成汇报三段式](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L129-L135)。

## 反例（禁止）

- ❌ 用 `adb shell input tap X Y` 坐标脚本触发跳转（Flutter app 用 `vm_service eval`）
- ❌ 只截图不看 `widget_inspector`
- ❌ 把"人肉点"当默认路径
