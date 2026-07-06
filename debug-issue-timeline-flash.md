# Debug Session: issue-timeline-flash

- **Status**: VERIFIED (unit-level, pending device confirmation)
- **Regression Guard**: `test/page/issue/issue_timeline_merge_test.dart`
  已把 replay 脚本 4 个 case 沉淀为 flutter_test，`flutter test` + `flutter analyze` 均 0 issue。

## Evidence

命令：`dart run tool/dbg/replay_issue_timeline_flash.dart`
或（CI 友好）：`flutter test test/page/issue/issue_timeline_merge_test.dart`

```
[case1] 修复后：合并 + wrapNext，两级消费后仍然含 timeline events
  ✅ 最终 dataList 长度 = 5 (3 comments + 2 events)
  ✅ 时间序升序（3 次相邻检查）
  ✅ 第一个事件是 labeled；最后一个事件是 closed
[case2] 反例：只合并 db res 不包装 next → 网络次消费清空 events
  ✅ 修复前二次消费后 timeline events 消失（复现 bug）
  ✅ 只剩 2 个 comments
[case3] 二次调用 decorate 幂等：长度 2 -> 2
[case4] 边界：null createdAt 排最后；res.data == null 不抛异常
```

## Conclusion

- **H1 CONFIRMED**：case2 直接复现"一闪就没"—— GSYListState 的两级消费在没有 wrapNext 时，
  第二级用纯 comments 覆盖 dataList。case1 证明 wrapNext + decorate 联合修复后行为符合预期。
- H2/H3/H4/H5 未复现，非本次 bug 主因。
- 时间序位置：case1 中 `labeled` 事件正确插在 comment#101(t0) 与 comment#102(t2) 之间，
  `closed` 事件正确排在 t3；用户任务 4 的要求满足。
- **Symptom**: Issue 详情页刚进入时能看到 timeline / labels / reactions 相关新能力，但很快"一闪就没了"。
- **Owner**: Trae Agent
- **Created**: 2026-07-03

## Hypotheses

1. **H1 (Data-flow overwrite)**: `GSYListState.handleRefresh` 在 `res.next != null` 时会二次 `resolveRefreshResult(resNext)`，
   把 `dataList` 清空并重新填入 —— 而 `resNext` 只包含 comments，没合并 timeline，从而覆盖第一次渲染的合并结果。
2. **H2 (Header async race)**: `_getHeaderInfo()` 未 await，两级 `.then` 拉本地 db + 网络。第二次 setState 覆盖了
   已加载的 labels/assignees/milestone。
3. **H3 (Timeline fetch failure)**: `_refreshTimeline()` 内部 try/catch 掉了异常，事件在网络失败时被清空。
4. **H4 (Type guard failure)**: `_decorateWithTimeline` 之前用 `is List<Issue>` 判断，若 res.data 实际是 `List<dynamic>`
   就跳过合并，导致某个分支只显示 comments。
5. **H5 (setState after dispose)**: 页面切换过快时 `_getHeaderInfo` 完成后 setState 抛错，帧被丢弃 —— 但用户报告的是
   "一闪就没"（内容出现后消失），不是"一直空白"，此假设优先级最低。

## Evidence Plan

- 不能起 debug server（无网络装机）。
- 用 Dart VM 单元测试对 `_decorateWithTimeline` 和 `_wrapNextWithTimeline` 的排序、合并、next 包装做黑盒验证。
- 测试用例：
  - db 分支 res.data = [Issue1, Issue2]，`_timelineEvents = [labeled@t1.5, closed@t2.5]` → 合并后按时间序、事件类型正确。
  - 二次消费 next()：包装后的 next 返回的 resNext.data 应该是 List<dynamic>（含 events），
    模拟 `GSYListState` 的两级 refresh 场景。
  - 反例：不包装 next 时（即修复前逻辑），resNext.data 保持纯 comments，验证"一闪"根因。
