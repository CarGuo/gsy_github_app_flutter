# open_discussion_verify

Discussions 家族真机验收 5 条缺口一次性兑现的冒烟路径。**Flutter 项目**，触发 / 命中 / 验证一律走
[mcp_dart](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md)，不基于 adb / 坐标 / 屏幕像素（2026-09-02 拍板）。

## 背景

Discussion 详情页 [discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart)、
reactions bar、answered 徽标、bot chip、release-linked footer、safe_pre_builder 手势修复代码层已完成，
但 [roadmap §3.1](file:///d:/workspace/project/gsy_github_app_flutter/docs/00-overview/roadmap.md)
真机验收 5 条缺口未兑现。本文档沉淀 SOP，一次性走完。

## Fixture（写死，不允许换）

| pt | 路径 | 仓库 / discussion | 关键场景 |
|---|---|---|---|
| pt.1 | reactions bar 渲染 + 长按 sheet + toggle | [`666ghj/BettaFish#511`](https://github.com/666ghj/BettaFish/discussions/511)（👍30🎉11 现成）+ [`#417`](https://github.com/666ghj/BettaFish/discussions/417)（Q&A，需 add reaction） | 8 类 emoji 底部 sheet 一次全命中 + count-1 → count+1 → count-1 三态 toggle |
| pt.2 | answered / self-answer / bot chip / deleted 边界 | [`#417`](https://github.com/666ghj/BettaFish/discussions/417) + [`#697`](https://github.com/666ghj/BettaFish/discussions/697)（deleted 404） | answered badge / self-answer / bot chip / discussion_not_found 兜底 |
| pt.3 | loadMore 第 2 次触发（60→90） | [`vercel/next.js#49607`](https://github.com/vercel/next.js/discussions/49607)（125 comments） | `hasNextPage=true` 分支再命中 + safe_pre_builder 手势修复真机复核 |
| pt.4 | private-user-images JWT CDN 图片渲染 | [`#511`](https://github.com/666ghj/BettaFish/discussions/511) body 段 | `<img>` 实际渲染出图（非蓝链文本）+ `runtime_errors` 无 `Image.network failed` |
| pt.5 | replies 非空嵌套（`_buildReplyRow`） | [`#417`](https://github.com/666ghj/BettaFish/discussions/417) + [`#309`](https://github.com/666ghj/BettaFish/discussions/309) | reply 行渲染 + widget tree 命中 `_buildReplyRow` |

**账号**：`CarSmallGuo`（真机 `jfxgpjeul7lrpjkz` 已登录，gho\_ token `repo` 权限；pt.1 的 reactions 写操作只在本账号自己的可访问仓库做，符合 AGENTS.md 允许写清单）。

**设备策略**（2026-09-09 用户拍板）：
- **debug build 装到 `emulator-5554`（gsy_pixel_fold 折叠屏模拟器）**：拿 mcp_dart 一等公民证据（widget tree / runtime errors）
- **真机 `jfxgpjeul7lrpjkz` 只做人眼对拍**：不装 debug 避免清空 CarSmallGuo token，对着 GitHub 官网页面复核 UI 一致性
- **不用 `flutter install`**（AGENTS.md 明确禁止：会清 SharedPreferences）

**姿态策略**（2026-09-09 用户第二次拍板）：**pt.1 - pt.5 每一条路径都必须两姿态跑**，缺一档视为未完成——因为 discussion 详情走的是 [_openDetailOrRouter](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart)，compact 用 `Navigator.push` 到主 Navigator，expanded 用 `detailNavigatorKey` 到右列，两条代码路径不同、UI 呈现不同。

| 姿态 | 硬件切换 | 期望 layout | 证据后缀 |
|---|---|---|---|
| CLOSED（折叠） | `adb -s emulator-5554 emu fold` | 单栏 compact，主 Navigator push | `_closed.png` |
| OPENED（展开） | `adb -s emulator-5554 emu unfold` | 双栏 expanded，右列 detailNavigatorKey | `_opened.png` |

**收尾时必须 `adb -s emulator-5554 emu unfold` 复位**，否则下位 author 拿到折叠基线，属于 author 责任事故。参见 [AGENTS.md 折叠 + 非折叠双姿态强制](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md)。

## 步骤

### Step 0：起 debug build 到折叠屏模拟器

```powershell
fvm flutter run -d emulator-5554
```

- stdout 会打印 `Debug service listening on ws://...` 与 `Dart DevTools debugger and profiler ... http://127.0.0.1:9101?uri=...`
- 记住 VM Service URI（`ws://127.0.0.1:PORT/TOKEN=/ws`），供 `mcp_dart dtd connect` 用

### Step 1：mcp_dart DTD 连接 + baseline

```
mcp_dart dtd listDtdUris    → 拿 dtd uri
mcp_dart dtd connect <uri>  → 建连接
mcp_dart get_runtime_errors → 拍 runtime_errors_baseline.txt
mcp_dart vm_service         → 拉 Isolate → libraries → 找 uri == "package:gsy_github_app_flutter/app.dart" 的 library id
```

### Step 2：pt.1 reactions bar 验收

**触发路由（主路径）**：

```
mcp_dart vm_service evaluate
  targetId: <library id of app.dart>
  expression: 'gsySmokeGoDiscussionDetail("666ghj", "BettaFish", 511)'
```

**验证命中**：

```
mcp_dart widget_inspector get_widget_tree summaryOnly=true
```

期望命中：
- `DiscussionDetailPage` widget
- reactions groups 中至少有 `textPreview` 含 `👍 30` / `🎉 11` 的 chip
- 长按其中一个 chip → 底部 sheet 弹出 → tree 里出现新的 `BottomSheet` 节点，含 8 类 emoji 行

**写操作（toggle count-1 → count+1）**：

- 点 👍 chip → count-1 → 再点一次 → count+1 → widget tree 里的数字对应变化
- `mcp_dart get_runtime_errors` 无新增

**证据落地**：
- `evidence/20260909-discussion-verify/pt1_01_bettafish_511_reactions_bar.png`（reactions bar 初态）
- `evidence/20260909-discussion-verify/pt1_02_bettafish_511_long_press_sheet.png`（底部 sheet 8 类）
- `evidence/20260909-discussion-verify/pt1_03_bettafish_511_toggle_up.png`（+1 后）
- `evidence/20260909-discussion-verify/pt1_04_bettafish_511_toggle_back.png`（-1 恢复）
- `evidence/20260909-discussion-verify/pt1_05_bettafish_417_qna_add_reaction.png`（Q&A add reaction）

### Step 3：pt.2 answered / self-answer / bot chip / deleted 边界

```
mcp_dart vm_service evaluate  // #417 = Q&A + answered
  expression: 'gsySmokeGoDiscussionDetail("666ghj", "BettaFish", 417)'
```

期望 widget tree 命中：
- `textPreview` 含 answered badge 文案（本地化 key `discussion_answered_badge`）
- 若答者 == 提问者 → self-answer 视觉降权
- 若答者是 GitHub App / bot → bot chip 命中

```
mcp_dart vm_service evaluate  // #697 = deleted (404)
  expression: 'gsySmokeGoDiscussionDetail("666ghj", "BettaFish", 697)'
```

期望：
- 详情页 fallback 展示 `discussion_not_found` 兜底文案，不 crash
- `get_runtime_errors` 允许 GraphQL 404 warning，不允许 Dart 层 Exception

**证据**：
- `pt2_01_bettafish_417_answered.png`
- `pt2_02_bettafish_417_bot_chip.png`（如现有答者是 bot）
- `pt2_03_bettafish_697_deleted.png`

### Step 4：pt.3 loadMore 第 2 次触发（60→90）

```
mcp_dart vm_service evaluate
  expression: 'gsySmokeGoDiscussionDetail("vercel", "next.js", 49607)'
```

首次加载：预期 30 条 comment（首次 loadMore 已在上一轮验过）。

**第 1 次 loadMore**：滚到底 → 触发 → 60 条 → 命中 `_buildLoadMore` widget。
**第 2 次 loadMore**：再滚到底 → 触发 → 90 条 → 关键：**safe_pre_builder 手势修复后 code block 不再拦截 scroll**，能顺利再拉一页。

widget tree 命中：
- `DiscussionCommentItem` 实例数 == 90
- `hasNextPage=true` 分支 chip 再次出现

**证据**：
- `pt3_01_next_49607_first_page.png`
- `pt3_02_next_49607_load_more_60.png`
- `pt3_03_next_49607_load_more_90.png`（关键：本轮真机复核 60→90）

### Step 5：pt.4 private-user-images JWT CDN 图片渲染

在 pt.1 打开的 `#511` 详情页 body 段里查找 `<img>` 标签（GitHub `user-attachments` CDN，URL 带 JWT）。

widget tree 命中：
- `Image` / `CachedNetworkImage` widget 已渲染出实际图像（`loadingProgress == null`）
- 不是 fallback 蓝链 `Text` 文本

`get_runtime_errors` 关键断言：
- **无** `Image.network failed to load` / `HTTP 401` / `HTTP 403`

**证据**：
- `pt4_01_bettafish_511_body_image_rendered.png`

### Step 6：pt.5 replies 非空嵌套

```
mcp_dart vm_service evaluate
  expression: 'gsySmokeGoDiscussionDetail("666ghj", "BettaFish", 309)'
```

或改走 `#417`（Q&A 通常带 reply 更多）。

widget tree 命中：
- `_buildReplyRow` 实例数 >= 1（`ReplyRow` 或对应 `Widget` 名，取 `discussion_detail_page.dart` 现有实现）
- reply 行相对父 comment 有缩进（`textPreview` 里 reply 行的 `Padding` `EdgeInsets.left` > 父 comment）

**证据**：
- `pt5_01_bettafish_309_reply_row.png` 或 `pt5_01_bettafish_417_reply_row.png`

### Step 7：收尾

- `mcp_dart get_runtime_errors` 拍 `runtime_errors_final.txt`，diff baseline 无新增 Dart 异常
- 补 [evidence/20260909-discussion-verify/README.md](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/20260909-discussion-verify/README.md) 索引所有截图和 widget tree 命中
- [roadmap.md §3.1](file:///d:/workspace/project/gsy_github_app_flutter/docs/00-overview/roadmap.md) pt.1~pt.5 真机验收缺口全部划掉 + ✅ + commit hash
- git add + commit + push

## 完成汇报必填

见 [AGENTS.md 完成汇报三段式](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md)：
- **看代码**：Wave 1 零代码改动（仅新增文档 + evidence）
- **看编译**：不需要 analyze / build_runner（无代码变动）
- **看运行**：DTD URI + 5 条路径 widget tree 命中 + 截图绝对路径 + `runtime_errors_final` 结论

## 反例（禁止）

- ❌ 用 `adb shell input tap` 坐标脚本触发跳转（2026-09-02 拍板）
- ❌ 只截图不看 `widget_inspector`
- ❌ 把"人肉点"当默认路径
- ❌ 用 `flutter install` 装 debug 到真机（会清 SharedPreferences token）
- ❌ 只有截图没有 `runtime_errors` 前后对比
