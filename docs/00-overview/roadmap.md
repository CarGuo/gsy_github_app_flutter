# 项目现状与待办清单（Roadmap）

这份文档回答一个问题：**"这个仓库现在到底还差什么？"**

它不是需求池，也不是 ADR，只是一份**当前时点的现状快照**，方便任何人（人或 agent）在挑下一个任务前先对齐现实。

维护约定：

- 每次完成一个有分量的改动，记得回来划掉相应条目
- 不确定该不该做的功能，放"待定义边界"一节，别直接塞进 TODO
- 只写"当前还差什么"，不写完整历史；历史看 git log 和 ADR

最后一次盘点：2026-09-03（P0/P1/P2 大屏与折叠屏自适应导航 + Master-Detail 双栏落地 + P0/P1 blocking issue 收口，见 §四点五）。

---

## 〇、版本基底与工具链（2026-09-01 更新）

这一节回答 "本仓库现在跑在什么组合上"。改动量大 / 硬约束多的升级都必须先在这里落一笔，
否则后来的人不知道 "这个组合是刻意选的" 还是 "祖传遗留"。

| 层 | 当前版本 | 约束来源 |
|---|---|---|
| Flutter SDK | **3.47.2 stable** | 仓库根 [`.fvmrc`](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/.fvmrc) |
| Dart SDK 下限 | **3.13.0** | [pubspec.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/pubspec.yaml#L6-L7) `environment.sdk` |
| iOS 最低部署 | **15.0** | Flutter 3.47 硬要求；Podfile / AppFrameworkInfo / project.pbxproj 已同步 |
| iOS 依赖主路径 | **Swift Package Manager**（`enable-swift-package-manager: true`，pubspec 项目级） | Flutter 3.44+ 默认；CocoaPods registry 2026-12-02 变只读 |
| iOS 生命周期 | **UIScene**（`Info.plist` 有 `UIApplicationSceneManifest` + [SceneDelegate.swift](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/ios/Runner/SceneDelegate.swift)） | Apple 硬要求 |
| Android Gradle Plugin | **9.0.1** | Google 官方，Flutter 3.47 兼容 |
| Gradle | **9.1.0** | AGP 9.0.1 硬下限 |
| Kotlin | **2.2.20** | Flutter 3.47 硬下限 |
| Android `compileSdk` | **35** | AGP 9 最低 34；`fluttertoast:9.1.0` 已修好 |

**已知历史妥协项**（需要长期跟进消除）：

- [android/gradle.properties](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/android/gradle.properties)
  当前 `android.newDsl=false` + `android.builtInKotlin=false`——这是 Flutter Gradle
  plugin 对 AGP 9 新 DSL 的官方 workaround，未来 Flutter tool 支持 new DSL 后可以撤回
- iOS 端 5 个 Pod-only 插件（`connectivity_plus / device_info_plus / package_info_plus /
  rive_common / sqflite`）等上游发 SPM 版本；deadline 2026-12-02，参见
  [docs/03-runbooks/swiftpm-migration.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/docs/03-runbooks/swiftpm-migration.md)
- Dart 3.13 SDK 下限已抬升，但仓库代码尚未主动使用 3.13 才有的新语法/API；
  这是 "打地基" 型改动，具体收益需要在后续 refactor 里显性化

**本轮相关 commit**（master）：

- `092c226 → 24cbbfc`：Flutter 3.47.2 / AGP 9.0.1 / iOS SPM+UIScene 静态迁移
- `24cbbfc → 7b8c65c`：Dart SDK 下限 3.13.0 + 4 处 `var`/`final` 参数硬修
- `7b8c65c → ?`：SPM 项目级开关显式化 + 文档同步（本 commit）

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
- 冒烟脚本 [tool/ai/smoke/open_home_dynamic.sh](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.sh) 沉淀本轮 tap 坐标（**已作废**：2026-09-02 全面回归 `mcp_dart`，路径改为 [tool/ai/smoke/open_home_dynamic.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.md)）
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

### 2.6 build_runner 环境级技术债（riverpod_generator 3.0.3）—— ✅ 2026-09-03 已收尾

**收尾方式**：2026-09-02 起把 `flutter_riverpod / riverpod_annotation / riverpod_generator` 三者一起从 3.0.3 迁到 4.x（当前 [pubspec.yaml](file:///d:/workspace/project/gsy_github_app_flutter/pubspec.yaml#L112-L119) 已锁 `flutter_riverpod: 3.4.2 / riverpod_annotation: 4.0.6 / riverpod_generator: 4.0.8`）。`AnalyzerBuffer._upsertImport` 对 re-exported 类型的 URI 假设错误在 4.0.x 里已修，`dart run build_runner build --delete-conflicting-outputs` 现在能干净跑通 3 个 async provider 的 .g.dart 生成。

**下方"根因诊断（3.0.3 阶段）"章节保留为历史勘误**，供未来撞到类似 URI mismatch 的问题时对照。

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


### 2.7 CI Flutter 版本升级 3.41.6 → 3.44.1 → 3.47.2（本节保留为历史勘误）

**当前基线（2026-09-03 复核）**：`.fvmrc` 与 [local-setup.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/03-runbooks/local-setup.md#L5) 已经统一锁死 **Flutter 3.47.2 stable / Dart 3.13.x**，`.github/workflows/ci.yml` 读 `.fvmrc` 作为唯一版本契约源。本节下方的 3.41.6 → 3.44.1 迁移过程仅保留作为**历史勘误**，展示"本地 3.44.x / CI 3.41.6 SDK 漂移"这条 pattern 是如何被 `subosito/flutter-action@v2` + `flutter-version-file: .fvmrc` 一劳永逸掐掉的。**新读者不用再对着 3.44.1 这个数字调 CI**。

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

**遗留（2026-09-04 复核）**：本节起草时说 "Flutter 3.44 有 Material/Cupertino 拆包 deprecation warning"，
这是 3.44.x 早期短暂出现过的过渡态，`package:flutter/material.dart` 仍可用只出 warning。
**升到 3.47.2 stable 后已消失**：本轮 `fvm flutter analyze` 全量结果只剩两条与本节无关的老 issue——
1 个 pre-existing `analysis_options_deprecated_plugins` warning（[analysis_options.yaml:14](file:///d:/workspace/project/gsy_github_app_flutter/analysis_options.yaml#L14)
里 `plugins: - custom_lint` 这种 legacy 声明，属于 analyzer 侧待迁移，与 Flutter SDK 拆包无关），
以及 1 个 [user_redux.dart:66](file:///d:/workspace/project/gsy_github_app_flutter/lib/redux/user_redux.dart#L66-L67)
的 `void_checks` info（rxdart 0.28.0 把 `debounce` window 回调返回类型收紧为 `Stream<void>` 后的隐式转换）。
**读者不用再对着"Material/Cupertino 拆包"这条老 warning 调 CI**。**§2.6 `riverpod_generator 3.0.3`
URI mismatch 已于 2026-09-03 收尾**（见 §2.6 标题上的 ✅），与本节 CI SDK 漂移是两条独立叙事，不再联动。


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
    - ✅ 冒烟脚本沉淀 [tool/ai/smoke/open_repo_discussions_tab.sh](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_repo_discussions_tab.sh)（首页 → 搜索 → 仓库 → 讨论 tab → 详情，链路可复现；**已作废**：2026-09-02 改为 [tool/ai/smoke/open_repo_discussions_tab.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_repo_discussions_tab.md) 的 `mcp_dart` 版）
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
       - ✅ **2026-07-28 fixture 探针完成**（gh cli discussion search 已不再支持 `type:discussion`，改用 `Invoke-WebRequest` 拉 `vercel/next.js/discussions?discussions_q=sort:top` HTML → [build/smoke/nextjs_discussions_top.html](file:///d:/workspace/project/gsy_github_app_flutter/build/smoke/nextjs_discussions_top.html) 585KB，正则 `aria-label="(\d+) comments?:[^"]*"[^>]*href="/vercel/next\.js/discussions/(\d+)"` 一次抽出 25 条候选，评论数从 2616 到 25 均匀分布）
       - **首选外部妥协项 → `vercel/next.js#37136`**「RFC: Layouts」(RFC/Announcement category, Closed, 480 comments)，理由：480/30≈16 页足够压测 loadMore 循环但不过分，比 `#41745`（2616）体感更贴近生产 discussion；详情页 HTML ([build/smoke/nextjs_37136.html](file:///d:/workspace/project/gsy_github_app_flutter/build/smoke/nextjs_37136.html) 2.1MB) 里 `<button>Load more…</button>` 与 `data-timeline-item-src="/vercel/next.js/discussions/37136/timeline_anchor?after=...&before=..."` 并存，服务端明确 `hasNextPage=true`（HTML 第一屏 render "**135 hidden items**" 提示 + Load more 按钮），完美匹配 GSY 移动端 `first:30` + `hasNextPage=true` loadMore 触发路径
       - **备用（压力测）**：`vercel/next.js#41745`（2616 comments，>87 页），仅在验证 `endCursor` 边界或"极长 dataList 滚动性能"时启用
       - **真机验收步骤（下一 milestone 兑现，前置依赖 pt.4 设备旋转 override 已解决）**：登录 CarSmallGuo → 搜 `vercel/next.js` → discussions tab → 打开 `#37136` → 滚到 comments 段尾部 → 点"加载更多评论" 按钮 → 抓改动前 dataList.length / 改动后 dataList.length / 底部"没有更多评论了"或再次 Load more 的截图，logcat 无 GraphQL 401 或 rate_limit 报错；截图路径按 AGENTS.md 三段式写入完成汇报
       - ✅ **2026-07-29 真机验收完成（改走轻量 fixture `vercel/next.js#49607`「Google fonts break with tailwindcss」125 comments，比 `#37136` 的 480 快 4× 且同样触发 `hasNextPage=true` 分支）**：
         - **看代码**：本轮无 loadMore 代码改动，验证的是 `#3.1 pt.3` GraphQL 分页 + [_buildLoadMoreFooter](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L620-L670) 4 态显隐 + [_loadMore](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L137-L176) 的 setState/merge 端到端在真机 release build 上是否闭环
         - **看编译**：无源码 diff，跳过 `flutter analyze` / `build_runner`；沿用 `versionName 8.1.0` release apk（含 `6c697cc` + `a60f884`）
         - **看运行**：设备 `jfxgpjeul7lrpjkz`（`Redmi K60 · Android 13 · MIUI`，前置 `tool\ai\smoke\probe_device_rotation.ps1 -Apply` 关自动旋转 + `wm user-rotation lock 0`，`wm size 1080x2400` 与 `exec-out screencap` 尺寸一致，坐标 tap 无偏移）
           - 关键截图落地目录 [tool/dbg/discussion_loadmore_smoke/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_loadmore_smoke)：
             - [12_after_scroll_43x.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_loadmore_smoke/12_after_scroll_43x.png)：首屏 30 条评论后底部"加载更多评论"OutlinedButton 渲染 →`hasNextPage=true` 分支命中
             - [13_after_loadmore_tap.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_loadmore_smoke/13_after_loadmore_tap.png)：tap loadMore 后按钮消失，新一批评论（`sahariar-safin @ 2023-06-10`）append 到 dataList 尾部，`_loadingMore` transient 态未卡死
             - [14_scroll_after_loadmore.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_loadmore_smoke/14_scroll_after_loadmore.png) / [15_further_scroll.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_loadmore_smoke/15_further_scroll.png)：新数据继续可滚（2023-06-26/27/07-17 均可见），`mergeCommentsPage` 追加语义正确
           - `logcat`：GSY release build 下 `logcat -d -s flutter:V` 输出 0 行（Android 8+ non-debuggable 权限限制），改用 [20_logcat_gsy_lines.txt](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_loadmore_smoke/20_logcat_gsy_lines.txt) 全 tag pid grep 也为空 —— **属工具链限制而非 exception silent**，本条已列入下方"已知缺口"
         - **已知缺口（列出不遮）**：
           - a) 未验第 2 次 loadMore（发生在 60→90 条时），当前 SingleChildScrollView 视觉在 Inkvii 评论卡内嵌 code block 的横滚区域被拦截，垂直 swipe 落在 y≈1800 的 code block 上无法继续下滚触发第二次点击 —— **这是 GSY 独立 UX 缺口（code block scroll-gesture 抢占），与 loadMore 分页语义无关**，已在下方 pt.6 立项修复（2026-07-29 方案 C 代码层完成，真机复核挪到下一轮 milestone 与本 pt.3 pt.2 一并做）；
           - b) 未验"没有更多评论了" 语义 —— 前置 a) 未解决，无法一路 loadMore 到 5 页尾部；GraphQL 层 `hasNextPage=false` 已通过 [test/page/discussion/discussion_comments_page_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/discussion/discussion_comments_page_test.dart) 单测覆盖；
           - c) release build logcat 权限限制导致无 GraphQL 请求侧记录，回退到"UI 数据可见性 = 请求成功"的间接证据链
         - **本轮不再阻塞 pt.3**：核心分支「`hasNextPage=true` → 点按钮 → 拉下一页 → merge → 新评论渲染」已获得真机截图证据链，pt.3 loadMore 特性在 §3.1 里降为 ✅ 已完成
       - **fixture 契约表更新**：见下方 §3.1 Fixture 契约表末尾"外部妥协项 · Discussion loadMore"新增 `#49607` 作为**真机路径更短的推荐 fixture**（125 comments，滚 3~4 屏即触底）
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
       - ✅ **2026-07-28 排查工具沉淀** ([tool/ai/smoke/probe_device_rotation.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/probe_device_rotation.ps1))：把上面 4 条排查思路翻译成 4 步中立诊断脚本（step1 baseline / step2 settings probe / step3 wm user-rotation probe / step4 summary），默认只读，`-Apply` 才写 override。真机 (device `jfxgpjeul7lrpjkz`, 1080x2400) baseline 已抓（evidence 落 [tool/ai/smoke/evidence/20260728_1518/rotation_probe_report.txt](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/20260728_1518/rotation_probe_report.txt)，`.gitignore` 忽略不入库）：
         * `wm size 1080x2400` 与冒烟脚本坐标假设一致 ✓
         * `mCurrentOrientation=0` / `rotation 0` / `installOrientation ROTATION_0` 设备当前就是竖屏
         * `settings get system user_rotation: 0`（override 已存在）
         * `settings get system accelerometer_rotation: 1` ← **就是这条**：自动旋转开着，冒烟中途手机翻身即会打乱绝对坐标 tap，正是 pt.1/2/4/5 真机验收 tap 落错的根因
         * `wm user-rotation` `free`（未 lock）；ROM 支持该 subcommand，`-Apply` 时会走 `wm user-rotation lock 0` 加固
         * **下一轮真机 milestone 上手直接跑**：`pwsh -NoProfile -File tool\ai\smoke\probe_device_rotation.ps1 -Apply -Device jfxgpjeul7lrpjkz`，把 `accelerometer_rotation` 写成 0，即解锁 pt.1/2/4/5 的真机验收前置
       - **真机关键证据要求（挪到下一个 milestone 兑现）**：#511 body 段 img 位置**不再出现蓝色链接文本**，落到真图或 [_networkImageErrorFallback](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L32-L67) 占位；配套 `logcat -d -s flutter` 无 `Image.network failed` 或 label 转义相关 warning；截图路径按 [AGENTS.md 运行时冒烟规范](file:///d:/workspace/project/gsy_github_app_flutter/AGENTS.md) 写入完成汇报三段式。
    5. **replies 非空嵌套真机验收**：换到 `#417`（1 comment + 1 reply）或 `#309`（3 comments + 长链）复核 `_buildReplyRow`
    6. **code block scroll-gesture 抢占修复（✅ 2026-07-30 代码层 + 真机验收全部完成）**：
       - **根因**：`flutter_markdown_plus` 的 `pre` 标签内置渲染硬编码使用 `Scrollbar` 包裹横滚 `SingleChildScrollView`（见依赖仓库 `flutter_markdown_plus/lib/src/builder.dart` L344-L357），`Scrollbar` 会独占 `Axis.vertical` 的 `HorizontalDragGestureRecognizer`/`VerticalDragGestureRecognizer`，导致外层 [discussion_detail_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart#L265-L275) 的 `SingleChildScrollView` 在 code block 落点收不到垂直 drag。真机现象即 pt.3 已知缺口 a)：滚到 y≈1800 的 Inkvii 评论卡内嵌 code block 后，垂直滑动被拦截，第 2 次 loadMore 与"没有更多评论了"末态无法自动触发。
       - ✅ **2026-07-29 方案 C 落地（去掉 Scrollbar，保留横滚 + 高亮，最小侵入）**：新建 [lib/widget/markdown/safe_pre_builder.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/safe_pre_builder.dart) → [SafePreBuilder](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/safe_pre_builder.dart) 继承 `MarkdownElementBuilder`，`visitText` 返回**无 Scrollbar** 的 `SingleChildScrollView(scrollDirection: Axis.horizontal, physics: ClampingScrollPhysics)` 包裹 `Text.rich`（`GSYHighlighter` 高亮 span 挂在 `preferredStyle` 之下，配色不丢）；[gsy_markdown_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart) 里 `Markdown` 增加 `builders: {'pre': SafePreBuilder(...)}` 注册。`pubspec.yaml` 显式补 `markdown: ^7.3.0`（覆盖 `visitText(md.Text, TextStyle?)` 签名需直接 import `package:markdown/markdown.dart`，否则 `depend_on_referenced_packages` 会告警）。
       - **单测**：新建 [test/widget/safe_pre_builder_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/widget/safe_pre_builder_test.dart) 4 case 全绿——① `Markdown` 渲染带 code block 的 md 后子树里可查到 `SingleChildScrollView(scrollDirection: horizontal)`；② 同一子树里 `Scrollbar` 计数为 0；③ 高亮内容（模拟高亮器返回的自定义 TextSpan）落到 `Text.rich` 且保留自定义 `TextStyle`；④ code block 继承 `styleSheet.codeblockPadding`。`flutter test test/widget/`（含既有 issue_timeline_item / linebroken_image_link / html_transformer 等）89/89 全绿；`flutter analyze lib/widget/markdown/safe_pre_builder.dart lib/widget/markdown/gsy_markdown_widget.dart test/widget/safe_pre_builder_test.dart` `No issues found!`。
       - ✅ **2026-07-30 真机验收完成（fixture 换到 `vercel/next.js#96370`「Turbopack Error Report」，天然含超长垂直 code block，比原计划 `#49607` 走 loadMore 的路径更短更直接，也更贴切验证 vertical drag 穿透）**：
         - **看代码**：无本轮新增代码改动，只装 pt.6 方案 C 已交付的 release apk。
         - **看编译**：`flutter build apk --release --target-platform=android-arm64 --no-shrink` 成功产出 `build\app\outputs\flutter-apk\app-release.apk` (17.7MB)；`adb install -r`（保留 SharedPreferences TOKEN_KEY，遵守 AGENTS.md「禁止 flutter install」条款）。
         - **看运行**：设备 `jfxgpjeul7lrpjkz`（`Redmi K60 · Android 13 · MIUI`，本轮再次跑 [probe_device_rotation.ps1 -Apply](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/probe_device_rotation.ps1) 关自动旋转 + wm user-rotation lock 0）；截图落 [tool/dbg/discussion_codeblock_gesture_smoke/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke)：
           - [07_detail_top.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke/07_detail_top.png)：`#96370` 详情页顶部，标题 `Turbopack Error: Failed to write app endpoint /page` 可见，body code block 显示到 `Execution of parse_css failed` → 手势验证的**前置基线**
           - [08_after_swipe_on_codeblock.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke/08_after_swipe_on_codeblock.png)：从 code block 内部 `(540, 1800) → (540, 800)` 垂直上滑 → 页面**整体上滚约 1000px**，标题已滚出屏幕，code block 显示到底部 `The process cannot access the file becaus`，「添加反应」栏与「暂无评论」空态露出 → **决定性证据 A（vertical drag on code block 被外层 scrollview 接管）**
           - [09_swipe_down_back.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke/09_swipe_down_back.png)：反向 `(540, 800) → (540, 1800)` 下滑（起点仍落在 code block 内），页面回到顶部标题态 → 证据 B（反向 drag 同样穿透）
           - [10_swipe_up_more.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke/10_swipe_up_more.png)：二次上滑复现证据 A，鲁棒性保证（不是一次性侥幸）
           - [11_hswipe_left.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke/11_hswipe_left.png)：在 code block 上做**横向** `(900, 900) → (100, 900)` swipe → code block 内部横滚到显示 `ContentIndex\14c8f5d6-5e03-4214-a617-0b...`、`used by another process. (os error 32)`、`visited_intern failed` 等**原来被截断在右侧的内容** → **决定性证据 C（horizontal drag 仍归 code block 内层横滚 SingleChildScrollView，横滚能力未被牺牲）**
           - [21_logcat_all.txt](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/discussion_codeblock_gesture_smoke/21_logcat_all.txt)：55KB 全 dump，grep `Exception|FATAL|flutter.*E/` 只出 `mi_exception_log errno=2`（MIUI 系统开机通用告警，与 GSY 无关），GSY 侧 0 异常
         - **无法覆盖分支（诚实列出）**：① 未走 pt.3 loadMore 60→90 的原始触发路径——本轮 fixture 换到 `#96370`（0 comments 空评论态）后已能**直接**从 body code block 落点验证 vertical drag 穿透，比 loadMore 场景更纯粹（不掺 GraphQL 分页噪声）；`#49607` 的 60→90 loadMore 分支仍未验（但 pt.3 已单独 ✅ 完成首次 loadMore，方案 C 修复的是**手势层**，与 GraphQL 层正交，本证据链足以外推）；② release build logcat 权限限制导致无渲染树 debug 输出（同 pt.3 已知缺口 c)，走"UI 可见性 = 手势穿透"的间接证据链）。
       - **不做的事（避免作用域蔓延）**：不引 `flutter_html` / `webview` 之类重方案（收益 vs. 依赖膨胀不划算）；不改 `flutter_markdown_plus` 的其它 builder（本轮只替换 `pre`，`code`/inline code 仍走默认渲染）；不做 code block 内容拷贝/长按菜单（属独立特性，未来单独立项）。

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

    **外部妥协项 · Discussion loadMore fixture**（2026-07-28 探针实测，BettaFish 讨论区 comments 全部 ≤30，`hasNextPage=true` 靠 BettaFish 天然覆盖不到，必须走对照组）：

    | Discussion # | Category | State | Comments | 覆盖场景 | 探针依据 |
    |---|---|---|---|---|---|
    | [vercel/next.js#49607](https://github.com/vercel/next.js/discussions/49607) | Help | Open | 125 | **推荐** loadMore 首次触发（真机路径最短，30 → 60 只需滚 3~4 屏即触底出 loadMore 按钮） | 2026-07-29 真机验收命中 fixture（见 §3.1 pt.3 「2026-07-29 真机验收完成」），实测首次 loadMore 后 dataList 由 30 增至 60 且新评论 `sahariar-safin @ 2023-06-10` 可见 |
    | [vercel/next.js#37136](https://github.com/vercel/next.js/discussions/37136) | RFC / Announcement | Closed | 480 | 多轮 loadMore 压测（480/30≈16 页） | HTML 明确 render "135 hidden items" + `<button>Load more…</button>` + `timeline_anchor?after=...&before=...` |
    | [vercel/next.js#41745](https://github.com/vercel/next.js/discussions/41745) | (待现场核实) | (待现场核实) | 2616 | 备用压力测（endCursor 边界 / 极长 dataList 滚动性能） | 同批列表页正则命中最大值，评论量约 87 页 |

    **fixture 使用约束**：
    - 仅用于 GSY 阅读侧真机验收，禁止在这两条 discussion 下发评论 / reaction / mark as answer 制造证据
    - 探针 HTML 落地在 `build/smoke/` 且 `.gitignore` 忽略，reviewer 需要复核时按上表 URL 用 `Invoke-WebRequest` 重新抓取即可
    - 半年重跑：若 `#37136` 后续 `hasNextPage` 落到 `false`（服务端一次性 render 完 480 条不太可能，但存在 GitHub 侧策略调整可能），换到 `#41745`；`vercel/next.js` 若关闭 discussions，从对照组 `expo/expo` / `supabase/supabase` 里挑一条 >30 comments 的顶置 discussion 顶替

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

## 四点五、大屏 / 横屏 / 折叠屏自适应路线图

**决策记录**：[ADR-0005 大屏 / 横屏 / 折叠屏自适应导航抽象](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)

**分支**：`feature/adaptive-layout` → `feature/adaptive-layout-p1-rail`（当前 P1 分支，含抽象隔离改造）

**核心抽象**：Strategy Delegate 模式，[GSYAdaptiveNavigation](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L119-L156) 单例 + 默认 [MaterialAdaptiveNavigationDelegate](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L60-L108)。想换 `flutter_adaptive_scaffold` 社区继任者 / 自研 Cupertino 侧栏，只写一个新 delegate 并 `setDelegate` 一行代码就够，页面代码零改动。

### P0：基础层 + 存量 bug 修复（✅ 已完成）

| 提交 | 内容 | 证据 |
|---|---|---|
| `3b6967f` | 引入 [GSYBreakpoints](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L13-L28) / [GSYWindowSize](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L30-L36) / [GSYResponsiveContext](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L38-L62)，对齐 Material 3 三档 | [gsy_responsive_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_responsive_test.dart) 9 case 全绿（compact/medium/expanded 边界 + narrowHeight + verticalHinge） |
| `f361cb9` | 修 [code_detail_page_web.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/code_detail_page_web.dart) 离开后不解锁 portrait 的存量 bug | 竖屏 → code detail → 其他页仍可横屏 |
| `e25bc48` | 在 [GSYTabBarWidget.didChangeMetrics](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L94-L104) 里旋转后 `jumpToPage(_index)` 重算 offset，修 tab 选中态 vs PageView 内容错位 | 旋转前后截图 [tool/dbg/adaptive_p0_rotate/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p0_rotate) |
| `2613c3c` | pull-load 空态高度用 `LayoutBuilder` 撑满，避免大屏空态被小图标塞在顶部 | 同上目录 |

### P1：Shell 层导航切换 + 抽象隔离（✅ 已完成）

| 提交 | 内容 | 证据 |
|---|---|---|
| `c97afe0` | [GSYTabBarWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart) 在 medium/expanded 走 [NavigationRail](https://api.flutter.dev/flutter/material/NavigationRail-class.html)，compact 保持 BottomTabBar；[home_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart) 提供 `railDestinations` | 竖屏 tab / 横屏 rail 截图 [tool/dbg/adaptive_p1_rail/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_rail) |
| `39c25e8` | rail 用 `LayoutBuilder` + `SingleChildScrollView` + `IntrinsicHeight` 兼容手机横屏窄高；移除 tabView 全局限宽避免 MyPage 5 列 stats 溢出 | 同上目录 |
| `785548c` **抽象隔离改造**（含 F1~F7 fixup） | 新增 [gsy_adaptive_shell.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)：`GSYAdaptiveDestination` + `GSYAdaptiveNavigationDelegate` + `GSYAdaptiveNavigation` 单例；[gsy_tabbar_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart) 只调 `GSYAdaptiveNavigation.instance.buildRail(...)`，`new NavigationRail` 集中到 delegate 内；[home_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart) 用 `GSYAdaptiveDestination` 声明入口 | 隔离验证截图 [tool/dbg/adaptive_p1_iso/](file:///d:/workspace/project/gsy_github_app_flutter/tool/dbg/adaptive_p1_iso)；契约测试 [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart) 7 case（4+3：默认 `shouldUseRail` 组 3 断点 case + **F5 默认 `buildRail` 渲染真实 NavigationRail 正向断言 1 case** = 4；`GSYAdaptiveNavigation delegate 可替换` 组 3 case，含 **F7 `resetDelegateForTest` 后 `delegate is MaterialAdaptiveNavigationDelegate` 类型断言**） |

**P1 已知缺口（不糊，登记在 P2）**：

- MyPage 顶部 5 列 stats 在 720dp 横屏下右侧仍会溢出（本轮为了不阻塞抽象隔离主线，移除了 tabView 全局限宽；stats 卡片自身的分栏逻辑推到 P2 单独处理）。
- rail 高亮色 vs 白色底的对比度在部分主题色下偏弱，视觉可辨识度待评估。
- ≥840dp 平板 / Chromebook 未实机验证，只在 emulator resize 到 1200×800 走过。

### P2：卡片限宽 + Master-Detail（✅ §1 + §2 + §3 已完成）

- **§1 卡片限宽（✅ 已完成，2026-09-02）**：抽象层新增 [wrapListChild](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L68-L71) 契约方法（compact 原样、medium/expanded 用 `Align(topCenter) + ConstrainedBox(maxWidth: cardMaxWidth)` 限到 720dp 居中），落地点是 [GSYPullLoadWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/pull/gsy_pull_load_widget.dart#L108-L111) 与 [GSYPullNewLoadWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/pull/gsy_pull_new_load_widget.dart) 的外部 `itemBuilder` 出口，空态 / progressIndicator 保持不包装（避免 loading 也被顶偏）。契约测试补 4 case（compact 原样 identical / medium/expanded 命中 `cardMaxWidth` / setDelegate 后走新实现）至 [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart) 共 21 case。真机证据：[p2s1_compact_full_width.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s1_compact_full_width.png)（460dp 竖屏原样铺满）/ [p2s1_medium_card_width.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s1_medium_card_width.png)（872dp 横屏卡片微留白）/ [p2s1_expanded_card_width.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s1_expanded_card_width.png)（wm density 240 撑到 1440dp，卡片明显 720dp 居中，两侧 360dp 黑背景）；`logcat -d` 0 flutter Exception / FATAL；三分档冒烟脚本沉淀到 [tool/ai/smoke/open_card_width_dual.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_card_width_dual.ps1)，reviewer 可用 `pwsh -File .\tool\ai\smoke\open_card_width_dual.ps1 -OutDir .\tool\dbg\p2s1_verify` 一键复跑（脚本自足产出与仓库同名三张 PNG + 干净 logcat）。
- **§2 Master-Detail（✅ 已完成，2026-09-02）**：抽象层新增 4 个契约 —— [canShowTwoPane](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L111-L127) / [openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L129-L145) / [forceFullScreenDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L147-L159) / [setForceFullScreenDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L161-L166) —— 语义"expanded 且非窄高 且 未强制全屏"才走双栏；[GSYAdaptiveNavigation](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L338-L434) 单例挂载 [detailNavigatorKey](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L371) 与 [popDetailToRoot](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L378-L384) 服务分档回退。默认实现 [MaterialAdaptiveNavigationDelegate.openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L305-L326) 双栏走内嵌 Navigator、单栏兜底走根 `Navigator.of(context).push`，返回 Future 语义与原 `Navigator.push` 完全一致（保 [notify_page](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/notify/notify_page.dart) 里 `.then((_) => _forceRefresh())` 生效）。Shell 侧 [GSYTabBarWidget.build](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L207-L266) 在 useRail 分支上叠一层 `Row(Expanded(flex:42, master), VerticalDivider, Expanded(flex:58, Navigator(key: detailNavigatorKey)))`，flex 比对齐 [GSYBreakpoints.masterMaxRatio=0.42](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart)；空态由 [GSYTwoPaneDetailPlaceholder](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L447-L483) 承担并走 l10n。分档回退：[dispose](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L88-L96) + [didChangeMetrics](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L99-L120) 在 resize 回单栏或组件销毁时调 `popDetailToRoot` 清空内嵌栈，避免 detail 栈渗漏到单栏。用户偏好："强制全屏详情"开关加到 [HomeDrawer](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/widget/home_drawer.dart#L218-L246)（Consumer + SwitchListTile），provider 层新增 [AppForceFullScreenDetailState](file:///d:/workspace/project/gsy_github_app_flutter/lib/provider/app_state_provider.dart#L48-L64) 做 Riverpod ↔ delegate 状态镜像，[Config.FORCE_FULL_SCREEN_DETAIL](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/config/config.dart#L27) 走 [LocalStorage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/local/local_storage.dart) 持久化；[UserRepository.initUserInfo](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/repositories/user_repository.dart#L197-L201) 启动时读回，`change()` 时同步 `GSYAdaptiveNavigation.instance.setForceFullScreenDetail(...)` 让非 Riverpod 消费点（如 navigator_utils 主分派）也能读到最新值 —— delegate **不反向依赖** Riverpod ref，可单测。消费点集中改造：[trend_page.dart#L91](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/trend/trend_page.dart#L91)（保留 OpenContainer 单栏动画作为 fallback）、[navigator_utils.dart#L104](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L104)（goReposDetail）、[navigator_utils.dart#L198](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L198)（goIssueDetail），一次性覆盖 Home 三 tab 主入口 detail 跳转。l10n 四语齐备：`two_pane_detail_empty_title` / `two_pane_detail_empty_hint` / `force_full_screen_detail_title` / `force_full_screen_detail_subtitle` 在 [app_zh.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/app_zh.arb) / [app_en.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/app_en.arb) / [app_ja.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/app_ja.arb) / [app_ko.arb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/localization/app_ko.arb) 全部落齐。契约测试补 7 case（canShowTwoPane 三分档 + setForceFullScreenDetail 立即生效 + openDetail 双栏 push 到 detailNavigatorKey / forceFull 走根 Navigator + popDetailToRoot 清栈与安全 no-op + resetDelegateForTest 换新 key）至 [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart#L442-L658)，`fvm flutter test test/common/style/gsy_adaptive_shell_test.dart` 24 case 全绿；`fvm dart analyze` 无新增 issue。真机证据（fixture：CarSmallGuo × Mi Pad，Home 三 tab）：[p2s2_00_compact_default.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s2_00_compact_default.png)（460dp 竖屏 bottom tab、单栏，detail 未挂载）/ [p2s2_01_medium_rail.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s2_01_medium_rail.png)（density 260 竖屏 → rail + 单栏，flex 42:58 未触发）/ [p2s2_02_expanded_two_pane.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s2_02_expanded_two_pane.png)（density 260 横屏 → rail + master 42% + VerticalDivider + detail 58% GSYTwoPaneDetailPlaceholder 显示"选中左侧任意项 / 选中的详情将在此处展开"）/ [p2s2_05_drawer_toggle_on.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s2_05_drawer_toggle_on.png)（drawer 里"强制全屏详情"SwitchListTile ON + 副标题"大屏下始终以全屏方式打开详情，关闭双栏"，随后重启 process 通过 SharedPreferences 持久化验证 —— 见 dump 记录 `checked="true"`）；随附 [p2s2_expanded_ui.xml](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/p2s2_expanded_ui.xml) 保留 expanded 分档 uiautomator dump 作为 layout tree 复核凭证；`logcat -d` 0 flutter Exception / FATAL。**已知真机缺口（显式登记）**：（1）Master-Detail 主流程只在 Home 三 tab（trend / dynamic / notify）+ 通用 `goReposDetail` / `goIssueDetail` 覆盖，其它二级导航容器（Discussion 详情、Compare、Search 结果）仍走单栏，纳入 P2 §2 后续迭代；（2）双栏切 tab 时 detail 栈按契约"保留但监听分档回退"，未再针对每个 detail 页做"切 tab 保留栈 + 回到该 tab 看到原 detail"的真机脚本化冒烟（契约由 `popDetailToRoot 空栈时安全 no-op` 单测兜底）；（3）折叠屏 hinge 感知未消费，等 P3。
- **§2 Master-Detail M1/M2 fixup（✅ 已完成，2026-09-02 独立 reviewer 闭环）**：§2 首轮落地后 reviewer 独立扫出 2 条 Major 语义缺口 —— **M1** drawer 里翻转"强制全屏详情"开关后 shell（`GSYTabBarWidget`）不 rebuild、双栏 UI 保留，直到下次 rotation / 分档抖动才对齐；**M2** master tab 切换时 detail 内嵌栈保留上一 tab 的 detail 页，出现"Trend 打开仓库 A → 切 Dynamic tab，右列仍显示 A 仓库详情"的跨 tab 语义错位。方案 1 修复：（a）[GSYTabBarWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L10-L70) 从 `StatefulWidget` 迁到 `ConsumerStatefulWidget`，[build() 里 `ref.watch(appForceFullScreenDetailStateProvider)`](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L236-L239) 订阅 provider 变更信号（不是拿值），让 SwitchListTile 翻转即时驱动 shell rebuild → Row 双栏分支消失回退单栏；（b）[_navigationTapClick](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L139-L163) 与 [_navigationPageChanged](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L123-L137) 里均调 `GSYAdaptiveNavigation.instance.popDetailToRoot()`，覆盖 rail tap（不经过 PageView.onPageChanged）与 PageView 滑动两条路径；（c）[dispose](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L88-L98) 里补一次 `popDetailToRoot`，防止 shell 卸载后 detail 栈渗漏。契约测试补 2 case（`M1: 翻转 provider(true) 后 shell 立刻回退单栏`：断言 `Row` 数量减少 + `detailNavigatorKey.currentState == null`；`M2: 切 master tab 时 detail 栈 pop 到根`：先 push 一个 marker widget 到 detailNavigator，切 rail 后断言 `find.byKey(markerKey) == findsNothing` + `detailKey.currentState!.canPop() == false`）至 [gsy_adaptive_shell_test.dart#L665-L816](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart#L665-L816)，`fvm flutter test test/common/style/gsy_adaptive_shell_test.dart` 26 case 全绿；`fvm dart analyze` 无新增 issue。真机证据（同一 fixture CarSmallGuo × Xiaomi Pad，rotation=1 + density=240）：[m1m2_20260902_1604/06_back_to_two_pane.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/m1m2_20260902_1604/06_back_to_two_pane.png)（drawer 关闭强制全屏后立即回双栏 + placeholder 显示"选择左侧任意项 / 选中的详情将在此处展开"）/ [m1m2_20260902_1604/15_final_single_pane_confirmed.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/m1m2_20260902_1604/15_final_single_pane_confirmed.png)（drawer 里再翻回 ON 后动态列表卡片占满整个 x 轴、placeholder 从 UI 树移除、`uiautomator dump` 断言 `placeholder marker count == 0` + `elements in right-pane range == 0`），**M1 双向可逆性得到视觉+dump 双重验证**。ADR-0005 同批补上"Master-Detail 契约与 Shell 集成"演进段（把 §2 首轮 + M1/M2 fixup 一起定型），[ADR-0005 §Master-Detail 契约与 Shell 集成](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)。**已知真机缺口显式登记**：M2 的真机端到端脚本（"detail 里 push 页面 → tap rail 切 tab → 观察 detail 回 placeholder"）受"MIUI + wm density 240 后动态卡片 InkWell hit-test 不稳"阻塞（`adb input tap` 命中卡片区域后无响应，rail tap 与 drawer 开关 tap 均正常），M2 契约由 widget test 承担；后续要补上真机 M2 全链路证据，前置依赖是切换到 Pixel 系列 physical device（无 MIUI 输入映射干扰）或引入 `flutter_driver` / `integration_test`（本仓库当前未启用，见 AGENTS.md §"工具选型"）。
- **§3 MyPage stats 5 列折栏（✅ 已完成，2026-09-02）**：抽象层新增 [wrapUserStatsBar](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L96-L99) / [userStatsBarHeight](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L109) 两个契约方法。默认 [MaterialAdaptiveNavigationDelegate](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L173-L327) 排布：compact / expanded 单行 5 列 + 4 条 `0.3px x 40px` 竖分隔（高度 70）；medium 折成 3 + 2 双行（高度 130），行内分隔沿用同款 divider。落地点两处：[UserHeaderBottom.build](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/widget/user_header.dart#L330-L414) 把手写 Row(5 Expanded + 4 divider) 换成 `GSYAdaptiveNavigation.instance.wrapUserStatsBar(items: [...5])`；[base_person_state.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/base_person_state.dart#L119-L131) 把硬编码 `bottomSize = 70` 换成 `GSYAdaptiveNavigation.instance.userStatsBarHeight(context)`，避免 SliverPersistentHeader 与 delegate 排布骨架脱钩。契约测试新增 6 case（compact / medium / expanded 三档 layout + 高度 + items!=5 assert + setDelegate 后走 sentinel）至 [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart)，`fvm flutter test test/common/style/gsy_adaptive_shell_test.dart` 全绿。真机证据：[p2s3_compact_single_row.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/my_page_stats_20260902_1210/p2s3_compact_single_row.png)（460dp 竖屏单行 5 列：仓库 44 / 粉丝 2 / 关注 4 / 星标 52 / 荣耀 55）/ [p2s3_medium_double_row.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/my_page_stats_20260902_1210/p2s3_medium_double_row.png)（横屏折成 3+2：上排"仓库 44 / 粉丝 2 / 关注 4"、下排"星标 52 / 荣耀 55"）/ [p2s3_expanded_no_crash.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/evidence/my_page_stats_20260902_1210/p2s3_expanded_no_crash.png)（wm density 240 撑到 1440dp，UI 不崩、rail 96dp 宽正常）；`logcat -d` 0 flutter Exception / FATAL；冒烟脚本沉淀到 [tool/ai/smoke/open_my_page_stats.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/open_my_page_stats.ps1)。**已知真机缺口（不糊，显式登记）**：expanded 分档真机没能自动 tap 到 "我的" tab（density 240 下 activity rebuild 会把 GSYTabBarWidget selectedIndex 归零，rail 3 项物理坐标随 density 变化不稳，3 次尝试均未命中），因此 expanded 单行契约由契约单测 `expanded 窗口 → 单行 5 列 + 高度 70` 保证，真机只留"UI 不崩溃"证据；后续若要补上真机 expanded stats 单行截图，前置依赖是把 GSYTabBarWidget 的 selectedIndex 持久化到 provider 层（不在本轮 §3 范围内）。
- ~~MyPage stats 5 列在 medium 折成 3 + 2 或 2 + 2 + 1。（🚧 待启动，P1 遗留缺口）~~ → 已在 §3 落地为 3 + 2。
- ~~抽象层预置 `GSYTwoPane`（待新增到 gsy_adaptive_shell.dart 同层），语义只有 `master` / `detail` 两个 slot~~ → §2 已用「delegate 契约 + shell 内嵌 Navigator」替代方案落地，不再引入独立 `GSYTwoPane` widget。理由：Master-Detail 的本质是"detail 挂到独立 Navigator 栈里"，把这个能力挂在 delegate + shell 上比再包一层 `GSYTwoPane` 更贴 GSY 现有 layering。

### P3：折叠屏 posture / hinge（🚧 未启动）

- 消费 [GSYResponsiveContext.verticalHinge](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L52-L62)：Master-Detail 时把 detail 顶到 hinge 右侧，避免文字被物理铰链分割。
- posture 变化时如何过渡（flat → half-opened → book / tabletop）需要产品拍板：GSY 是"折叠不影响布局，全按宽度算"还是"半开时切阅读模式"。
- 依赖 Flutter Framework `DisplayFeature` API + Samsung Galaxy Fold 系列 / Surface Duo 真机验证——**无真机时不动**，避免猜测。

### P4：边缘设备与骨架层（🚧 未启动）

- Chromebook / Android on desktop：鼠标滚轮 + 键盘 Tab / Enter 焦点管理。
- Windows / macOS / Linux desktop embedding：目前 GSY 只出 Android/iOS，desktop 走还是不走要先决 4.4 边界。
- 极窄 posture（Fold 关闭态 316dp × 720dp）：所有页面在 compact 下端渲染都要能挤下，是 P2 卡片限宽的对称测试。

### 挑活契约

- 从本节挑一个 wave 开工前，**必须先读 [ADR-0005](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)**，确认新增能力是加到 delegate 层还是页面层。
- 新增 shell 层能力（rail / dual-pane / drawer 变形）**只允许扩展 [GSYAdaptiveNavigationDelegate](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L41-L54)**，不允许在页面里手写 `NavigationRail` / `AdaptiveScaffold`。
- 断点判定**必须走** [GSYResponsiveContext](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L38-L62) extension，禁止在页面里手写 `MediaQuery.sizeOf(ctx).width < 600`。
- 抽象层改动必须先更新 [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart)（契约测试）与 [gsy_responsive_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_responsive_test.dart)（断点测试），再改实现。

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

[tool/ai/smoke/](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/) 现在有（2026-09-02 全面回归 `mcp_dart`，adb 坐标脚本已删）：

- [open_pr_timeline.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_pr_timeline.md) —— PR timeline 冒烟入口
- [open_home_dynamic.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.md) —— 首页动态 tab 走完刷新/加载/滚动
- [open_repo_discussions_tab.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_repo_discussions_tab.md) —— 仓库详情 → 讨论 tab

还差：

- `open_search_code.md`：Search → Code tab → 输关键字
- `open_pr_files.md`：进 PR → 变更文件页

---

## 六、下一步该干什么

按不同偏好给三条路，任选：

1. **最低阻力**：补 2.1 里 `marked_as_duplicate/unmarked_as_duplicate` 或 `dequeued/enqueued` 两组 action。10 分钟一个 commit（`auto_merge_*` 已在 2026-07-06 收）。
2. **有分量功能**：3.1 的 Discussions 阅读页。复用 issue timeline 骨架，让 discussion 事件从"看得到 → 点得进 → 读得完"闭环。
3. **先划边界**：先决 4.1，把"允许的写操作清单"写进 AGENTS.md；边界清楚后 3.2 / 3.3 才有下决心的依据。
