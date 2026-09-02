# open_home_dynamic

首页 Dynamic tab 冒烟路径描述。**这是一个 Flutter 项目**，点击 / 触发 / 验证一律走
[mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)，
不基于 adb / 坐标 / 屏幕像素。2026-09-02 拍板。

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

## Flutter 项目触发操作的一等公民：`mcp_dart`

首页 Dynamic tab 是 app 冷启后的默认起点，**天然不需要跳转**（路由入口的降级 A 顶层
`gsySmokeGoXxx`——见 [app.dart#L229-L341](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L229-L341)
——在这里派不上用场，属于 route 层面的入口）。下拉刷新 / 上拉加载是核心验证目标，
必须走 mcp_dart 拉动 `State` 私有字段上的 controller，而**不是** `adb shell input swipe`。

### 下拉刷新（主路径）：`vm_service evaluate` 直接调用 refresh controller

`dynamic_page.dart` 里的下拉刷新走 [gsy_pull_load_widget](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/pull/gsy_pull_load_widget.dart)
的 `GSYPullLoadWidgetControl`。做法：

1. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=false` 拿到
   `DynamicPage` 对应的 `State` 的 `objectId`（`get_selected_widget` 也行，先在
   IDE / Devtools 里选中一次列表任意 item，或用 Flutter Inspector 的 select mode）。
2. 用该 `objectId` 作为 `targetId`，`vm_service` `evaluate`：

   ```
   evaluate(
     targetId: <dynamic_page_state_object_id>,
     expression: '_pullLoadWidgetControl.onRefresh?.call()'
   )
   ```

   如果 `_pullLoadWidgetControl` 是私有字段，用 [widget_inspector get_selected_widget](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L83)
   拿到 `_DynamicPageState` 后用 `evaluateInFrame` 反射进去。

3. eval 后 `mcp_dart` `hot_reload` 或 `widget_inspector` 3~4 秒后再拉一次 tree，
   确认顶部 `GSYEventItem` 列表被刷新（顶部 `textPreview` 变化）。

### 上拉分页（主路径）：同上，触发 loadMore

```
evaluate(
  targetId: <dynamic_page_state_object_id>,
  expression: '_pullLoadWidgetControl.onLoadMore?.call()'
)
```

### 未来可选下沉：给 [app.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart) 加 `gsySmokeRefreshHome`

如果反复冒烟 Dynamic tab 很频繁，值得给 [app.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart)
再加两个 `kDebugMode` 保护的顶层入口（照现有 `gsySmokeGoXxx` pattern）：

```dart
void gsySmokeRefreshHome() { ... }   // 内部通过 eventBus.fire(RefreshHomeEvent()) 广播，DynamicPage 里 listen
void gsySmokeLoadMoreHome() { ... }
```

这样冒烟命令就变成一行 `gsySmokeRefreshHome()`，跟路由入口的姿势对齐。
**默认不预先加**——只有真需要频繁跑时才加，避免 debug-only 顶层函数无节制膨胀。

### 降级（最后的最后）：人肉下拉 / 上拉

人肉在模拟器上下拉 / 上拉。仅当上面两条都不可用时使用；
**必须在完成汇报里说明"这一步为什么无法自动化"**。

## 步骤

1. `flutter run -d <deviceId>` 起 debug 构建。
2. `mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. `mcp_dart` `get_runtime_errors` 基线，应为 `No runtime errors found.`。
4. app 冷启后停在 Home 页 Dynamic tab（默认起点，**无需触发跳转**）。
5. `mcp_dart` `widget_inspector` `get_widget_tree summaryOnly=true` 拿 tree，
   grep 出以下命中项：
   - `GSYEventItem` 实例数 >= 5
   - `GSYUserIconWidget` 实例数 与 `GSYEventItem` 一致
   - `textPreview` 里出现至少两种事件文案（例：`Starred ...` / `Pushed to ...` /
     `Deleted branch ...` / `Opened issue #...`）
6. 截图（人眼补充证据，**不承担业务验证职责**）：
   - iOS：`xcrun simctl io <UDID> screenshot`
   - Android：`adb exec-out screencap -p`
7. **下拉刷新验证**：按§下拉刷新 eval 一次，3~4s 后再拉一次 `widget_inspector`，
   确认顶部 `textPreview` 变化，再抓一张截图对比。
8. **上拉分页验证**：按§上拉分页 eval 一次，3s 后再拉 tree，确认
   `GSYEventItem` 实例数 > 之前，抓截图。
9. `mcp_dart` `get_runtime_errors` 再拉一次，应仍为 `No runtime errors found.`。

## 完成汇报必填

见 [AGENTS.md 完成汇报三段式](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L129-L135)。

## 反例（禁止）

- ❌ 用 `adb shell input swipe` 坐标脚本代替下拉 / 上拉（Flutter app 不该基于像素点，用 `vm_service eval` 触发 controller）
- ❌ 只截图不看 `widget_inspector`
- ❌ 用 `adb logcat -d -s flutter` 当日志来源（改用 `mcp_dart get_runtime_errors`）
- ❌ 把"人肉下拉 / 上拉"当默认路径
