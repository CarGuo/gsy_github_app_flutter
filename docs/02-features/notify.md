# 通知功能

## 相关文件

- `lib/page/notify/notify_page.dart`
- `lib/common/repositories/user_repository.dart`
- `lib/model/notification.dart`

## 当前实现

通知页负责展示 GitHub 通知消息，并支持：

- 未读 / 参与 / 全部 三种筛选
- 下拉刷新
- 上拉加载更多
- 将单条通知标记为已读
- 全部标记为已读

## 数据流

1. 页面通过 Signals 创建通知列表、筛选索引、页码信号
2. `createEffect` 监听筛选索引和页码变化
3. 变化后触发 `loadData()`
4. `loadData()` 调用 `UserRepository.getNotifyRequest`
5. 根据返回结果刷新列表或追加列表
6. 点开 Issue 类型通知后跳转详情，并在返回时强制刷新

## 状态管理

- 该页面主要使用 Signals
- `notifySignal` 保存列表
- `notifyIndexSignal` 保存筛选状态
- `signalPage` 保存页码

## 高风险点

- `signalPage = -1` 被用作强制刷新前的中间态，改页码逻辑时不能忽略这个约定
- 列表加载、筛选切换、已读操作都依赖信号联动，改动时要验证多种入口
- 目前只对 `Issue` 类型通知做了明确跳转处理

## 修改建议

- 页面交互改动优先保持 Signals 结构稳定
- 如果扩展更多通知类型跳转，集中收口在 `_renderEventItem`
- 改分页或刷新逻辑时，必须手工验证切 tab、已读、回退刷新三条链路
