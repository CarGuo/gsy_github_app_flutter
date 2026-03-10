# 功能模板：修改动态页相关功能

## 开始前先读

1. `docs/02-features/dynamic.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- 页面刷新和滚动行为：`lib/page/dynamic/dynamic_page.dart`
- 列表数据与分页：`lib/page/dynamic/dynamic_bloc.dart`
- 事件跳转：`common/utils/event_utils.dart`

## 修改策略

- 首次加载、手动刷新、恢复前台刷新都要分开验证
- 动态页依赖当前登录用户，注意 Redux 用户态
- 不要只改 bloc 不测页面恢复刷新

## 最低验证

1. 首次进入动态页
2. 下拉刷新
3. 上拉加载更多
4. 退到后台再回来，验证自动刷新
5. 点击事件项跳转

## 收尾步骤

动态页改动完成后，先拉起新的 reviewer subagent 审查首次加载、恢复刷新和事件跳转，再对外汇报。
