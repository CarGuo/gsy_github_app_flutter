# 功能模板：修改通知页相关功能

## 适用场景

- 修改通知列表展示
- 调整未读/参与/全部筛选
- 修复刷新、分页或已读状态问题
- 扩展通知跳转行为

## 开始前先读

1. `docs/02-features/notify.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 先判断问题属于哪一层

### 页面与交互层

对应：

- `lib/page/notify/notify_page.dart`

适合处理：

- 列表渲染
- 滑动已读
- 顶部筛选
- 跳转行为

### 数据层

对应：

- `lib/common/repositories/user_repository.dart`
- `lib/model/notification.dart`

适合处理：

- 获取通知
- 标记已读
- 全部已读
- 通知字段解析

## 修改策略

- 优先维持 Signals 结构稳定
- 扩展通知类型跳转时，集中处理在 `_renderEventItem`
- 改分页或刷新逻辑时，必须一起验证筛选切换和返回强刷
- 未经明确允许，不得把本模块从 Signals 改成别的状态实现；这里保留 Signals 具有明确演示价值

## 常见误区

- 忽略 `signalPage = -1` 的强制刷新约定
- 只验证默认列表，不验证三个筛选 tab
- 标记已读后忘了检查列表移除或刷新逻辑

## 最低验证

1. 进入通知页
2. 默认列表加载
3. 切换 未读 / 参与 / 全部
4. 下拉刷新
5. 上拉加载更多
6. 单条标记已读
7. 全部标记已读
8. 点击 Issue 类型通知进入详情并返回

## 需要额外谨慎的情况

- 修改 Signals 触发链路
- 修改分页边界
- 修改通知详情跳转映射

## 收尾步骤

通知页改动完成后，必须先经过新的 reviewer subagent 审查。
author 不应在未做独立 review 的情况下直接宣布完成。
