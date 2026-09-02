# open_home_dynamic

首页 Dynamic tab 冒烟路径描述。**不再是 adb 坐标脚本**（2026-09-02 拍板全面回归
[mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)）。

## 目标

验证 [dynamic_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/dynamic/dynamic_page.dart)
与 [event_utils.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/utils/event_utils.dart)
的事件识别在真机上稳定，覆盖：

- `PushEvent`（带 head short SHA）
- `IssuesEvent opened`（issue #n + title）
- `ForkEvent`（src → dst）
- `WatchEvent started`（关注了 repo）

未覆盖但对同一段 switch 分支等价的事件（`DiscussionEvent` / `DiscussionCommentEvent`
/ `SponsorshipEvent` / `PullRequestReviewThreadEvent`）在多数 received feed 里
出现频率极低，靠 [docs/04-quality/smoke-matrix.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/docs/04-quality/smoke-matrix.md)
"首页动态 / 事件识别" 段落的单元测试兜底。

## Fixture

- 账号：`CarSmallGuo`（当前设备与 gh cli 登录账号，只读 token）
- received feed 前 40 条

## 步骤（mcp_dart 主路径）

1. `flutter run -d <deviceId>` 起 debug 构建。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 基线，应为 `No runtime errors found.`。
4. app 冷启后停在 Home 页 Dynamic tab（默认起点）。
5. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=true` 拿 tree，
   grep 出以下命中项：
   - `GSYEventItem` 实例数 >= 5
   - `GSYUserIconWidget` 实例数 与 `GSYEventItem` 一致
   - `textPreview` 里出现至少两种事件文案（例：`Starred ...` / `Pushed to ...` /
     `Deleted branch ...` / `Opened issue #...`）
6. 抓截图：iOS 用 `xcrun simctl io <UDID> screenshot`，Android 用 `adb exec-out screencap -p`。
7. **下拉刷新验证**：人肉下拉刷新一次，等 4s 后再拉一次 `widget_inspector`，
   确认 tree 顶部 event 列表被更新（顶部 `textPreview` 变化），
   再抓一张截图对比。
8. **上拉分页验证**：人肉上拉加载下一页，等 3s，再拉 tree，
   确认 `GSYEventItem` 实例数 > 之前，抓截图。
9. `mcp_dart` `get_runtime_errors` 再拉一次，应仍为 `No runtime errors found.`。

## 完成汇报必填

见 [AGENTS.md 完成汇报三段式](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L129-L135)。

## 反例（禁止）

- ❌ 用 `adb shell input swipe` 坐标脚本代替人肉下拉/上拉
- ❌ 只截图不看 `widget_inspector`
- ❌ 用 `adb logcat -d -s flutter` 当日志来源（现在改用 `mcp_dart get_runtime_errors`）
