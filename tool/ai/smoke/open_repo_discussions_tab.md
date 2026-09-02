# open_repo_discussions_tab

Discussions tab 冒烟路径描述。**不再是 adb 坐标脚本**（2026-09-02 拍板全面回归
[mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)）。

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

## 步骤（mcp_dart 主路径）

1. `flutter run -d <deviceId>` 起 debug 构建。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 基线。
4. 走到 `666ghj/BettaFish` 仓库详情页 → 讨论 tab（三种触发方式，任选可行的一种）：
   - **首选**：人肉在模拟器 / 设备上操作 UI（搜索 → 仓库 → 讨论 tab）。
   - **备选 1**：`mcp_dart` `vm_service` `evaluate` 触发 `Navigator.push` 到
     `RepositoryDetailPage` 并指定 `initialTabIndex=3`。
   - **备选 2**：如上一样，禁止提交 debug-only 深链入口到 master。
5. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=true`，命中：
   - Discussion 列表 tab 下 `DiscussionItem` 实例数 >= 3
   - 至少 1 条 `textPreview` 含 category emoji Unicode（例：`💬`、`🙏`）
6. 打开 discussion `#680` 详情，再拉一次 tree，命中：
   - 详情页存在 `DiscussionDetailPage` widget
   - Markdown body 里含中文 `textPreview`
7. 每步各抓一张截图（iOS `xcrun simctl io screenshot`，Android `adb exec-out screencap`）。
8. `mcp_dart` `get_runtime_errors` 再拉一次。

## 完成汇报必填

见 [AGENTS.md 完成汇报三段式](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L129-L135)。

## 反例（禁止）

- ❌ 用 `adb shell input tap X Y` 坐标脚本
- ❌ 只截图不看 `widget_inspector`
