# 项目现状与待办清单（Roadmap）

这份文档回答一个问题：**"这个仓库现在到底还差什么？"**

它不是需求池，也不是 ADR，只是一份**当前时点的现状快照**，方便任何人（人或 agent）在挑下一个任务前先对齐现实。

维护约定：

- 每次完成一个有分量的改动，记得回来划掉相应条目
- 不确定该不该做的功能，放"待定义边界"一节，别直接塞进 TODO
- 只写"当前还差什么"，不写完整历史；历史看 git log 和 ADR

最后一次盘点：2026-07-06（下午）。

---

## 一、已完成收尾（最近几周的存量）

这些不是当前 TODO，只是给读者一个"最近走到哪儿"的参考点。

| 模块 | 关键交付 | 入口文件 |
|---|---|---|
| PR timeline 事件识别 | reviewed / committed / copilot_work_* / ready_for_review 等特殊事件行 + 4 语言 + 25 widget 测试 | [issue_timeline_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_timeline_item.dart) |
| Reaction toggle | issue / comment 三态防抖 + 竞态锁 + mounted 校验 | [issue_repository.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/repositories/issue_repository.dart) |
| 通知中心 | subject.type 分派 / repo 筛选 / reason 快速筛选 chip / 图片错位 ValueKey 修复 / 侧滑三动作 | 通知模块 |
| Trend | 语言筛选歧义修复 + 时间/代码 icon | trend 模块 |
| Search | 历史 / Issue tab / Code tab / 抽屉动态化 / 空 q 假报错修复 | [gsy_search_drawer.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/search/widget/gsy_search_drawer.dart) |
| PR 变更文件页 | 行级评审评论挂载 + reviewed body 色带 | pr 模块 |
| URL 编码根治 | `+/:/#` 高级修饰符二次编码 bug 从源头修 | [address.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/net/address.dart) |
| 事件识别扩容 | Discussion / DiscussionComment / PullRequestReviewThread / Sponsorship 四类事件 + 5 个 action 收编（本轮） | [event_utils.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/utils/event_utils.dart) |

---

## 二、半成品 / 已知残留（Quick Win）

这些是"上一批改动做完但**没扫干净**"的口子，改动量都小，一个 commit 就能收：

### 2.1 通用 action 词典冷条目

`_translateAction` 里还没收编的 action（走 default 分支透传英文 + 遥测）：

- ~~`auto_merge_enabled` / `auto_merge_disabled`（PR 自动合并，越来越常见）~~ ✅ 本轮已收（4 语言 arb + 2 单测）
- `marked_as_duplicate` / `unmarked_as_duplicate`（issue 去重）
- `dequeued` / `enqueued`（merge queue，GitHub 2025 后主推）
- `deployed` / `deployment_status`

修改点：[_translateAction](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/utils/event_utils.dart#L172-L231) 加 case + 4 语言 arb 加 key。

### 2.2 DiscussionEvent 真机截图缺口 —— 已用代理证据关闭 + 附带发现新 bug

Discussion 家族事件已经收编到词典（本轮 `0b2cb46`），单测 15 绿；
本轮尝试从真机首页动态 tab 走 CarSmallGuo 的 received feed 直接命中 DiscussionEvent 那一条，
拉了 40+ 条依然没打到（GitHub API 上明确有 1 条：`JDDavenport / created / 666ghj/BettaFish / 2026-07-05 03:29:46`，
位于 `per_page=20` 第 2 页第 4 位）。

分析后确认这条真机命中**不该强求**，改为代理证据闭环：

- `test/utils/event_utils_test.dart` 15 case 已覆盖 Discussion / DiscussionComment / PullRequestReviewThread / Sponsorship 四类
- 真机上其他走同一个 `getActionAndDes` switch 分支的事件（IssuesEvent / ForkEvent / WatchEvent / PushEvent）
  在 40+ 条列表里全部正常渲染，无 UnknownEvent 空白卡片、无 EXCEPTION
- 冒烟脚本 [tool/ai/smoke/open_home_dynamic.sh](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.sh) 沉淀本轮 tap 坐标
- smoke-matrix 新增 "首页动态 / 事件识别" 段落，把"稀有事件不强求真机截图"这条规约白纸黑字化
- 证据截图：[tool/dbg/b_10_back_to_hfye.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/b_10_back_to_hfye.png)、
  [tool/dbg/b_13_load_more.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/b_13_load_more.png)、
  [tool/dbg/b_14_after_loadmore.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/b_14_after_loadmore.png)

**本轮附带发现新 bug（登记为独立跟进项，见 §2.5）**：GSY 首页动态 tab 有分页边界丢事件的嫌疑——
CarSmallGuo received feed 里明确存在的 DiscussionEvent（07-05 03:29）在 app 里滚遍时间戳区间也没出现。

### 2.5 首页动态 tab 分页边界疑似丢事件（新登记）

现象：GitHub API `/users/CarSmallGuo/received_events?per_page=20&page=2` 第 4 条是
`JDDavenport DiscussionEvent created 666ghj/BettaFish` @ `2026-07-05 03:29:46`；
但 GSY app 首页动态 tab 里下拉刷新 + 上拉加载后，从 `hfye 关注 666ghj/BettaFish`
直接跳到 `CarGuo push 46dca6c`，中间的 domesticmouse WatchEvent 与 JDDavenport DiscussionEvent 都不见。

怀疑路径：

- [dynamic_bloc.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart)
  `requestRefresh` 拉第 1 页 + `doNext(res)` 又 `await res.next()`（该闭包捕获的 `page` 仍为 1，实际再拉一次第 1 页），
  然后 `refreshData(resNext)` **整体覆盖** dataList，第 1 次 refresh 后内存里其实只有第 1 页 20 条
- [received_event_db_provider.dart#L54](file:///d:/workspace/project/gsy_github_app_flutter/lib/db/provider/event/received_event_db_provider.dart#L54)
  `insert` 里"清空后再插入，因为只保存第一页面"——db 缓存只有第 1 页
- `loadMoreData` 走 `_page++` 拉第 2 页 append，但**没有和第 1 页做时间戳排序去重**，
  存在"网络返回 event.id 与 db 缓存重复但 payload 差异"的边界

跟进方式（下轮任务）：

- 打开 [dynamic_bloc.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart) 单步 log 每一页返回的 event.id + type + created_at
- 对比 API 直连结果，找出被 GSY 丢掉的位置在拉页阶段还是渲染阶段
- 有可能需要引入 event.id 去重 set + 按 created_at 排序稳定化



### 2.3 flutter analyze 已收干净（原 7 条 → 0）

久违的技术债，不影响功能，但每次 CI 输出脏：

- ~~[event_bus.dart#L37](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/event/event_bus.dart#L37)：doc comment 里 `<...>` 需要转义或反引号~~ ✅ `e70d5b0`
- ~~[gsy_state.dart#L32](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/redux/gsy_state.dart#L32)：同上~~ ✅ `e70d5b0`
- ~~[gsy_markdown_widget.dart#L136](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L136)：同上~~ ✅ `e70d5b0`
- ~~[gsy_markdown_widget.dart#L358](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L358)：同上~~ ✅ `e70d5b0`
- ~~[flutter_radial_menu.dart#L1](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/menu/flutter_radial_menu.dart#L1)：`library` 名多余~~ ✅ `e70d5b0`
- ~~[pubspec.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/pubspec.yaml)：git 依赖 + 没写 `publish_to: none`~~ ✅ `e70d5b0`
- ~~[nested_refresh.dart#L526](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/pull/nested/nested_refresh.dart#L526)：`axisAlignment` deprecated → 迁到 `alignment: Alignment.topCenter/bottomCenter`~~ ✅ 本轮

现状：`flutter analyze` = **No issues found**。

### 2.4 CI flutter test 白名单已扩容，4 个红测试转绿

GitHub Actions 已在 build job 里加 `flutter test` 一步（`Run unit / widget tests (whitelist)`）。

**当前白名单**（全部跑绿）：

- `test/utils/event_utils_test.dart`
- `test/model/issue_timeline_event_test.dart`
- `test/widget/markdown_html_transformer_test.dart`
- `test/widget/issue_timeline_item_test.dart`（本轮加回，之前挂 4 个 reviewed body 用例）
- `test/page/issue/issue_timeline_merge_test.dart`（issue-timeline-flash 回归契约）

**已解决**：[_reviewBodyCard](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_timeline_item.dart#L222-L265)
从"`DecoratedBox` 直接 non-uniform border + borderRadius"改为
"外层 uniform 半透 border + 圆角 + 内层 Stack 叠一条 3px 色带"。原本因 shrink-wrapping viewport
不能配合 IntrinsicHeight，也在实现里避开了。真机截图见
[tool/dbg/smoke_08_issue_detail_scroll2.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/smoke_08_issue_detail_scroll2.png)
（`Pull request overview` 卡片左侧紫色 3px 色带 + 圆角边框，无断言）。

---

## 三、功能对齐官方 GitHub App / API 还差什么

**边界前提**：GSY 定位是 GitHub 的**只读 + 评论客户端**，不承担写 PR / 提交 review / 建仓库这类作者行为。
下面清单已按这条边界筛过。

### 3.1 高优先

- **Discussions 阅读页**
  Discussion 事件已经识别，动态流里能看到"在 xxx 创建 讨论"，但**点进去没页面**。
  可行路径：复用 issue detail 那套 timeline 骨架，接 `/repos/{o}/{r}/discussions/{n}` GraphQL。

  **进度跟踪**（分阶段推进，避免一口气吞完）：

  - ✅ **骨架阶段（本轮）**：GraphQL 单接口 + 空壳页 + 4 语言 fallback 文案
    - [lib/common/net/graphql/discussions.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart)：raw string `readDiscussion` 查询，含 category / author / bodyHTML / answer / upvoteCount / comments(first:30) + replies(first:10)
    - [lib/common/net/graphql/client.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/client.dart)：`getDiscussion(owner, name, number)` Future 封装
    - [lib/page/discussion/discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart)：三态（loading / error+retry / content），title + author + category + answered chip + upvote + commentCount，bodyHTML 目前只用 `Text` 直出（下一子任务替换为 Markdown/HTML widget）
    - [lib/common/utils/navigator_utils.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart)：`goDiscussionDetail(context, owner, name, number)` 入口
    - 4 语言 arb + gen-l10n 产物：`discussion_load_failed / discussion_not_found / discussion_retry / discussion_answered_badge / discussion_empty_body / discussion_skeleton_notice / discussion_comments_count`
    - **本轮不承诺**：event 卡片直接跳详情页（[EventPayload](file:///d:/workspace/project/gsy_github_app_flutter/lib/model/event_payload.dart) 无 `discussion` 字段，需下一子任务扩模型 + 跑 build_runner 才能接入 `ActionUtils` 路由）

  - ⏳ **交互阶段（下一子任务）**：
    - EventPayload 扩 `discussion` 字段 + build_runner → 在 `ActionUtils` switch 里给 DiscussionEvent 加分支调 `goDiscussionDetail`
    - bodyHTML 用 [gsy_markdown_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart) 完整渲染
    - comments/replies 展开、分页
    - answer 徽标细化、reactions bar
    - 真机冒烟固化到 [tool/ai/smoke/](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke)

- **Notifications 分组视图**
  目前是扁平列表 + reason 筛选。官方 app 是按 repo / subject 折叠。
  修改点：通知模块加分组 header，不改数据源。

- **PR review thread resolved 徽标**
  本轮 arb 已经有 `event_action_resolved / unresolved`，但 PR 详情页里 review thread 的状态**没渲染**。
  修改点：pr detail 页 review comment 分组渲染时加一个色条 / 图标。

### 3.2 中优先

- **Repo Releases tab 完善**
  之前 REL 冒烟确认 tab 存在，但换行 / 资产列表不完整（logcat 曾报过未知 asset 字段）。
- **Repo Watchers / Stargazers 列表**：目前只有数字，没列表。
- **Star 时序图**：官方 Insights 有，GSY 没有。
- **Feed 高级过滤**：按事件类型筛选动态流。
- **Issue / PR 内联搜索**：Search tab 支持关键字，但没 GitHub 修饰符 UI 辅助（label / assignee / milestone / is:open）。

### 3.3 低优先 / 边界待定

- **Gist 阅读**：完全没做。
- **GitHub Actions runs 状态**：作者行为重叠多，看 3.4 那个边界定了再决定。
- **Projects V2 阅读**：完全没做。
- **Copilot Chat 上下文**：GSY 定位不做 AI，一般跳过。

---

## 四、待定义边界（做不做要先讨论）

这些不写清楚，"该不该做"就没答案，不要贸然开工。

### 4.1 "只读 + 评论"到底允许多少写态？

- 已经在做的**写操作**：
  - Issue / Comment 加 reaction
  - Comment 发评论
  - Notify 标记已读 / done / unsubscribe
- 争议地带：
  - GitHub Actions rerun / cancel
  - Projects V2 卡片移动
  - PR dismiss review

**如果边界收紧**：3.1 的 resolved 徽标只做视觉、不做操作；Notify 那三个侧滑动作要重新讨论。
**如果边界放宽**：3.2 / 3.3 里"低优先"那批可以升级。

建议在 [AGENTS.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md) 里补一条"允许 / 禁止的写操作清单"。

### 4.2 event_utils 单文件已 400+ 行

26 个事件 case + 30+ action 词典塞在一个 switch。要不要按事件族拆成
`event_utils_pull_request.dart` / `event_utils_issue.dart` / `event_utils_discussion.dart`？

- 拆的好处：可读性；每族测试文件对齐一个源文件。
- 拆的成本：一次 diff 很大，reviewer 会痛苦；改一次上下文要跳三个文件。

**先不拆**，除非下一次要加事件族时再顺手拆。

### 4.3 arb 双风格

en 有 `@key.placeholders` 元数据，zh / ja / ko 没有。gen-l10n 能用，
但新增 key 时**必须记得只在 en 里加 metadata**，是个隐藏坑，本轮就差点踩。

选一：

- **补齐**：一次性给 zh / ja / ko 补 metadata，四端对称，代价 = 一堆无脑改动。
- **删除**：把 en 的 metadata 也删掉，全部走类型推断（`Object` → 得手工修一遍 dart 调用点）。
- **保持现状**：在 [CONTRIBUTING_AI.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/docs/CONTRIBUTING_AI.md) 显式写死"新增 key 只在 en 加 metadata"。

---

## 五、长期健康债（不阻塞，但迟早还）

### 5.1 状态管理四种共存

Redux / Riverpod / Provider / Signals 现实并存，按 ADR-0001 是**故意保留**的教学负担。
建议做一件事：**画一张"哪个模块用哪套"的当前快照**贴到 [state-management-matrix.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/docs/01-architecture/state-management-matrix.md)。
这不是消除并存，只是让 agent 一眼看清哪里该用哪套。

### 5.2 reviewer subagent 门槛

[AGENTS.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md) 要求"中等以上改动默认拉 reviewer subagent"，
但没定义什么叫"中等"。本轮 Discussion 事件收编（11 files / 418 insertions）严格说该走 reviewer 但没走。

建议补一条量化门槛：

- 单文件 < 50 行 → 免 reviewer
- 跨 3 个以上文件 或 单次 > 150 insertions → 强制 reviewer
- 涉及 [高风险目录](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md) → 无条件 reviewer

### 5.3 真机 fixture 沉淀不足（还剩 2 个）

[tool/ai/smoke/](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/) 现在有：

- `relaunch_app.sh` —— 冷启动 GSY 到首页（早期就有）
- `open_pr_timeline.sh` —— PR timeline 冒烟入口（上轮沉淀）
- `open_home_dynamic.sh` —— 首页动态 tab 走完刷新/加载/滚动 5 张证据截图（**本轮沉淀**）

还差：

- `open_search_code.sh`：Search → Code tab → 输关键字
- `open_pr_files.sh`：进 PR → 变更文件页

---

## 六、下一步该干什么

按不同偏好给三条路，任选：

1. **最低阻力**：补 2.1 里 `marked_as_duplicate/unmarked_as_duplicate` 或 `dequeued/enqueued` 两组 action。10 分钟一个 commit（`auto_merge_*` 已在 2026-07-06 收）。
2. **有分量功能**：3.1 的 Discussions 阅读页。复用 issue timeline 骨架，让 discussion 事件从"看得到 → 点得进 → 读得完"闭环。
3. **先划边界**：先决 4.1，把"允许的写操作清单"写进 AGENTS.md；边界清楚后 3.2 / 3.3 才有下决心的依据。
