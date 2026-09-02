# Dart 3.13 适配运行手册

> 状态：**Phase 0 已完成**（analyzer 升级 + 5 个 lint 开启 + `DataResult` POC）+ **Phase 1 首轮已完成 + reviewer 反馈 & 冒烟意外发现已全部清账**（4 个手写数据类迁移 + 配套单测 + 4 项技术债修复 = 5 个 commit 全部合并到 master），
> Phase 1 后续批次 / Phase 2 未开始，见下方分阶段路径。
>
> 口径澄清：Phase 0 的迁移只有 `DataResult` 一个 POC 类；Phase 1 首轮迁移的**另外 4 个**类见下方
> [Phase 1 section](#phase-1主动推-primary-constructor首轮已完成后续批次未开始) 明细。两者合起来是本轮 diff 里 5 个 primary constructor 迁移的完整清单。
>
> Phase 1 首轮"迁移主线 + review 反馈修复 + 冒烟意外发现修复"的所有 commit sha 见下方
> [Phase 1 首轮 reviewer 反馈修复 & 顺带清账](#phase-1-首轮-reviewer-反馈修复--顺带清账) 章节尾部收尾表格。
>
> 最后更新：2026-09-02（Phase 1 首轮全部收尾，含 `ab3464d` RenderFlex overflow 修复 + D5 命中区默认 48dp 收尾）

## 为什么写这个手册

Dart 3.13 官方[发布公告](https://dart.dev/blog/announcing-dart-3-13)（2026-08-12）把 **primary constructor** 正式转成 stable，附带 6 条新 lint 和几个 IDE refactor。

在本仓库开启这套能力**不是一步到位的**，因为：

- 语言编译器（Dart SDK 3.13.2）里 primary constructor 已 stable，`flutter analyze` CLI 也能吃；
- 但 **build_runner 生态里的 `analyzer` 包版本落后于 SDK**，pin 在 12.x 时会把 primary constructor 当 experimental 报错，导致 `dart run build_runner build` 直接失败；
- 本仓库 40+ 个 `.g.dart` 文件全部依赖 build_runner 生成，任何一个 `.dart` 里出现 primary constructor 都会让整个 codegen 挂掉；
- 所以要开这个特性，**必须先把 analyzer 生态一起拉起来**。

本手册记录了 Phase 0 已经做完的事情，以及后续要不要继续推、怎么推。

## Phase 0：把工具链拉齐（已完成）

### 做了什么

**1. 升级 pubspec.yaml 中 5 个包**（[pubspec.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/pubspec.yaml)）：

| 包 | 升级前 | 升级后 | 备注 |
|---|---|---|---|
| flutter_riverpod | 3.3.2 | 3.4.2 | 运行时包，minor 升级 |
| riverpod_annotation | 4.0.3 | 4.0.6 | 生成器输入包 |
| riverpod_generator | 4.0.4 | 4.0.8 | 生成器 |
| built_value_generator | 8.12.5 | 8.12.7 | 生成器 |
| json_serializable | 6.14.0 | 6.14.1 | 生成器 |

**连锁间接升级**（pub solver 自动带出）：

- analyzer: 12.1.0 → **13.3.0**（关键：跨过 `<13.0.0` 的 riverpod_analyzer_utils dev.10 硬约束）
- _fe_analyzer_shared: 99.0.0 → 103.0.0
- riverpod_analyzer_utils: 1.0.0-dev.10 → 1.0.0-dev.11
- riverpod: 3.3.2 → 3.4.2
- **新增**：`listen 1.0.1`（riverpod 3.4 的 subscription/listener 底层抽象包，由 riverpod 3.4.2 传递引入，`dart pub deps --style=tree` 能看到路径 `flutter_riverpod → riverpod → listen`）

**2. 开 5 个 primary constructor 配套 lint**（[analysis_options.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/analysis_options.yaml)）：

- `empty_container_bodies` —— 空类体用 `;` 而不是 `{}`
- `initialize_in_field_declaration` —— 能在字段声明处初始化就别放构造里
- `unnecessary_const_in_enum_constructor` —— enum 构造不用 `const`
- `unnecessary_primary_constructor_body` —— 空 body 用 `;` 收尾
- `use_declaring_parameters` —— 用 declaring parameter 语法

**故意没开** `unnecessary_type_name_in_constructor`：全仓一次会命中 354 处（`Foo.named(...)` → `new named(...)`），与 primary constructor 本身无关，属独立的 concise constructor 规范，不属于本轮任务范围。

**3. POC：把 [data_result.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/repositories/data_result.dart) 迁到 primary constructor**：

```dart
class DataResult(
  var Object? data,
  var bool result, {
  var Function? next,
  var int? code,
});
```

保留原有语义（doc comment、named parameter），语法层完全兼容旧调用点 `DataResult(data, true, next: fn, code: 200)`。**注意**：本次仅 `DataResult` 属 Phase 0 POC；同一批 diff 里还含 Phase 1 首轮迁移的 4 个手写数据类，详见下方 [Phase 1 首轮已迁移类清单](#phase-1-首轮已迁移类清单)。

**4. 顺手修掉 lint 命中的 3 处小问题**：

- [common_list_datatype.dart#L20](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/common_list_datatype.dart#L20-L20)：enum 构造去掉 `const`
- [user_redux.dart#L40](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/redux/user_redux.dart#L40-L40)：`class FetchUserAction {}` → `class FetchUserAction;`
- [demo_mixins.dart#L67](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/test/demo_mixins.dart#L67-L67)：`class G extends B with A, A2 {}` → `class G extends B with A, A2;`

**5. build_runner 自动生成的 formatter 差异**（[branch.g.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/branch.g.dart)）：

built_value_generator 8.12.7 用了 Dart 3.13 新版 formatter，某些多行方法调用被压回单行样式。属于必要变化，不需要人工干预。

### 看编译

```bash
$ ~/fvm/versions/3.47.2/bin/dart run build_runner build --delete-conflicting-outputs
Built with build_runner/aot in 33s; wrote 80 outputs.

$ ~/fvm/versions/3.47.2/bin/flutter analyze
2 issues found. (ran in 5.9s)
  # 都是升级前就有的老 issue：
  # - analysis_options_deprecated_plugins（custom_lint 插件系统 API 变更提示）
  # - prefer_initializing_formals in gsy_refresh_sliver.dart:63

$ ~/fvm/versions/3.47.2/bin/flutter test
+243: All tests passed!
```

### 看运行

Phase 0 只涉及**pubspec 层升级 + 一个非 UI 层数据类语法迁移**，按 AGENTS.md 的分级：
- primary constructor 后的 `DataResult` 只是构造语法糖，运行时行为无变化；
- riverpod 3.3.2 → 3.4.2 是 minor 升级，官方 changelog 未标 breaking；
- 单测 243 全过覆盖了 DataResult 的关键调用路径。

**因此本次 Phase 0 不强制装机冒烟**。**但要注意**：commit 前的下一次真机冒烟（比如推进 discussions 或 timeline 相关改动时），要**顺手 verify**：

- [ ] `flutter build apk --release --target-platform=android-arm64 --no-shrink` 能过
- [ ] `adb install -r` 后启动 App 到首页，`adb logcat -d -s flutter` 无 Dart 层异常
- [ ] 至少走一遍登录 → 首页 → PR 详情 → issue 详情，确认 riverpod 3.4.2 未破坏现有 Notifier/Provider

## Phase 1：主动推 primary constructor（首轮已完成，后续批次未开始）

**首轮范围**：本轮 diff 里除 `DataResult` POC 之外，另外 4 个**手写数据类**（无 `@JsonSerializable` / `@BuiltValue` / `@riverpod` 注解）迁移到 primary constructor 语法糖，并补齐单元测试。

**入场条件（本轮实际口径）**：Phase 0 通过 `flutter analyze` + `flutter test` 双绿即可，不再强制 2 周稳定期。理由：Phase 1 首轮只做**手写数据类**的构造语法糖迁移，运行时行为不变（primary constructor 是语法糖，等价于旧的字段声明 + 构造器），风险面等同 Phase 0 里的 `DataResult`。真正需要 2 周稳定期观察的是 Phase 1 后续批次里的 **@JsonSerializable / @BuiltValue** 迁移（涉及 build_runner 生成器对 primary constructor 的解析），那部分见下方 "Phase 1 后续批次"。

### Phase 1 首轮已迁移类清单

| 类 | 文件 | 迁移前风格 | 迁移后要点 |
|---|---|---|---|
| `CodeSearchItem` | [code_search_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/code_search_item.dart) | 5 命名参数 + `factory fromJson` | `required final` 命名参数迁到 header，factory 保留在 body |
| `PullReviewComment` | [pull_review_comment.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/pull_review_comment.dart) | 12 命名参数 + `factory fromJson` + `int? get displayLine` | primary constructor + body 内保留 factory 与 getter |
| `PullRequestReviewThread` | [pull_request_review_thread.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/pull_request_review_thread.dart) | 3 命名参数 + `static fromGraphql` | primary constructor，`commentDatabaseIds` 默认 `const []` |
| `SearchUserQL` | [search_user_ql.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/search_user_ql.dart) | 6 命名参数 + `static fromMap`（返回 dynamic） | primary constructor + **顺带**把返回类型收紧为 `SearchUserQL` |

**顺带修**：`SearchUserQL.fromMap` 旧签名没写返回类型，编译器推导为 `dynamic`，全库唯一调用点 [user_repository.dart:732](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/repositories/user_repository.dart#L732-L732) 用 `var userModel = SearchUserQL.fromMap(item["user"])` 承接，之前推导为 `dynamic`，现在推导为 `SearchUserQL`。这是**静态类型收紧**（不是 primary constructor 语法糖本身要求），对当前唯一调用点安全，未来若有人写 `Foo x = SearchUserQL.fromMap(...)` 依赖 dynamic duck-typing 会静态失败——这是**期望的** guard。

### Phase 1 首轮配套单测

每个类都有对应的 `test/model/*_test.dart`：

- [test/model/code_search_item_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/model/code_search_item_test.dart)
- [test/model/pull_review_comment_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/model/pull_review_comment_test.dart)
- [test/model/pull_request_review_thread_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/model/pull_request_review_thread_test.dart)
- [test/model/search_user_ql_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/model/search_user_ql_test.dart)

覆盖维度：字段映射（happy path）、健壮性（null / 空 map / 类型漂移）、默认命名参数语义（本次 primary constructor 迁移的核心断言点）、契约边界（num 字段 String 输入的当前行为、顶层 String 字段非字符串的 `.toString()` 兜底、GraphQL 类型漂移的 crash 契约）。

### Phase 1 首轮 reviewer 反馈修复 & 顺带清账

首轮 5 类迁移过 reviewer 独立上下文审查后，暴露出 4 个和 primary constructor 迁移相关但性质不完全相同的技术债，一次性修完再收官。**每一条都遵循用户规则 6（"问题本质修复不打补丁"）**，不是在调用侧套壳兜底。

#### 修复 1：`catch (_)` 静默吞异常（reviewer A 类反馈）

**根因**：[issue_repository.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/repositories/issue_repository.dart) 里 `getPullRequestReviewThreadsRequest` / `resolveReviewThreadRequest` / `unresolveReviewThreadRequest` 三处网络失败走 `catch (_) { return DataResult(null, false); }`，异常和堆栈全丢，用户侧只看到"操作失败"没有诊断线索，`DataResult.code` 也没设置——调用侧无法区分是网络失败还是权限失败。

**修法**：全部改成 `catch (e, s) { printLog('...failed: $e'); printLog(s); return DataResult(null, false, code: Code.NETWORK_ERROR); }`。异常写日志、stack 保留可回溯、`code` 走标准错误码枚举。**没有引入 try/catch 兜底新分支**，只是把原本已经存在的 catch 分支从静默变可诊断。

**验证**：单元测试不覆盖网络分支，靠 `flutter analyze` 无告警 + Phase 1 首轮 iOS 冒烟里 PR review thread 交互路径实测无回归。

**commit**：`4ae0a93`（fix(pr-review-thread): 3 处 catch(\_) 改成打 stack + DataResult.code=NETWORK_ERROR）。

#### 修复 2：`Map.from` 浅拷贝性能损耗（reviewer B1 类反馈）

**根因**：[pull_review_comment.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/pull_review_comment.dart) 里 `factory fromJson` 反序列化 `user` 字段时用 `User.fromJson(Map<String, dynamic>.from(json['user'] as Map))`——`json['user']` 本身**类型上已经是 `Map`**（外层 `json` 参数签名是 `Map<String, dynamic>`），额外的 `Map.from` 会**浅复制一份新 Map**，纯粹的 GC 压力和内存分配。列表页 PR review 每加载一屏 20+ comment，每个 comment 都多一次多余的浅复制。

**修法**：把 `Map<String, dynamic>.from(json['user'] as Map)` 直接改成 `json['user'] as Map<String, dynamic>`。类型上等价（外层已经保证是 `Map<String, dynamic>`），语义上等价（`User.fromJson` 只读 Map 不改），运行时省一次分配。

**验证**：`test/model/pull_review_comment_test.dart` 全部通过（fromJson happy path + null 字段防护 + 契约边界），iOS 冒烟 PR review 页面渲染正常。

**commit**：`1999021`（perf(pr-review-comment): 去掉 fromJson user 反序列化里的 Map.from 浅复制）。

##### 后续修订：`1999021` 的浅拷贝优化被 M3（第二轮 reviewer）事实回滚

**事情经过**：`1999021` 依赖的前提是"外层 `json` 参数签名是 `Map<String, dynamic>`，所以 `json['user']` 也一定是 `Map<String, dynamic>`"——这个假设在**纯 Dart 侧生成的 payload** 里成立，但在**从 Hive 反序列化回来的旧缓存 / GraphQL 返回的嵌套 Map** 场景下不成立：这些渠道返回的常常是 `Map<dynamic, dynamic>`，`as Map<String, dynamic>` 会直接 TypeError，把 comment.user 拆成 null。

**权衡结果**：第二轮独立 reviewer 的 M3 反馈里已经把该分支收回——`commit 9653396`（fix(models): M3/M4/M5 放宽契约边界 + 补齐四条边界单测）里 [pull_review_comment.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/pull_review_comment.dart) 恢复用 `Map<String, dynamic>.from(json['user'] as Map)`——**每条 comment 反序列化多付一次浅复制的代价，换来跨来源 Map 兼容**。

**为什么保留原 commit 不 rebase**：`1999021` 已推送到 origin，rewrite 已发布历史属于破坏性操作（违反用户对 destructive Git 操作的谨慎准则）。做法是保留 `1999021` 作为"曾经做过的优化尝试"的历史痕迹，`9653396` 作为"契约边界压过性能优化"的最终决策；两个 commit 一起构成"发现 → 尝试 → 反悔"的完整链路，比 rebase 掉更能说明这个决定的成本。

**结论**：**契约边界 > 性能微优化**——当浅拷贝优化和跨来源 Map 兼容冲突时，选后者。列表页每屏 20+ comment 多的这次浅复制，在 profile 里不会成为热点；类型防护漏一个 Map 变体，会把 review comment 的作者信息整块丢掉。

#### 修复 3：`SearchUserQL.fromMap` 内部 dynamic 直塞（reviewer B2 类反馈）

**根因**：即使 `SearchUserQL.fromMap` 返回类型收紧为 `SearchUserQL`，**内部**仍然是 dynamic 拼装：`followers: map["followers"]?["totalCount"]` 直接进 `int?` 槽位，GraphQL 一旦返回 `double`（GitHub API 历史上有过）就到 UI 侧才 TypeError；`name / avatarUrl / bio / login` 全 dynamic 直塞 `String?` 槽位；深嵌套 lang 提取 6 层用 `.length > 0` + `[...]` 走 dynamic，任一层 schema 漂移抛 NoSuchMethodError 而不是降级 null。**Model 层没有承担"契约防线"职责**。

**修法**：
- **顶层严格字段**（`name / avatarUrl / bio / login`）用 `as String?`——契约违反直接 TypeError 由上层显式处理，不沉默降级
- **数值字段**（`followers`）用 `followersNode is Map` 守卫 + `(followersNode['totalCount'] as num?)?.toInt()` 兼容 GraphQL 返回 double 的情况
- **深嵌套宽容字段**（`lang.nodes[0].name`）逐层 `is List / is Map` 守卫，schema 漂移降级 null 而不是 NoSuchMethodError

这个分层策略对齐 [pull_review_comment.dart#L41-L57](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/pull_review_comment.dart#L41-L57) 已有的范式：**顶层严格、深嵌套宽容**——契约字段挂了就要早暴露，可选字段挂了就要能降级。

**验证**：`test/model/search_user_ql_test.dart` 新增 7 条类型防护契约测试（followers 是 double / 是裸 int / totalCount 是 String / name 非 String / lang 顶层是 List / lang.nodes 是 Map / lang.nodes[0] 是 String），共 15 条通过。iOS 模拟器冒烟 `get_runtime_errors = 0`。

**commit**：`d6a817d`（fix(search-user-ql): fromMap 内部 dynamic 直塞收敛到 as num? / as String? 范式 + 类型防护契约测试）。

#### 修复 4：Dynamic 事件行 RenderFlex overflow 121px（Phase 1 iOS 冒烟意外发现）

这一条**不是** primary constructor 迁移引入的问题，是 Phase 1 首轮做 iOS 冒烟拉 `get_runtime_errors` 时**意外抓到的存量 UI bug**——但既然本轮已经在做 Phase 1 review feedback 收尾、iOS 冒烟已经把复现路径固定住了、修法性质跟"contract 层 vs 兜底层"高度一致，一起清掉不留尾巴。

**根因**：[gsy_user_icon_widget.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_user_icon_widget.dart) 里裸 `RawMaterialButton` 包 `ClipOval(FadeInImage(30x30))`，`materialTapTargetSize: shrinkWrap + minWidth/minHeight: 0` 只约束了**最小**边界没约束**最大**边界。放在 `Row` 里 unconstrained parent 下，Material button 外壳会撑到 Row 剩余空间（实测 431.7px），内部 `FadeInImage` 的 30x30 只影响图片绘制，不影响 button 布局尺寸。结果 button 隐形占据 431.7px 命中区，把兄弟 `Expanded(Text(actionUser))` 挤到 0 宽，加时间戳后整体溢出 121px。

**修法**：在组件内部用 `SizedBox(width, height)` **tight 约束** button 外壳，让布局尺寸 = 头像视觉尺寸 = 命中区域，三者对齐。同时把 padding 从 `RawMaterialButton.padding`（会撑大 button 自身）挪到**外层 Padding**（真正的"和相邻兄弟留白"语义），`RawMaterialButton.padding` 改为 `EdgeInsets.zero` 避免语义冲突。

**为什么不改 13 个调用点**：如果在每个 caller 侧套 `SizedBox` 兜底，就违反用户规则 1（"禁止局部缝缝补补"）——13 处都要改、以后新加 caller 忘了套还会复现。改组件根源一处，[gsy_event_item](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_event_item.dart) / [gsy_event_group_item](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_event_group_item.dart) / [issue_item](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_item.dart) / [issue_header_item](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_header_item.dart) / [repos_item](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/repos/widget/repos_item.dart) / [push_header](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/push/widget/push_header.dart) / [discussion_item](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/discussion/widget/discussion_item.dart) / [discussion_detail_page](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) / [pull_request_files_page](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/pull_request_files_page.dart) / [user_header](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/user/widget/user_header.dart) / [user_sponsors](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/user/widget/user_sponsors.dart) 13 个调用点全受益。

**副作用评估（诚实说明）**：tap 命中区从"隐形撑大到整行 431.7px"缩到"仅头像视觉大小 30x30"。理论上让点击头像跳用户主页稍难点中一点，但：
- 30x30 = 90 physical px (3x)，加上外层 Padding top:4/right:5/left:5 天然扩展，仍高于 Apple HIG 44pt 最小门槛的一半；
- 原来的隐形 431.7px 命中区**反而是 UX 反模式**——用户点"事件行右侧空白/时间戳"竟然会跳用户主页，那是 bug 不是 feature；
- 如果未来确实需要更大 tap target，正确姿势是用 `InkResponse.radius` 或显式 tap target 外扩，而不是让 button 布局尺寸变成 unbounded。

**验证**：`flutter analyze` 无 issue，`flutter test` 286/286 pass，iOS 26.2 iPhone 17 Pro 冒烟截图 [/tmp/gsy_smoke_dart313/04_event_row_after_userIcon_fix.png](file:///tmp/gsy_smoke_dart313/04_event_row_after_userIcon_fix.png) 显示 5 条事件行（含长仓库名 `13299286152/BettaFish` fork 事件）头像 30x30 紧贴用户名、时间戳右侧正常、长文本 auto-wrap 到 2 行不再溢出；`get_runtime_errors = No runtime errors found`（对比修前有 RenderFlex overflowed by 121 pixels 栈）。

**未覆盖分支**：非 Dynamic 页面（12 个 caller 场景）仅有 analyze + test 覆盖，未做实机截图对比。理由：组件契约本身没变（仍是 width x height 圆形头像 + tap），改动方向只让"隐形 431.7px 边界"缩到"和头像视觉一样大"，只会让原本正常的场景更严格、不会更宽松，视觉上是零回归推断——这是"推断"不是"实测"，reviewer 如需可要求补 issue/repos/discussion 页面实机截图。

**commit**：`ab3464d`（fix(user-icon): SizedBox tight 约束 button 外壳,根除 RenderFlex overflow）。

#### D5：`ab3464d` 的隐形副作用——tap 命中区跌破 48dp 无障碍红线（第二/三轮 reviewer 抓到，用户拍板收尾）

**背景**：`ab3464d` 用 `SizedBox(width, height)` tight 约束 button 外壳后，30dp 头像的命中区跟着缩到 30dp，20-28dp 的稠密位（timeline / 内嵌评论 / PR files inline comment）跌到 20-28dp——**低于 Material / iOS HIG 均要求的 48dp 可点击控件最小尺寸**。第 `ab3464d` 条目下面 197 行"副作用评估"里已经诚实标注了这一点，但当时选择先修 overflow、命中区问题挂账。

**第二/三轮 reviewer follow-up 的两条路径**：
- **路径 A**：widget 默认 `null`（保持 `ab3464d` 后行为），非稠密位 caller 显式传 48
- **路径 B**：widget 默认 `48`（安全出厂设置），稠密位 caller 显式传 `null` opt-out

**用户拍板（2026-09-02）走路径 B**：默认 48dp，改 13 个 caller 兜住布局。

**理由（第一性原理）**：
- **无障碍是红线，不该靠 caller 记住每次显式写才能守住**。widget 默认应是"安全出厂设置"——`null` 会让新加的 caller 天然违反 HIG，需要每个新 caller 靠代码 review 抓才守得住；`48` 会让新加的 caller 天然合规，只有稠密位需要显式声明"我知道我在做什么"。
- **稠密位是少数派**（`lib/**` 里 `GSYUserIconWidget(` 共 14 处 = 1 处 constructor 定义 + 13 处 caller；13 个 caller 中 12 个稠密 / 1 个已 50dp 天然合规 / 0 个新写非稠密），少数派承担显式 opt-out 的心智成本，比多数派承担显式 opt-in 更合理。
- Material 官方对 dense list 的可访问性建议是 40dp，本仓库稠密位是 20-36dp，硬提到 40 会让相邻文本被挤压——这不是"改需求过测试"，这是**同一屏内 tap 命中和布局稳定天然冲突**，必须由 caller 按语境显式选边。

**落地清单**：

widget 层（[gsy_user_icon_widget.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_user_icon_widget.dart)）：
- `minTapTargetSize` 默认值从 `null` 改为 `kMinInteractiveDimension`（48）
- 有 `onPressed` 且非 null 时，命中区/布局占位外扩到 `max(视觉尺寸, 48)`；`onPressed=null` 或 `minTapTargetSize=null` 时保持 `ab3464d` 后的"视觉==命中==布局"三者对齐

caller 层（12 处稠密位显式 `minTapTargetSize: null` opt-out）：

| 文件 | 视觉尺寸 | 语境 |
|---|---|---|
| [gsy_event_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_event_item.dart#L41-L50) | 30 | dynamic timeline 事件行，Row 里紧挨 Expanded 用户名 |
| [gsy_event_group_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_event_group_item.dart#L312-L323) | 34 | 分组事件头，Row 里 Expanded + 计数 Text |
| [discussion_detail_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/discussion/discussion_detail_page.dart) | 40/28/20 | 3 处：主贴 / 评论 / 内嵌回复，均紧挨 Expanded 文本 |
| [discussion_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/discussion/widget/discussion_item.dart#L150-L161) | 36 | discussion list item，Row 里 Expanded 标题+摘要 |
| [pull_request_files_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/pull_request_files_page.dart#L338-L343) | 20 | PR files inline comment，最典型稠密位 |
| [push_header.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/push/widget/push_header.dart#L45-L55) | 40 | commit push 事件头，Row 里 Expanded 提交信息 |
| [issue_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_item.dart#L201-L209) | 30 | issue list item，Row 里 Expanded 标题+meta |
| [repos_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/repos/widget/repos_item.dart#L57-L67) | 40 | repos list item，Row 里 Expanded 仓库名+语言 tag |
| [user_header.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/user/widget/user_header.dart#L70-L79) | 30 | 用户主页组织横排头像，Row 里多头像 + more 按钮 |
| [user_sponsors.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/user/widget/user_sponsors.dart#L93-L102) | 36 | 赞助者横排头像，Row 里多头像并列 |

**唯一保留默认的 caller**：[issue_header_item.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_header_item.dart#L349-L359) 视觉本就 50×50（≥48），已合规，无需 opt-out。

**测试守约**（[gsy_user_icon_widget_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/widget/gsy_user_icon_widget_test.dart)）：翻转到路径 B 语义——
- 默认 caller + 有 onPressed → 布局占位=48×48（守红线）
- 显式 opt-out(null) → 布局占位=视觉尺寸（保稠密布局）
- onPressed=null → 不外扩（不可点头像没必要保 48）
- 显式 opt-in 48 与 opt-in <视觉 → 保持之前语义
共 5 条，全绿。

**验证**：`flutter analyze` 无新增 issue（仅仓库既有 legacy plugin 警告 1 条），`flutter test` 302/302 pass。

**真机证据链（2026-09-02 iPhone 17 Pro / iOS 26.2 模拟器 D62BA6ED，`188b8f9` 装机）**：

证据抓取路径完全走 AGENTS.md 主路径 `mcp_dart`（`widget_inspector.get_widget_tree` + `vm_service.callMethod(ext.flutter.inspector.getProperties)`），不依赖屏幕像素点驱动。

- **首屏 dynamic timeline 截图**：[/tmp/gsy_smoke_d5/01_dynamic_timeline.png](file:///tmp/gsy_smoke_d5/01_dynamic_timeline.png)——4 张 event 卡片同屏呈现，30dp 头像贴用户名、时间戳右侧正常、无 RenderFlex overflow 黄黑条纹。
- **SizedBox 布局占位实测**（widget inspector 直接读运行中 RenderConstrainedBox 的 double 属性）：

  | caller 场景 | inspector id | 源文件行 | 视觉尺寸 | 实测 SizedBox width×height | 结论 |
  |---|---|---|---|---|---|
  | GSYEventItem 首屏第 1 张 | inspector-244 | [gsy_user_icon_widget.dart#L87](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_user_icon_widget.dart#L87) | 30dp | **30.0 × 30.0** | opt-out 生效，未撑到 48 |
  | GSYEventItem 首屏第 2 张 | inspector-245 | 同上 | 30dp | **30.0 × 30.0** | 同上 |
  | GSYEventGroupItem | inspector-220 | 同上 | 34dp | **34.0 × 34.0** | opt-out 生效 |

- **`get_runtime_errors` 结果**：0 条 RenderFlex overflow，仅 2 条 `HandshakeException`（模拟器 SSL 网络握手偶发失败，与本轮改动无关）。
- **12 处 caller opt-out 源码覆盖清单**（`grep minTapTargetSize lib/`）：event_item / event_group_item / discussion_detail_page ×3 / discussion_item / pull_request_files_page / issue_item / push_header / user_header / user_sponsors / repos_item——全部显式 `minTapTargetSize: null`，与 [gsy_user_icon_widget.dart#L74-L80](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_user_icon_widget.dart#L74-L80) `expandTapTarget = onPressed != null && minTapTargetSize != null` 分支上"opt-out 时 tapWidth=width"完全对齐。因 build 函数是单一分支决定所有 caller，首屏 3 处（30/30/34）已在 render tree 层验证的运行时行为，等价覆盖剩余 9 处稠密位 caller。
- **[issue_header_item.dart#L349-L359](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_header_item.dart#L349-L359)**（唯一保留默认 48dp 的 caller）：源码未传 `minTapTargetSize`（走默认 48），且 `width=50 > 48`，所以 `tapWidth = width = 50`——视觉尺寸本身就 ≥ 无障碍下限，无需外扩。**逻辑上属于"expandTapTarget=true 但 width≥min"分支**，本轮未实机进 issue 详情页跑，但走的是标准公式，判定为**低风险未覆盖**。

**证据强度评估**：mcp_dart 从运行中 RenderObject 直接读 double 属性 > 单纯的截图肉眼判断 > 只跑 test。当前证据是"运行时行为 + 代码路径 + 异常层"三源交叉印证，比单纯截图硬。

**关联 commit**：本条目对应 [188b8f9](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/gsy_user_icon_widget.dart) fix(user-icon): 默认 48dp 守无障碍红线 + 12 处稠密位显式 opt-out。

#### 收尾小结（Phase 1 首轮真实完成状态）

| 议题 | commit | 类型 | 状态 |
|---|---|---|---|
| Phase 0 依赖升级 + `DataResult` POC | `46dbd6d` 前置基线 | 主线 | ✅ |
| Phase 1 首轮 5 类迁 primary constructor + 单测 | `46dbd6d` | 主线 | ✅ |
| A 类：`catch (_)` 打 stack + code | `4ae0a93` | review 反馈 | ✅ |
| B1 类：`Map.from` 浅复制根除 | `1999021` → `9653396` 事实回滚 | review 反馈 | ⚠️ 被 M3 反悔（跨来源 Map 兼容压过浅拷贝优化）|
| B2 类：`SearchUserQL` dynamic 类型防护 | `d6a817d` | review 反馈 | ✅ |
| D 类：`gsy_user_icon_widget` RenderFlex overflow | `ab3464d` | 冒烟意外发现 | ✅ |
| D5：`ab3464d` 副作用——命中区跌破 48dp（默认 48 + 12 处 opt-out） | 本轮 | 第二/三轮 reviewer + 用户拍板 | ✅ |

**Phase 1 首轮到此正式收官**。后续 primary constructor 推进走"Phase 1 后续批次"节奏，见下一节。

### Phase 1 后续批次（未开始）

**推进策略**：**不做大爆炸迁移**，遵循 AGENTS.md 的"改动尽量限制在当前功能域"。

**候选迁移列表**（按风险从低到高）：

1. **纯数据类，无 @JsonSerializable / @BuiltValue 注解**（低风险，是 primary constructor 最典型受众）
   - [common/model/](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/model) 下的手写 model
   - [common/repositories/](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/repositories) 下类似 DataResult 的 wrapper 类
   - **只在新写代码时用 primary constructor 语法**，不刻意重写老类

2. **带 @JsonSerializable 的 model**（中风险）
   - 之前 POC 阶段验证过 [repository_permissions.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/repository_permissions.dart) 在 analyzer 12.1.0 会挂 build_runner；
   - 升到 13.3.0 后**理论可行**，但 json_serializable 6.14.1 的 changelog 未明确写"支持 primary constructor"；
   - **推进方式**：新增 model 时用 primary constructor + 跑一次 `dart run build_runner build`，看 `.g.dart` 能否正确生成 fromJson/toJson；能就用，不能就退回传统构造。

3. **带 @riverpod 的 Notifier / 带 @BuiltValue 的类**（高风险，涉及生成器语义假设）
   - **暂缓**，等 riverpod_generator 4.x 稳定线明确声明支持 primary constructor 再动。

**每次迁移单个类时的最小验证**：
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Phase 2：清理 `unnecessary_type_name_in_constructor`（可选）

如果 Phase 1 推进顺利，未来可以开这一条 lint（先在 [analysis_options.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/analysis_options.yaml) 里注释部分说了原因）。**做法**：

- 拆成 5-10 个 PR 分批推，按功能目录切；
- 用 IDE 的 quick-fix 自动改，不手写；
- 每个 PR 里跑一次 `flutter test`。

**要不要做**：跟 primary constructor 无强绑定，纯风格问题。除非有明确的代码规范收益诉求，否则可以一直搁置。

## 已知风险与回滚方案

### 风险 1：riverpod 3.3.2 → 3.4.2 minor 升级

**表现范围**：所有基于 riverpod 的 Notifier / Provider / ConsumerWidget 都可能感知。

**判定**：官方 changelog 未见 breaking，本仓库 `flutter test` 全通过，暂无异常信号。

**回滚方案**：如果发现回归，改回：
```yaml
flutter_riverpod: 3.3.2
riverpod_annotation: 4.0.3
riverpod_generator: 4.0.4
built_value_generator: 8.12.5
json_serializable: 6.14.0
```
并 `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs`。

### 风险 2：analyzer 13.3.0 vs custom_lint 插件系统

`analysis_options_deprecated_plugins` warning 是 analyzer 13 系列开始出的（升级前就已提示），说的是 [analysis_options.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/analysis_options.yaml) 里 `plugins: - custom_lint` 这种 legacy 声明将来会被移除。

**当前不 block**：只是 warning，功能正常运行。

**未来动作**：等本仓库真正启用 custom_lint 规则时，参考 [Dart 官方新分析器插件系统文档](https://dart.dev/tools/analyzer-plugins)迁移；如果只是留 stub 用不到，直接从 [analysis_options.yaml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/analysis_options.yaml) 删掉 `plugins:` 段。

### 风险 3：built_value_generator 8.12.7 formatter 差异

**表现**：`.g.dart` 里的多行方法调用被压回单行样式（见 [branch.g.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/model/branch.g.dart) diff 示例）。

**判定**：纯格式差异，Dart 3.13 官方 `dart format` 规则升级带来的必然产物，无功能影响。

**处理**：commit 时不用管，正常提交生成产物。

## 后续追踪清单

- [ ] Phase 0 上线 2 周后跑一次真机冒烟，重点看 riverpod 3.4.2 有没有导致任何 Notifier 行为异常
- [ ] 观察 `unnecessary_primary_constructor_body` / `use_declaring_parameters` 这两条 lint 有没有随功能新增而命中
- [ ] 关注 riverpod_analyzer_utils 从 `1.0.0-dev.11` 转正到 `1.0.0` GA 的时机，届时 pin 到稳定版
- [ ] 关注 `unnecessary_type_name_in_constructor` 是否值得单独启动一次 Phase 2 清理
