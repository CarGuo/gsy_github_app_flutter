# smokePostFrame 简化 spike 结论

> **spike 时间**：2026-09-03
> **背景 commit**：`8106529`（R3 修：加 idle 直接分支 + 改错误上报）、`661bfa7`（M1/M2 复审收尾）
> **对应 todo**：t4 — 评估 `_smokePostFrame` 简化，是否砍 post-frame path 分支

## 结论

**不砍**。保留 `idle 直跑 + post-frame 分支`双路径实现，
维持 [lib/app.dart#L299-L352](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L299-L352) 现状。

## 为什么想过要砍

- 真机自测（[tool/ai/smoke/evidence/8106529_r3_selftest](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/evidence/8106529_r3_selftest)）
  里跑冒烟时 isolate 几乎恒定处于 `SchedulerPhase.idle`，`mcp_dart`
  `vm_service evaluate` 排队执行时通常也落在 idle 阶段——post-frame 分支
  很难被"自然"命中。
- 只留 idle 分支 → 函数体减半，注释 / 单测覆盖面也小一半。
- 直觉上"冒烟工具就是给人手动触发的、都是 idle 情况"。

## 为什么最终不砍

### 1. VM Service Protocol 从未承诺 `evaluate` 一定在 idle 排到

- Dart VM Service Protocol
  ([service.md `evaluate` 章节](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md))
  只保证 evaluate 表达式在目标 isolate 的**事件循环里排队执行**，不保证
  排到时 isolate 处于哪个 SchedulerPhase。
- 冒烟场景下 isolate 极大概率停 idle 是**经验统计**，不是**规格保证**。
  一旦哪天：
  - 冒烟脚本在动画帧驱动（`AnimationController.repeat()`、Lottie 循环
    等）恰好触发时排 evaluate；
  - 未来把 `gsySmokeGoXxx` 从 debug-only 顶层入口扩展到 release 或
    e2e / integration 场景；
  - 使用者手工在 devtools 里 evaluate 一个 `smokePostFrame(...)` 表达式；

  post-frame 路径就必定被命中，而这时如果没有防御，用户等回来的就是
  `Build scheduled during frame` 或 setState 报错——即使这不是"根因修复"，
  它就是**唯一的兜底**。
- 一句话：概率 ≠ 保证。规格没保证的东西，代码不能靠"我从没见过"来简化掉。

### 2. 单测已经证明 post-frame 分支实际可控可复现

- [test/app/smoke_post_frame_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/app/smoke_post_frame_test.dart)
  用 `SchedulerBinding.instance.scheduleFrameCallback` 在
  `SchedulerPhase.transientCallbacks` 阶段调 `smokePostFrame`，
  能稳定命中 post-frame 分支的**正常返回**和**错误上报**两条子分支。
- 单测里 `expect(phaseInsideCallback, isNot(SchedulerPhase.idle))`
  已守约：**这个分支是可用工具能复现的，不是死代码**。
- 覆盖代价 = 6 个 case 中的 2 个。ROI 上完全成立。

> ⚠️ **已知覆盖缺口**：单测目前只覆盖 `transientCallbacks` 阶段调用；
> `SchedulerPhase.postFrameCallbacks` 阶段调用（即 `lib/app.dart`
> smokePostFrame dartdoc 里明说的"回调落到下一帧才 flush"这条边界瑕疵）
> **理论存在但当前单测未覆盖**。之所以先不补：真机上 evaluate 排到 isolate
> 正处于 postFrameCallbacks 阶段的概率相当于两个独立事件的时间窗对齐，
> 属于极端边缘 case；等真的观察到再补 `addPostFrameCallback` 内嵌
> `smokePostFrame` 的用例即可。

### 3. 砍掉的收益远小于风险

| 维度 | 保留 post-frame 分支 | 砍掉 post-frame 分支 |
|---|---|---|
| 函数体行数 | ~54 行 | ~30 行 |
| 单测 case | 6 个 | 4 个 |
| 触发 build-during-frame 风险 | 已防御 | 完全裸奔 |
| 引入未来 bug 的可能 | 无 | evaluate 落在非 idle 阶段就炸 |
| 排查成本 | 单测 + 真机自测都命中 | 需要复现 evaluate 时机才能重现 |

砍掉能省 24 行代码 + 2 个 case，但**任何未来场景变化**都可能让冒烟从
「可靠」退化为「概率炸」——这对一个纯冒烟辅助工具来说不划算。

### 4. 语义上函数就该覆盖两条路径

- `smokePostFrame` 的定位是 **"在任意 SchedulerPhase 下都能安全触发一次
  navigator 动作"** 的封装。这本来就是它存在的核心价值——如果只保
  idle 分支，那和 `NavigatorUtils.goXxx(navKey.currentContext!, ...)`
  没有本质区别，函数就没必要包一层了。
- 保留 post-frame 分支 = **保留函数存在的理由**。

## 未来触发重新评估的条件

**只有满足下列任一条件才重启这次讨论**，否则维持现状：

1. 官方文档明确写 `evaluate` **只**在 `SchedulerPhase.idle` 排到
   （目前不成立，Dart VM Protocol 从没提 SchedulerPhase）。
2. 单测证明 post-frame 分支在任何 mcp_dart / DTD 客户端下都无法复现
   （目前不成立，`smoke_post_frame_test.dart` 已复现）。
3. `smokePostFrame` 被降级为纯 debug helper 且完全不对外暴露
   （目前定位就是 `@visibleForTesting` + debug-only 顶层入口，
   已经是最小暴露面了，无进一步降级空间）。

## 关联

- 代码：[lib/app.dart smokePostFrame](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L299-L352)
- 单测：[test/app/smoke_post_frame_test.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/test/app/smoke_post_frame_test.dart)
- 历史 commit：`224a0d8` → `ed7077e` → `8106529` → `661bfa7`
  （见 [tool/ai/smoke/README.md `## 历史勘误（errata）`](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/README.md)
  章节，用章节名定位，避免行号漂移）
- AGENTS 规则：
  [禁止在文档 / commit / code comment 里编造 VM Service 时序细节](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md)
  （见 AGENTS.md `### 禁止行为` 章节末条）
