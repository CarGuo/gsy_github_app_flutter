# 动态页功能

## 相关文件

- `lib/page/dynamic/dynamic_page.dart`
- `lib/page/dynamic/dynamic_bloc.dart`
- `lib/common/repositories/repos_repository.dart`
- `lib/common/utils/event_utils.dart`

## 当前实现

动态页是首页第一个 tab，展示当前用户相关动态流。
页面支持：

- 首次加载
- 下拉刷新
- 上拉加载更多
- 生命周期恢复时自动刷新
- 事件点击跳转

## 数据流

1. 首次进入时先读数据库或本地缓存链路
2. 再触发刷新
3. 页面恢复到前台时，如果已有数据则再次触发刷新
4. 列表项点击后通过 `EventUtils` 分发跳转

## 状态管理

- 主要通过 `DynamicBloc` 管理列表数据
- 页面本地管理滚动、刷新和忽略点击状态
- 用户名来源于 Redux store

## 高风险点

- 首次加载、手动刷新、生命周期恢复刷新是三条不同入口
- `_ignoring` 会影响页面交互时机
- 数据来源和跳转逻辑分布在 bloc、repository、event utils

## 修改建议

- 列表行为问题优先看 `dynamic_page.dart`
- 数据加载与分页问题看 `dynamic_bloc.dart`
- 事件跳转问题看 `EventUtils`
