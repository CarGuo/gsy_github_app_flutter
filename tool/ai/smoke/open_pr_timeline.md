# open_pr_timeline

PR timeline 冒烟路径描述。**不再是 adb 坐标脚本**（2026-09-02 拍板全面回归
[mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)）。

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

## 步骤（mcp_dart 主路径）

1. `flutter run -d <deviceId>` 起 debug 构建，等待 `Dart VM Service on ... is available at: <uri>` 打印。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 拿"改动前"基线，应为 `No runtime errors found.`。
4. 走到 PR #938 详情页 timeline（三种触发方式，任选可行的一种）：
   - **首选**：人肉在 iOS Simulator / Android 上操作 UI，走"首页 → 搜索 →
     CarGuo/gsy_github_app_flutter → ISSUE tab → #938 → 向下滚 timeline"。
   - **备选 1**：`mcp_dart` `vm_service` `evaluate` 触发 `Navigator.push` 到
     `IssueDetailPage`（需要 app 支持 URI scheme 深链，目前 GSY 未接入，先用首选）。
   - **备选 2**：改造 `main.dart` 临时加一个 debug-only 深链入口，跑完删除
     （**不允许**提交这类临时代码到 master）。
5. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=true` 拿完整
   widget 树，`grep` 出以下命中项证据：
   - `textPreview` 里包含 `Copilot 提交了评审意见`（或英文 `Copilot reviewed`）
   - 该行下方存在一个 `Card` widget 承载 review body（788 字符）
   - `EventTimelineItem` / `IssueTimelineItem` 类型实例数 >= 1
6. `xcrun simctl io <UDID> screenshot /tmp/gsy_smoke_pr_timeline_<ts>.png`
   （iOS）或 `adb exec-out screencap -p > /tmp/gsy_smoke_pr_timeline_<ts>.png`
   （Android）抓截图作为人眼层面补充证据。
7. `mcp_dart` `get_runtime_errors` 再拉一次，应仍为 `No runtime errors found.`。

## 完成汇报里必须写清

- 平台 + 设备 id（例：iOS Simulator iPhone 17 Pro `D62B...`）
- `mcp_dart` DTD/VM Service URI
- `widget_inspector` 命中 `textPreview` 摘录
- 截图**绝对路径**
- 无法覆盖的分支列表（例：`base_ref_force_pushed` 真机 fixture 空 → 靠 `test/model/*.dart` 单测覆盖）

## 反例（禁止）

- ❌ 用 `adb shell input tap X Y` 坐标脚本代替人肉操作或 `vm_service eval`
- ❌ 只截图不连 DTD 拿 `get_runtime_errors`
- ❌ 新造 fixture PR 或用 gh cli 造评论
