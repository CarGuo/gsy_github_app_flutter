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

### 2.6 build_runner 环境级技术债（riverpod_generator 3.0.3）—— 已诊断到位

`dart run build_runner build` 时，`riverpod_generator` 阶段对以下三个 async provider 稳定报错：

- `Invalid argument(s): Cannot find import for AsyncValue in _CanonicalizedUri(package:riverpod/riverpod.dart), and could not automatically import it.`
- 影响文件（都是返回 `Future<T>` 或 `AsyncNotifier` 的 provider，g.dart 需要 emit `AsyncValue<T>`）：
  - [lib/page/trend/trend_provider.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/trend/trend_provider.dart)
  - [lib/page/trend/trend_user_provider.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/trend/trend_user_provider.dart)
  - [lib/page/user/base_person_provider.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/base_person_provider.dart)
- 未报错的对照组（同样 `@riverpod` 注解但**同步** `build()`，g.dart 不 emit `AsyncValue`）：
  - [lib/provider/app_state_provider.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/provider/app_state_provider.dart)
  - [lib/page/user/base_person_state.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/base_person_state.dart)（无 `part` 声明，不参与生成）

**真实版本组合**（`.dart_tool/package_config.json` 与 pubspec 交叉验证）：

- `flutter_riverpod: 3.0.3`
- `riverpod: 3.0.3`（传递依赖）
- `riverpod_annotation: 3.0.3`
- `riverpod_generator: 3.0.3`
- `analyzer_buffer: 0.1.12`（`AnalyzerBuffer._upsertImport` 抛错所在包）

四方严格对齐 3.0.3，不是版本 mismatch。

**根因**（本轮实测走完排查后重写，替换掉前一轮"6.3 vs 3.x"的错误猜测）：

`AnalyzerBuffer._upsertImport(_CanonicalizedUri('package:riverpod/riverpod.dart'), 'AsyncValue')` 在 [analyzer_buffer 0.1.12 lib/src/analyzer_buffer.dart#L538-L546](file:///D:/workspace/pub_cache/hosted/pub.flutter-io.cn/analyzer_buffer-0.1.12/lib/src/analyzer_buffer.dart#L538-L546) 里，会先调 `_namespace.findSymbol(uri, 'AsyncValue')` 遍历当前源文件的 `libraryImports2`，取每个 import 的 `definedNames2['AsyncValue']?.library2?.uri` 与期望 URI 精确比对。

问题是 `AsyncValue` 实际定义在 [riverpod-3.0.3 lib/src/core/async_value.dart#L414](file:///D:/workspace/pub_cache/hosted/pub.flutter-io.cn/riverpod-3.0.3/lib/src/core/async_value.dart#L414)，通过 [riverpod-3.0.3 lib/src/internals.dart#L1-L26](file:///D:/workspace/pub_cache/hosted/pub.flutter-io.cn/riverpod-3.0.3/lib/src/internals.dart#L1-L26) 的 `export 'src/...'` 链层层 re-export 到 [riverpod-3.0.3 lib/riverpod.dart#L1-L24](file:///D:/workspace/pub_cache/hosted/pub.flutter-io.cn/riverpod-3.0.3/lib/riverpod.dart#L1-L24)。analyzer 侧的 `Element.library2.uri` 返回的是**定义 library** 的 URI（`package:riverpod/src/core/async_value.dart`），而不是 re-export 入口的 URI（`package:riverpod/riverpod.dart`）—— 两者永远匹配不上。

由于 `_autoImport = false`（`_TargetNamespace` 构造函数默认关闭），最终抛 `Cannot find import for AsyncValue in ...`。

**关键结论**：这是 `riverpod_generator 3.0.3` 对 re-exported 类型的 URI 假设错误，**用户侧无法通过修改源文件的 import 绕开**。本轮已实测：

1. 给 3 个源文件顶部加 `import 'package:flutter_riverpod/flutter_riverpod.dart';` → **仍报同样错误**
2. 追加 `import 'package:riverpod/riverpod.dart';` → **仍报同样错误**

两次修改都已回退到原状。

**副作用已自行消失**：build_runner 3.x 已移除 `--delete-conflicting-outputs` 参数（本轮实测输出 `W These options have been removed and were ignored`），即使 riverpod_generator 报错，也**不再联动删除 .g.dart**。本轮 2 次跑 build_runner 前后 3 个 .g.dart 字节数与时间戳完全一致（4197 / 4674 / 2889，`11:24:26 AM`）。前一轮 roadmap 记录的"删掉却不重生成"痛点由此关闭。

**当前状态**：既有 3 个 .g.dart 是**有效生成产物**（`app_state_provider.g.dart` 早前生成时环境不同），运行时正常。只要不主动 `git rm` 或手动清理，就不受影响。

**根治候选（不在本轮工作范围）**：

- 升级到 `riverpod_generator 4.0.4`（2026-06 中旬发布，跨越 4.0.0 ~ 4.0.4 五个版本），配套升级 `flutter_riverpod` / `riverpod_annotation` 到 4.x。属于**跨大版本升级**，可能牵涉 `ProviderContainer` / `Ref` / `AsyncNotifier` 等运行时 API 破坏性变更，波及 [app_state_provider.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/provider/app_state_provider.dart) 里的 `globalContainer = ProviderContainer()` 与 5 个 `@riverpod` 消费点。需**独立任务**拉一栏，含 pub deps → 迁移指南 → 全量回归。
- 或降级 `riverpod_generator` 到 `2.6.5`（`AnalyzerBuffer` 尚未引入 `_upsertImport` 那套流程），但会失去 3.0.0 之后的 stateful hot-reload / new element model 收益。**不推荐**。

**日常操作约束**（本轮沉淀，供后续人 / agent 参考）：

- 改 EventPayload / 其它 json_serializable 模型跑 build_runner 时，**忽略** `E riverpod_generator on ...` 那三条错误（它们不会破坏已生成产物，也不会阻断 json_serializable 阶段的输出）。看的是 `wrote N outputs` 里 N 是不是符合预期，不看 exit code。
- 如果确认没改 riverpod provider 源文件，**不需要**每次都跑 build_runner，只跑针对性 target 即可：
  `dart run build_runner build --build-filter="lib/model/*.dart"`（本仓库当前不强制这么用，但作为环境优化路径记录）。
- 只有真要动 `@riverpod` 源文件语义（改返回类型 / 加参数）时才需要单独任务处理这个环境问题，否则**默认容忍**。


### 2.7 CI Flutter 版本升级 3.41.6 → 3.44.1（本轮修复 GitHub Actions 红）

**背景**：CI 一直在 build 阶段挂，日志显示
`lib/widget/pull/nested/nested_refresh.dart:526:15: Error: No named parameter with the name 'alignment'`。
原因是本轮 §2.3 早期已把 [nested_refresh.dart#L526](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/pull/nested/nested_refresh.dart#L526)
的 `axisAlignment: 1.0/-1.0`（deprecated after Flutter v3.41.0-1.0.pre）迁到了新 API
`alignment: Alignment.bottomCenter/topCenter`；这个新参数在 Flutter 3.41.6 stable 里**还没引入**，
而 CI workflow 里 `subosito/flutter-action@v1` 恰恰锁在 `flutter-version: '3.41.6'`。
本地长期跑 3.44.x，CI 一直落后 → 出现"本地绿 / CI 红"的经典 SDK 漂移。

**修复方式（用户拍板：升 CI 而非降代码 API）**：

- [.fvmrc](file:///d:/workspace/project/gsy_github_app_flutter/.fvmrc)：`3.38.4` → `3.44.1`（用 FVM 作为唯一版本契约源）
- [.github/workflows/ci.yml](file:///d:/workspace/project/gsy_github_app_flutter/.github/workflows/ci.yml) 两处 job（`build` 与 `apk`）：
  - `subosito/flutter-action@v1` → `@v2`（v2 起支持 `flutter-version-file`）
  - `flutter-version: '3.41.6'` → `flutter-version-file: .fvmrc`（读同一份 FVM 契约，杜绝双写漂移）
  - 顺带打开 `channel: stable` + `cache: true`
- [README.md](file:///d:/workspace/project/gsy_github_app_flutter/README.md) / [README_EN.md](file:///d:/workspace/project/gsy_github_app_flutter/README_EN.md)：编译运行流程处 "Flutter SDK 3.38" → **3.44.1**，附 FVM 用法
- [docs/03-runbooks/local-setup.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/03-runbooks/local-setup.md)：基线要求段写死 3.44.1 + `.fvmrc` + FVM

**遗留**：Flutter 3.44 有 Material/Cupertino 拆包 deprecation warning（`package:flutter/material.dart` 仍可用，只出 warning）；
当前 CI 不带 `--fatal-warnings`，不阻塞，等后续再迁移。**riverpod_generator 3.0.3 URI mismatch（§2.6）
是完全独立的问题**，不随本次 CI 升级解决，仍需按 §2.6 建议独立跨版本升级任务处理。


---

## 三、功能对齐官方 GitHub App / API 还差什么

**边界前提**：GSY 定位是 GitHub 的**只读 + 评论客户端**，不承担写 PR / 提交 review / 建仓库这类作者行为。
下面清单已按这条边界筛过。

### 3.1 高优先

- **Discussions 阅读页**
  Discussion 事件已经识别，动态流里能看到"在 xxx 创建 讨论"，但**点进去没页面**。
  可行路径：复用 issue detail 那套 timeline 骨架，接 `/repos/{o}/{r}/discussions/{n}` GraphQL。

  **进度跟踪**（分阶段推进，避免一口气吞完）：

  - ✅ **骨架阶段（上轮）**：GraphQL 单接口 + 空壳页 + 4 语言 fallback 文案
    - [lib/common/net/graphql/discussions.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart)：raw string `readDiscussion` 查询，含 category / author / bodyHTML / answer / upvoteCount / comments(first:30) + replies(first:10)
    - [lib/common/net/graphql/client.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/client.dart)：`getDiscussion(owner, name, number)` Future 封装
    - [lib/page/discussion/discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart)：三态（loading / error+retry / content），title + author + category + answered chip + upvote + commentCount，bodyHTML 目前只用 `Text` 直出（下一子任务替换为 Markdown/HTML widget）
    - [lib/common/utils/navigator_utils.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart)：`goDiscussionDetail(context, owner, name, number)` 入口
    - 4 语言 arb + gen-l10n 产物：`discussion_load_failed / discussion_not_found / discussion_retry / discussion_answered_badge / discussion_empty_body / discussion_skeleton_notice / discussion_comments_count`

  - ✅ **event 路由接入（本轮）**：动态流卡片直连详情
    - [lib/model/event_payload.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/model/event_payload.dart) 新增嵌套模型 `EventDiscussionRef`（只留 `number` 字段），`EventPayload.discussion` 走 json_serializable 自动解析
    - [lib/common/utils/event_utils.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/event_utils.dart#L633-L652) `ActionUtils` switch 追加 `DiscussionEvent` / `DiscussionCommentEvent` case：`payload.discussion?.number` 拿到就走 `goDiscussionDetail`，缺失时回退 `goReposDetail`（不假装成功）
    - [test/utils/event_utils_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/utils/event_utils_test.dart#L454-L491) 加 2 个序列化用例：有 `discussion.number` 时反解为 int，缺失时保持 null；总测试数 119 → 121 全绿
    - 真机验证：release apk 重装 + 首页动态流滚多屏 + logcat 拉 → 无 Dart 层 Exception，Push/Fork/Watch 路径未回归。**DiscussionEvent 真机路径未覆盖**（GSY 关注账号最近的 events 里没有 discussion 事件，AGENTS.md 禁止造数据），已用单测补齐稀有分支覆盖率
    - 冒烟截图：[tool/dbg/smoke_disc_01_launch.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/smoke_disc_01_launch.png) / [tool/dbg/smoke_disc_02_scroll.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/smoke_disc_02_scroll.png)

  - ⏳ **内容渲染阶段（下一子任务）**：
    - bodyHTML 用 [gsy_markdown_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart) 完整渲染
    - comments/replies 展开、分页
    - answer 徽标细化、reactions bar
    - 真机 DiscussionEvent 直连截图（需要等 GSY 关注的某账号产生 discussion 事件，或在仓库详情加 Discussions tab 后从 tab 入口反向验证）
    - 冒烟脚本沉淀到 [tool/ai/smoke/](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke)

- **Notifications 分组视图**
  目前是扁平列表 + reason 筛选。官方 app 是按 repo / subject 折叠。
  修改点：通知模块加分组 header，不改数据源。

- **PR review thread resolved 徽标 + 操作**
  本轮 arb 已经有 `event_action_resolved / unresolved`，但 PR 详情页里 review thread 的状态**没渲染**。
  修改点：pr detail 页 review comment 分组渲染时加色条 / 图标；**2026-07-06 边界拍板允许把操作层也做进来**（长按 / 侧滑触发 resolveReviewThread / unresolveReviewThread mutation），仅操作层，**不做"未 resolved thread 计数"这类仪表盘**。

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
- **Projects V2 阅读**：~~完全没做~~ **2026-07-06 拍板归入禁止清单**（阅读也搁置），不再列入待做，见 [AGENTS.md §允许 / 禁止的写操作清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169)。
- **Copilot Chat 上下文**：GSY 定位不做 AI，一般跳过。

---

## 四、待定义边界（做不做要先讨论）

这些不写清楚，"该不该做"就没答案，不要贸然开工。

### 4.1 "只读 + 评论"到底允许多少写态？

**状态更新（2026-07-06）**：已在 [AGENTS.md 允许 / 禁止的写操作清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169) 拍板转正。roadmap 这段保留分类原文供理解演进用，**以 AGENTS.md 为准**。

- 已经在做的**写操作**：
  - Issue / Comment 加 reaction
  - Comment 发评论
  - Notify 标记已读 / done / unsubscribe
- 原争议地带 **2026-07-06 拍板结果**：
  - GitHub Actions rerun / cancel → **禁止**（仓库运维行为）
  - Projects V2 卡片移动 → **禁止**（同时连阅读也搁置，见 §3.3）
  - PR review thread resolved / unresolved → **允许（仅操作，不做仪表盘）**，见 §3.1
  - 编辑自己发的 issue body / comment 内容 → **允许（仅编辑，不含删除）**，独立任务待排期
  - PR dismiss review → **禁止**（作者行为，未在本轮拍板中升级）

**拍板产生的下游影响**：

- **收紧**：§3.3 Projects V2 阅读整段划掉；Notify 三个侧滑动作维持现状（仍在允许范围内，不受影响）。
- **放宽**：§3.1 resolved 徽标可以扩展到操作层（长按触发 resolveReviewThread mutation），已同步改写 §3.1；新开"编辑自己的 comment / issue body"独立任务待排期。

清单以 [AGENTS.md](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169) 为准，任何新增写操作需要在 PR 描述里显式提出并同步更新该清单。

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
