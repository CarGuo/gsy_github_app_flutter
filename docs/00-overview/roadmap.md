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

#### 2.5.1 本轮尝试 & 失败复盘（2026-07-13）

**尝试的方向**：把 [refreshData](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart#L83-L114) 从"整体覆盖 dataList"改成"以 incoming 打头 + 保留旧 dataList 里不在 incoming id 集合的尾部元素"，试图让下拉刷新不清空 loadMore 累加的 page=2/3。

**为什么失败（reviewer F1 拍板）**：与 [EventRepository.getEventReceived](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/repositories/event_repository.dart#L11-L50) 的 db→net 双阶段模型冲突：

1. [requestRefresh](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart#L14-L24) 会**连续调两次 refreshData**：先 `refreshData(res)`（db 阶段），再 `await doNext(res)` → `refreshData(resNext)`（net 阶段）。
2. 合并语义下每次都把 incoming 塞到 old 前面 → dataList **单调膨胀**，用户反复下拉 → 长度会累积到实际关注账号一段时间内的**所有** received event。
3. 尾部老 event 污染 [loadMoreData](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart#L122-L148) 的 seen 集合 → 用户上拉 page=2/3 时，与老尾部时间段重叠的新事件会被判为重复丢弃 → **"分页边界丢事件"症状从 page1↔page2 平移到 page2↔page3+**，并没有真正消失。
4. `bug25_fixed/` 里的截图看似"深段数据保留"，实际证明的是 dataList 膨胀，不是 §2.5 描述的 JDDavenport DiscussionEvent 真的回到了 UI。

修改已 `git checkout` 撤回，本地状态回到 §2.5 未修状态。

#### 2.5.2 下一轮真正的调研路径（reviewer F6 + roadmap 三条怀疑合并）

按可能性从高到低排：

- **[高] `doNext` 里 `res.next()` 闭包捕获的 `page` 恒为 1**：[event_repository.dart#L18-L38](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/repositories/event_repository.dart#L18-L38) `next()` 是在 `getEventReceived(page: 1)` 时创建的闭包，闭包捕获的 `page` = 1。[dynamic_bloc.dart#L48-L56](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart#L48-L56) 里 `await res.next()` 相当于**再拉一次 page=1**，而非"翻到下一页"。这条要么修 `next()` 让它带 `page+1`，要么直接删掉 doNext 分支（db 阶段就是 page=1，doNext 只是刷新一下"真实的 page=1"就够了，不应把结果当第 2 页用）。
- **[中] `loadMoreData` 依赖 `dataList` 做 id 去重，但没做 created_at 兜底稳定排序**：GitHub `received_events` 是持续变化的流；两次请求间新事件涌入，会导致 page=N 尾部 event.id 在 page=N+1 头部再次出现（重复），也会导致 page=N+1 里含**已在 page=N 边界外**但时间比 page=N 尾还老的事件被裹进来。当前 loadMoreData id 去重能挡住第一种；第二种目前没保护但**观察到的丢失现象**（JDDavenport DiscussionEvent 从 UI 消失）不是这条能解释的——它本来就在 page=2 第 4 条位置。
- **[待验证] loadMoreData 处理层实际把 page=2 的数据全部塞进 dataList，但 UI 渲染层因某种原因跳过了 JDDavenport DiscussionEvent**：可能是 EventItem/EventViewModel 对 DiscussionEvent 的处理缺失或抛异常被 catch 吞掉。这条**需要真机 log** 确认。

**首要动作（下一轮先做这个）**：

1. 在 [dynamic_bloc.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/dynamic/dynamic_bloc.dart) 里加**只在 debug build 生效**的 debugPrint，输出：
   - `requestRefresh` 完成后 dataList 的所有 `id / type / created_at`
   - `requestLoadMore` 完成后 dataList 新增段的 `id / type / created_at`
2. 真机跑 debug build，在 CarSmallGuo 账号下做 refresh + loadMore(page=2)，对比 `curl /users/CarSmallGuo/received_events?per_page=20&page=2`。
3. 判断丢事件发生在**拉页阶段**（bloc 层 dataList 就没有）还是**渲染阶段**（bloc 层有但 UI 没显示）。
4. 拿到结论后再决定改哪层，禁止在没证据的前提下再动 refreshData。

**禁止**：

- ❌ 在没有 debug log 证据前，再动 `refreshData` / `loadMoreData` 语义
- ❌ 用真机截图"看数据在不在"当验证——`hfye 关注 666ghj/BettaFish` 与 `JDDavenport DiscussionEvent` 时间戳相近，肉眼滚很难判断是否真的丢
- ❌ 复用本轮 `bug25_fixed/` 目录的证据（改动已撤回，证据无效）



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

  - ✅ **内容渲染阶段 + 仓库详情 tab（2026-07-20 拓宽 → 2026-07-27 主体完成）**：
    - **本轮范围拓宽拍板**：只做详情页内容渲染不够——GSY 生态里没有 discussion 事件源（见下方 fixture 探针结论），必须在仓库详情页新增 Discussions tab 反向入口，才能真机走通"列表 → 详情"完整路径。
    - ✅ 详情页 bodyHTML 用 [gsy_markdown_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart) 完整渲染（骨架阶段代码里就是 Markdown widget，roadmap 旧文案"Text 直出"过时，此处更正）
    - ✅ **详情页 comments/replies 列表 + 分页**（2026-07-27 `bb96480`）：
      * [discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart)：header + body 下方新增 `_buildCommentsSection` / `_buildCommentCard` / `_buildReplyRow` / `_buildLoadMoreFooter`，一级 comment 走 `GSYMarkdownWidget` 渲染 bodyHTML，replies 平铺前 3 条 + "还有 N 条回复"尾巴
      * [discussion_comments_paging.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_comments_paging.dart)：`DiscussionCommentsPage` 容器 + `pickCommentsPage`（防御式提取：空 endCursor 归 null / Map<dynamic,dynamic> 规范化）+ `mergeCommentsPage`（尾部追加、pageInfo/totalCount 用新页）
      * [graphql/discussions.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart)：新增 `readDiscussionCommentsPage(first, after)` 变体，字段与 `readDiscussion.comments` 完全对齐
      * [graphql/client.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/client.dart)：`getDiscussionCommentsPage`（fetchPolicy=noCache 走真实分页）
      * `hasNextPage=true` 展示"加载更多"按钮，点击 `_loadMore` 追加；`hasNextPage=false` 展示"没有更多评论了"；失败展示重试
      * i18n 补 `discussion_comments_empty / discussion_comments_load_more / discussion_comments_load_more_failed / discussion_comments_no_more / discussion_comments_reply_more_hint` 5 key ×4 语言
      * [test/page/discussion/discussion_comments_paging_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/discussion/discussion_comments_paging_test.dart) 9/9 绿：`pickCommentsPage` 7 case（空/缺字段/类型错/正常/pageInfo 缺/空 endCursor/规范化）+ `mergeCommentsPage` 2 case
      * 真机验证：`BettaFish #522`（1 评论）+ `#511`（3 评论含 @mention + 代码块）在 Android 33 zh 8.1.0 上单卡/多卡/footer 空态命中，无 Dart 侧 Exception，证据落 `tool/dbg/discussion_comments_smoke/16_discussion_522.png` / `17_discussion_522_scroll.png` / `19_discussion_511.png` / `22_discussion_511_s5.png`
    - ✅ **仓库详情页新增 Discussions tab**（`b0e4042`）：入口条件 `repository.has_discussions=true`，无则**不显示 tab**（不显示空态，避免误导用户去点）
    - ✅ 冒烟脚本沉淀 [tool/ai/smoke/open_repo_discussions_tab.sh](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_repo_discussions_tab.sh)（首页 → 搜索 → 仓库 → 讨论 tab → 详情，链路可复现）
    - ⚠️ private-user-images JWT CDN 图片渲染硬化（`6c697cc` → `b762edf` → `a60f884`）—— 详情页 markdown 图片链路已改 `errorBuilder` + 保留 JWT 签名；2026-07-27 真机验收发现 8.1.0 apk #511 body 段图片以蓝链文本呈现（`imageBuilder` 未被触发），排查确认两条独立 bug 路径：`<a><img></a>` HTML 结构被 label 转义（`b762edf` 已修）+ `[![alt](img)]\n(href)` 换行断开导致 CommonMark 判为未闭合 link（`a60f884` 已修）。**代码层两条路径均已修复且单测覆盖**，真机验收挪到下一轮（需先解决 fixture 设备旋转 override 问题，详见 §3.1 剩余分支 pt.4）
    - ⚠️ **本轮已知运行时缺口**（不糊，全部沉淀成 §3.1 剩余分支）：
      * loadMore 分支：BettaFish 讨论 comments ≤30 一页返回完，`hasNextPage=true` 真机上没自然触发
      * replies 非空嵌套：本轮 fixture 命中的 comments totalReplies=0，`_buildReplyRow` 未在真机截图上显式命中
      * private-user-images 图片：代码层两条 bug 路径已修（`b762edf` + `a60f884`），真机复核挪到下一轮 milestone，前置依赖是 fixture 设备旋转排查，见 §3.1 剩余分支 pt.4

  - ⏳ **§3.1 剩余分支（下一子任务）**：
    1. **reactions bar**（`👍/🎉/❤️/🚀/👀/😄/😕/👎` 8 类）：Discussion 本体 + 每条 comment 都要挂
       - ✅ **2026-07-28 数据层 + UI 层已完成（真机验收待下一轮，前置依赖同 pt.4 旋转 override）**：
         - GraphQL：[readDiscussion / readDiscussionCommentsPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart) 已补 `reactionGroups { content viewerHasReacted reactors { totalCount } }`；新增 [mutationAddReaction / mutationRemoveReaction](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart) 与 [addReactionToSubject / removeReactionFromSubject](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/client.dart) 包装函数
         - 纯 Dart 模型 & 函数：[reaction_groups.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/reaction_groups.dart) 提供 `kReactionContents` / `kReactionEmoji` / [ReactionSummary](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/reaction_groups.dart#L56-L96) / [pickReactionGroups](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/reaction_groups.dart#L108-L133)（GraphQL 返回规范化，宽容处理未知枚举 / null / 类型错）/ [applyLocalReactionToggle](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/reaction_groups.dart#L152-L193)（乐观 toggle，幂等，遵循 [kReactionContents](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/reaction_groups.dart#L23-L32) 顺序）
         - 单测：[test/page/discussion/reaction_groups_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/discussion/reaction_groups_test.dart) 覆盖 14 case（6 规范化分支 + 8 增量推进分支），`flutter test test/page/discussion/reaction_groups_test.dart` 全绿
         - UI：[discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) 新增 [_buildReactionsBar / _buildReactionChip / _buildAddReactionButton / _openReactionPicker](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L914-L1136)，挂到 discussion body card 底栏与每条 comment card 底栏（reply 层本轮不加，避免密集）；`count>0` 分组以 chip 形式展示，`viewerHasReacted` 用 primaryColor 描边 + 淡背景高亮；尾部 `+` 与长按 bar 都触发底部 sheet 8 类 chip 选择器
         - 交互：点击 chip 走 [_toggleReaction](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L825-L880)：inflight guard（同一 `subjectId` 并发一律丢弃）→ 乐观 `applyLocalReactionToggle` → 走 mutation → 成功用返回的 `reactionGroups` 覆盖 / 失败回滚到调用前快照并弹 SnackBar（走 `discussion_reaction_failed` 文案）
         - i18n：[app_en.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/l10n/app_en.arb) / [app_zh.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/l10n/app_zh.arb) / [app_ja.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/l10n/app_ja.arb) / [app_ko.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/l10n/app_ko.arb) 四份 ARB 同步新增 `discussion_reaction_add` / `discussion_reaction_login_required` / `discussion_reaction_failed` / `discussion_reaction_a11y` + 8 类 emoji a11y label（`reaction_thumbs_up` … `reaction_eyes`），`flutter gen-l10n` 已重跑
         - 静态：`flutter analyze lib/page/discussion/discussion_detail_page.dart` `No issues found!`
       - 写操作对齐 [AGENTS.md 允许清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169)：加 / 取消 reaction 允许；本轮 mutation 只走 `addReaction` / `removeReaction`，没有 create/delete discussion 之类越界动作
       - **真机验收缺口（挪到下一轮 milestone，与 pt.4 共享同一前置：fixture 设备旋转 override 排查）**：
         * fixture 走 [BettaFish #511](https://github.com/666ghj/BettaFish/discussions/511)（👍30🎉11 现成）+ [#417](https://github.com/666ghj/BettaFish/discussions/417)（Q&A + answered + 需要新增 reaction 试探 add 分支）
         * 关键证据要求：点击已有 chip count-1 截图 + 点击未 react chip count+1 截图 + 长按弹底部 sheet 全 8 类截图 + `logcat -d -s flutter` 空异常
         * 未登录（无 gho\_ token）分支：本轮走 mutation 失败 SnackBar，不做前置 login gate；真机验收若要覆盖需在拔掉 token 场景下再抓一次截图
    2. **answer 徽标细化 + author self-answer + bot 评论徽标 + `[deleted]` 边界 + release-linked footer**
       - fixture 已就绪：`#417`（answered + bot + self-answer + 嵌套 reply）/ `#697`（deleted 404）/ `#511`（release footer）
       - ✅ **2026-07-28 UI 层完成（真机验收挪下一轮 milestone，与 pt.1/pt.4 共享同一前置：fixture 设备旋转 override 排查）**：
         - GraphQL：[readDiscussion / readDiscussionCommentsPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/graphql/discussions.dart) 在 `discussion.author` / `answer.author` / `comment.author` / `reply.author` 全部补 `__typename`，作为 Bot 判定的唯一权威依据（GitHub GraphQL 保证 `Bot`/`User`/`Organization`/`Mannequin` 四值）；`answer { id author { login __typename } }` 支撑 self-answer 判定
         - UI：[discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) 增：
           * `selfAnswered` 计算（answered=true && `authorLogin!=null` && `authorLogin==answerAuthorLogin`，任一 login null 走 ghost 分支不误命中），header answered chip label 切成 `discussion_answered_by_author_badge`
           * [_isBotAuthor](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) / [_buildBotBadge](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart)：`__typename == 'Bot'` 时在 [_buildCommentCard](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) 与 [_buildReplyRow](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) author 名字后挂橙色 chip，与绿色 answer chip 视觉隔离
           * `[deleted]` 兜底：`author == null` 且 `bodyHTML` 为空时改用 `discussion_comment_deleted_body`（"该评论已被删除"），仍有内容时保持渲染 body（GitHub 允许 body 保留但 author 消失）
         - i18n：4 份 ARB 新增 `discussion_answered_by_author_badge` / `discussion_comment_bot_badge` / `discussion_comment_deleted_body`；`flutter gen-l10n` 已重跑
         - 静态：`flutter analyze` 全仓 `No issues found!`；`flutter test test/page/discussion` 35/35 全绿（复用既有单测，UI 侧改动无新 model 单测）
         - 写操作：本轮无 mutation，仅新增 GraphQL 读字段与 UI 分支，严格对齐 [AGENTS.md 允许清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169) 只读约束
       - **真机验收缺口（挪到 pt.4 旋转 override 之后）**：`#417` 走 answered + self-answer + bot chip + 嵌套 reply 截图，`#697` 走 deleted body 截图；release-linked footer 卡真机截图与 pt.1/2/4 一并做
       - ✅ **2026-07-28 增量：release-linked footer 独立卡片已落地**（原本挂在下一 milestone，本轮探针到真实 HTML 结构后前置到 pt.2 尾巴一起做完）：
         - 探针实测（gh cli 未登录时改用 `Invoke-WebRequest` 拉 BettaFish #511 discussion HTML 页面，抓 [build/smoke/disc_511_page.html](file:///d:/workspace/project/gsy_github_app_flutter/build/smoke/disc_511_page.html) 全量 324KB，line 1619 命中真实 footer 结构）：`<hr><em>This discussion was created from the release <a href="https://github.com/{owner}/{repo}/releases/tag/{tag}">{title}</a>.</em>`，真实 fixture tag=`v3.0.0`，title 是中文"微舆v3.0.0"
         - 纯 Dart 抽取器 [release_footer.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/release_footer.dart)：提供 [ReleaseFooterInfo](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/release_footer.dart#L28-L57) 值模型 + [extractReleaseFooter](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/release_footer.dart#L59-L96) 抽取函数，返回 `(strippedBody, info?)`；正则保守约束（`<hr>` 自闭合 / caseInsensitive / 允许前后空白与换行 / href 必须命中 `/releases/tag/{tag}` 形态 / title 不含 `<` 避免吞下一个标签 / footer 必须在 body 末尾，中途出现的 releases-tag 链接不吞）；HTML entity 只做 5 项最小解码避免引依赖
         - UI 接入 [_buildBodyCard](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L469-L521) + [_buildReleaseFooterCard](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L523-L585)：body 段走 `extractReleaseFooter` 抽离，剩余 HTML 交 markdown；footer 独立成 [GSYCardItem](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_card_item.dart) 卡（`local_offer_outlined` 图标 + `discussion_release_footer_title` 提示 + `info.title` 加粗标题 + `info.tag` primaryColor chip + `chevron_right`），整卡 InkWell 走 [NavigatorUtils.goGSYWebView](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 打开 release 网页，复用 header "查看 GitHub" 一致的出站入口
         - 单测 [test/page/discussion/release_footer_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/discussion/release_footer_test.dart) 覆盖 15 case（4 基础命中 + 3 href/tag 抽取分支 + 7 未命中/边界 + 1 值语义），含真实 BettaFish #511 fixture 形态与"多个 releases-tag 链接只吞尾部"这条关键保守分支
         - i18n：4 份 ARB 新增 `discussion_release_footer_title`（zh"关联的 Release" / en"Linked release" / ja"紐付いた Release" / ko"연결된 Release"）；`flutter gen-l10n` 已重跑
         - 静态：`flutter analyze` 全仓 `No issues found!`；`flutter test test/page/discussion` 50/50 全绿（35 原有 + 15 新增）
         - 真机验收仍挪到与 pt.1/2/4 共同前置的下一轮 milestone，`#511` 就是这条 UI 分支的天然 fixture
    3. **loadMore 真机验收**：BettaFish 讨论区当前 comments ≤30，`hasNextPage=true` 需换 fixture 到 `vercel/next.js` 或 `expo/expo` 里挑一条 >30 comments 的 discussion（对照组 fallback，需要在 PR 描述里显式提出后再落到 fixture 表）
    4. **private-user-images 图片真机验收（2026-07-27 已验：两条 bug 路径均已代码层修复，真机验收挪到 fixture 设备旋转排查后的下一轮 milestone）**：
       - 已在 8.1.0 apk（含 `6c697cc`）上跑通 #511 body 段截图（[37_disc_511_top.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_comments_smoke/37_disc_511_top.png) / [38_disc_511_scroll1.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_comments_smoke/38_disc_511_scroll1.png) / [39_disc_511_scroll2.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_comments_smoke/39_disc_511_scroll2.png)），logcat 无 `Image.network failed` 记录（[40_logcat_pid.txt](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_comments_smoke/40_logcat_pid.txt) 只 69 字节的 gralloc 噪声）
       - **根因（不是 6c697cc 修复的场景）**：GitHub 生成的 discussion body 里 `[![alt](imgUrl)]` 与外层链接 `(hrefUrl)` 之间**夹了一个换行符**，flutter_markdown_plus 走 CommonMark 严格解析时会因此把整段 `[![alt](imgUrl)]\n(hrefUrl)` 判为"未闭合 link"→ 全段降级为纯文本，`imageBuilder` 从未被触发，UA/errorBuilder 分支自然不生效。
       - ✅ **2026-07-27 修复完成（Dart 侧预处理，commit `a60f884`）**：在 [gsy_markdown_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart) 顶层新增 [mergeLinebrokenImageLinks](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L92-L99)，在 [_processMarkdownImages](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L195-L297) 开头调用；正则 `\[!\[([^\]\n]*)\]\(([^)\s]+)\)\][ \t]*\n?[ \t]*\(([^)\s]+)\)` 保守匹配——alt 不含 `]` 与换行、URL 不含空格 / 右括号，避免误吞下一行独立段落或独立普通链接。已是单行的表达式命中后原样输出（幂等），与 `<a><img></a>` 直通分支输出的单行形态无冲突。
       - 验证：新建 [test/widget/markdown_linebroken_image_link_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/widget/markdown_linebroken_image_link_test.dart) 覆盖 8 case（基本换行合并 / private-user-images JWT query / alt 含中文与空格 / hrefUrl 相对路径 / 已单行幂等 / 后续独立普通链接不误吞 / 多段混合 / 多空格与 tab），`flutter test test/widget/markdown_linebroken_image_link_test.dart` 8/8 全绿；`flutter analyze` 目标文件零告警。
       - **2026-07-27 增量：`<a><img></a>` HTML 结构直通修复（另一条独立 bug 路径，非本 pt.4 根因）**
         - 现象：`bodyHTML` 里 GitHub 生成的 `<a href="X"><img src="Y" alt="Z"></a>` 走 [_dispatch](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/markdown_html_transformer.dart) `<a>` 分支时，`label = "![Z](Y)"` 被 `_escapeMdLinkText` 转义成 `\!\[Z\](Y)`，最终产物 `[\!\[Z\](Y)](X)` 是 CommonMark 无法识别的字面文本，`imageBuilder` 永远进不去。
         - 修复：在 [_dispatch](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/markdown_html_transformer.dart) `<a>` 分支新增 [_extractSoleImgChild](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/markdown_html_transformer.dart) 辅助——当 `<a>` 的唯一有效子节点是 `<img>` 时（允许前后空白 text 节点），直接吐出 `[![alt](src)](href)`，`alt` 单独走 `_escapeMdLinkText`，`src` / `href` 走 `_escapeMdUrl`（防空格 / 右括号伪造）。混合子节点（多张图、img+文字）仍回落通用 label 转义分支，安全优先。
         - 覆盖：[test/widget/markdown_html_transformer_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/widget/markdown_html_transformer_test.dart) 新增 6 case（直通形态 / private-user-images JWT 长 URL / 混合子节点回落 / 两张 img 回落 / 空白 text 节点容忍 / alt 含 `]` 转义），52/52 全绿；`flutter analyze lib/widget/markdown test/widget/markdown_html_transformer_test.dart` `No issues found!`。
       - **本轮已知缺口（两条 bug 路径共同的真机验收缺口）**：**未在真机上复核 #511** —— 装机（`adb install -r build/app/outputs/flutter-apk/app-debug.apk`）通过，但当前 fixture 设备 `jfxgpjeul7lrpjkz` 的 GSY 主 Activity 以 landscape 内容渲染（`adb exec-out screencap -p` 输出 2400x1080，与竖屏 `wm size 1080x2400` / `mRotation=ROTATION_0` 不一致），`adb input tap` 用竖屏物理坐标全部落偏，导航到 BettaFish `#511` 详情页失败。按 [AGENTS.md 分级要求](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md) "稀有分支覆盖率无法靠真机保证时，优先加模型层单测 + 真实 fixture" 补齐单测（含 private-user-images JWT URL 真实 fixture 形态 + 换行断开真实形态）后停在此层。
       - **旋转 override 排查思路（下一轮真机验收前必须先解决）**：
         1. `adb shell settings get system user_rotation` / `adb shell settings put system accelerometer_rotation 0` 关闭自动旋转，再 `settings put system user_rotation 0` 强制竖屏 override；
         2. 若仍不生效，试 `adb shell wm user-rotation lock 0`（部分厂商 ROM 才支持）；
         3. 最兜底：重启设备（`adb reboot`）后立即抓 `wm size` / `dumpsys display | grep -Ei 'rotation|orientation'` 观察 boot 之后 rotation 是否恢复；
         4. 若依旧偏，改用 flutter_driver / integration_test 走"按 semantics label 找目标"的路径，不再依赖屏幕物理坐标（这条依赖引入新依赖，需在 PR 描述里显式提出）。
       - **真机关键证据要求（挪到下一个 milestone 兑现）**：#511 body 段 img 位置**不再出现蓝色链接文本**，落到真图或 [_networkImageErrorFallback](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L32-L67) 占位；配套 `logcat -d -s flutter` 无 `Image.network failed` 或 label 转义相关 warning；截图路径按 [AGENTS.md 运行时冒烟规范](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md) 写入完成汇报三段式。
    5. **replies 非空嵌套真机验收**：换到 `#417`（1 comment + 1 reply）或 `#309`（3 comments + 长链）复核 `_buildReplyRow`

  - **Fixture 契约（2026-07-20 API 探针实测）**：

    **CarGuo 生态全军覆没**：主仓 + 5 个 CarGuo 名下仓库 `has_discussions=false`（未认证 REST 实测）。
    Discussion fixture **必须走外部妥协项**。

    **首选外部妥协项**：`666ghj/BettaFish`（41k stars, User owner_type, 与 §2.5 DiscussionEvent 来源一致，见 [event_utils.dart#L396-L412](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/event_utils.dart#L396-L412)）

    | Discussion # | Category | Answered | Comments | 覆盖场景 |
    |---|---|---|---|---|
    | [#511](https://github.com/666ghj/BettaFish/discussions/511) | 📣 Announcements | - | 2 | Maintainer 徽标 + reactions (👍30🎉11) + upvote=8 + release-linked footer + image embed |
    | [#417](https://github.com/666ghj/BettaFish/discussions/417) | 🙏 Q&A | ✅ | 1 (+1 reply) | Answered 徽标 + bot 评论 + author self-answer + code block + 嵌套 reply + 完整 markdown |
    | [#309](https://github.com/666ghj/BettaFish/discussions/309) | 🙏 Q&A | ✅ | 3 | Answered + 长评论链 |
    | [#418](https://github.com/666ghj/BettaFish/discussions/418) | 🙏 Q&A | ❌ | 9 | Unanswered + 长评论链（最多） |
    | [#680](https://github.com/666ghj/BettaFish/discussions/680) | 💬 General | - | 1 | 短标题 + 短 body（GraphQL 边界） |
    | [#121](https://github.com/666ghj/BettaFish/discussions/121) | 💬 General | - | 1 | 孟加拉语标题 `হাই`（多语言渲染） |
    | [#134](https://github.com/666ghj/BettaFish/discussions/134) | 💬 General | - | 0 | 0 comment 空状态 |
    | [#697](https://github.com/666ghj/BettaFish/discussions/697) | (deleted) | - | - | 已删除 404 边界（真机进入应显示 `discussion_not_found`） |

    **对照组**（同时探过、`has_discussions=true` 但 GSY 生态无关联，仅作 fallback）：
    `vercel/next.js` (141k★) / `vuejs/core` (54k★) / `expo/expo` (51k★) / `supabase/supabase` (107k★) / `shadcn-ui/ui` (119k★)

    **明确不选**：`flutter/flutter` / `microsoft/TypeScript` 都 **`has_discussions=false`**，别再往这两个仓库塞探针了。

    **写操作边界**（对齐 [AGENTS.md 允许/禁止清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169)）：
    - ✅ 允许：Discussion comment 加 reaction、Discussion comment 加评论
    - ❌ 禁止：新建 Discussion / 删除 Discussion / 转移分类 / mark as answer（作者行为，属禁止清单里"提交 / dismiss review"同族）
    - ⚠️ 待定：upvote discussion 本体 —— GraphQL 有 `addUpvote` mutation，边界暧昧（不改讨论内容但影响排序），**本轮不实现**，留在 PR 描述里显式提出后再拍板

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
- **GitHub Actions runs 状态**：作者行为重叠多，看第 4 节那个边界定了再决定。
- **Projects V2 阅读**：~~完全没做~~ **2026-07-06 拍板归入禁止清单**（阅读也搁置），不再列入待做，见 [AGENTS.md §允许 / 禁止的写操作清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md#L141-L169)。
- **Copilot Chat 上下文**：GSY 定位不做 AI，一般跳过。

### 3.5 API 差集 × Fixture 契约表（2026-07-06 落地）

**这一小节的存在意义**：前面 §3.1-3.3 罗列了功能待办，但**没有把"用哪个仓库验证"钉死**。
Discussions 阶段就吃过这个亏——事件识别做完才发现 GSY 关注账号里根本没 discussion 事件，
真机路径覆盖不了，只能补单测。这一节把每个待办功能**预先绑定测试 fixture**，
挑活前一眼看清是否能上真机；`⚠️`标记的项目要在正式开工前**先跑 API 探针**确认。

**Fixture 优先级规则**（与 [AGENTS.md 允许 / 禁止的写操作清单](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md) 一致：**禁止造数据**，全部用真实数据）：

1. 主仓 [CarGuo/gsy_github_app_flutter](https://github.com/CarGuo/gsy_github_app_flutter)（首选）
2. CarGuo 名下其他仓库：`GSYVideoPlayer / GSYGithubAppKotlin / GSYGithubAppCompose / GSYGithubAPP / gsy_flutter_book`
3. 当前 adb 登录账号 `CarSmallGuo` 的通知 / 关注数据（首选，因为不用切账号）
4. 外部真实仓库（`flutter/flutter` / `dart-lang` / `defunkt` 等）—— 仅在前三档无数据时启用，**必须显式标注为"外部妥协项"**

---

**探针结果快照**（2026-07-06 用 CarSmallGuo 的 gho\_ token 实测，`GET /rate_limit` 显示 core 4997/5000，探针零压力）：

| 探针 | 结论 |
|---|---|
| `GET /repos/CarGuo/gsy_github_app_flutter/milestones?state=all` | count=0 → 主仓无 milestone，需外部 fixture |
| `GET /repos/CarGuo/gsy_github_app_flutter/issues?state=all&per_page=10` | #938 有 `assignees=[CarGuo,Copilot]`；其他 9 条都是 `(none)` → assignee 挂件用 #938 即可 |
| `GET /repos/CarGuo/gsy_github_app_flutter/pulls/938/comments` | 2 条 line-level review comment（Copilot 对 `android/app/build.gradle` L41 / L84），完美 review thread fixture |
| `GET /users/CarGuo/gists` | count=0 → CarGuo 无公开 gists，fallback 到 `defunkt`（已实测 3 条非空） |
| `GET /notifications?all=true&per_page=30` | 30 条通知 reason 分布 `subscribed x 28 / manual x 2` → reason chip filter 需要更丰富 reason，实际验证时可去用 `mention` / `review_requested` 相关的仓库 |
| `POST /graphql user.pinnedItems(first:6)` | CarGuo pinned 6 个仓库：`GSYVideoPlayer ★21458 / gsy_github_app_flutter ★15461 / GSYGithubAppCompose ★125 / GSYGithubAPP ★2485 / GSYGithubAppKotlin ★1586 / gsy_flutter_book ★4618` → 完美 pinned fixture |

---

#### 模块 1：动态 / 事件

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | 公共事件流 `/events` | 无需 fixture | 全站流，任何账号登录后即有数据 |
| 2 | 组织事件 `/orgs/:org/events` | `flutter` / `dart-lang` 组织（外部妥协项） | CarGuo 是个人账号，无组织 fixture |
| 3 | Repo 网络事件流 `/networks/:o/:r/events` | ✅ 主仓（fork 数够） | [Address.getReposEvent](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/address.dart#L86-L88) URL 已在但无 UI 消费 |
| 4 | 事件类型 filter | ✅ 主仓首页混合事件流（本轮真机截图 [smoke_ci344_01_home.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/smoke_ci344_01_home.png) 已证 6 张卡多种事件混排） | 纯本地过滤 |

#### 模块 2：仓库详情

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | Release 详情页 + reactions | ✅ 主仓 releases（`8.0.0` 已在真机日志出现） | [release_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/release/release_page.dart) 是列表未做详情 |
| 2 | Topics chip | ⚠️ 需先跑 `GET /repos/CarGuo/gsy_github_app_flutter/topics` 确认非空 | 若空，退到 `flutter/flutter`（topics 稠密） |
| 3 | Labels chip | ✅ 主仓 [Address.getReposLabels](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/address.dart#L138-L140) URL 已在 | 主仓 labels 页非空 |
| 4 | Milestone | **主仓无 milestone**（探针实测 count=0） → 用 `flutter/flutter`（外部妥协项） | 已实测确认 |
| 5 | Branches 切换 | ✅ 主仓多分支 | [Address.getbranches](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/address.dart#L337-L339) URL 已在 |
| 6 | Contributors / Stargazers / Watchers 列表页 | ✅ 主仓 fixture ★15461（探针实测） | UI 只有数字未做列表 |
| 7 | Compare 视图 | ✅ 主仓 `423c762...bf557aa`（本轮实际存在的两个 commit） | [Address.getReposCompare](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/address.dart#L116-L118) URL 已在 |
| 8 | Language 分布条 | ✅ 主仓多语言（Dart + Java + ObjC + Kotlin） | `GET /repos/:o/:r/languages` |
| 9 | Community Health | ✅ 主仓 `GET /repos/CarGuo/gsy_github_app_flutter/community/profile` | 主仓有 LICENSE / README 完整 |

#### 模块 3：Issue / PR

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | Assignee / Milestone / Label 挂件 | ✅ Assignee 用主仓 [#938](https://github.com/CarGuo/gsy_github_app_flutter/pull/938)（实测 assignees=`CarGuo,Copilot`）；Milestone 用 `flutter/flutter`；Label 用主仓 | 单一 issue detail 页混合 fixture |
| 2 | PR 状态 badge (draft / mergeable / conflicts) | ✅ 主仓 #938 | AGENTS.md 已固化 |
| 3 | PR reviews 完整列表 | ✅ 主仓 #938 | AGENTS.md 已固化 |
| 4 | PR commits | ✅ 主仓 #938 | AGENTS.md 已固化 |
| 5 | PR review thread 阶段 A/2 | ✅ **主仓 #938**（实测 2 条 line-level comment：Copilot 对 `android/app/build.gradle` L41 / L84）| 完美 review thread fixture |
| 6 | Issue comment reactions | ✅ 主仓 [issue #643](https://github.com/CarGuo/gsy_github_app_flutter/issues/643)（README 里"登录失败"高流量 issue） | [Address.getIssueCommentReactions](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/net/address.dart#L243-L245) URL 已在 |
| 7 | Timeline 分页 | ✅ 主仓 [issue #13](https://github.com/CarGuo/gsy_github_app_flutter/issues/13)（README 明示"所有运行问题请点这里"，历史巨长 issue） | 完美长 timeline fixture |

#### 模块 4：搜索

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | Commits 搜索 | ✅ 搜 `repo:CarGuo/gsy_github_app_flutter Copilot` 命中 | 主仓自搜 |
| 2 | Topics 搜索 | ✅ 搜 `flutter` / `github-client` | 全站，主仓也在结果集 |
| 3 | Labels 搜索 | ✅ `GET /search/labels?repository_id=142308181&q=bug`（142308181 是主仓 id，本轮真机日志 `repo:{id:142308181}` 已确认） | 主仓 id 已固定 |
| 4 | 搜索历史 UI 增强 | 无需 fixture | 本地 [search_history_repository](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/repositories/search_history_repository.dart) 数据 |
| 5 | 高级筛选 chip | 无需 fixture | 纯 UI |

#### 模块 5：用户 / 我的

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | 用户公共 Gists | **CarGuo 无 gists**（实测 count=0）→ 用 `defunkt`（外部妥协项，探针实测 3 条非空） | 已实测确认 |
| 2 | 贡献日历 GraphQL 版 | ✅ CarGuo（活跃开发者，calendar 稠密） | 主用户已够 |
| 3 | Pinned Repositories | ✅ **CarGuo 6 个 pinned**：GSYVideoPlayer / gsy_github_app_flutter / GSYGithubAppCompose / GSYGithubAPP / GSYGithubAppKotlin / gsy_flutter_book（探针实测） | 完美 fixture |
| 4 | Following/Followers 交集 | ✅ CarGuo × CarSmallGuo（后者是 adb 当前登录账号，天然双账号） | 双账号 fixture |
| 5 | 组织详情页 | `flutter` / `dart-lang`（外部妥协项） | CarGuo 不是组织 |

#### 模块 6：通知

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | 仓库级通知筛选 | 依赖 CarSmallGuo 订阅——**已实测 30 条通知都是主仓 subscribed** → 主仓即可 | 单仓测试足够 |
| 2 | reason chip filter | **CarSmallGuo 当前 reason 单一**（subscribed x 28 / manual x 2）→ 实际验证时通过手动 mention 其他账号或订阅 `flutter/flutter` 扩容 reason 分布 | 已实测确认 |
| 3 | since / before 窗口 | 无需 fixture | 参数扩展 |
| 4 | 未读 badge | 无需 fixture | 现有数据算 |

#### 跨模块补充

| # | 待办功能 | fixture 锚点 | 备注 |
|---|---|---|---|
| 1 | Reactions 铺满（release / commit comment 等） | ✅ 主仓 issue #643 + release `8.0.0` | 主仓够用 |
| 2 | Markdown / Emoji 渲染 | 无需 fixture | POST 任意 md |
| 3 | License 列表 | 无需 fixture | 全站 API |
| 4 | Rate Limit 诊断入口 | 无需 fixture（当前 token 自查，本轮探针实测 core 4997/5000） | 天然自证 |
| 5 | Stars 增长曲线 | ✅ 主仓（README 已用 star-history 外链 badge，数据密度够画） | 主仓够用 |

---

#### 挑活契约（本节的强约束）

- 从本节挑一个功能开工前，**先看该行 fixture 锚点**：`⚠️` 项必须先跑一次 API 探针把它转成 `✅` 或"外部妥协项"，再动代码
- 挑外部妥协项的功能时，**必须在 PR 描述里注明"本功能验证使用外部仓库 X，原因 Y"**，不能默认使用
- 新增待办条目时必须补上 fixture 锚点栏；无 fixture 锚点的条目不合并入本表

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
