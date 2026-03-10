# 功能模板：修改趋势页相关功能

## 适用场景

- 趋势页列表展示改动
- 时间和语言筛选改动
- 刷新或首次加载问题
- 趋势页跳转链路调整

## 开始前先读

1. `docs/02-features/trend.md`
2. `docs/06-decisions/ADR-0001-状态管理收敛策略.md`
3. `docs/04-quality/smoke-matrix.md`
4. `lib/page/AGENTS.md`

## 先判断问题属于哪一层

### 页面层

对应：

- `lib/page/trend/trend_page.dart`

适合处理：

- 列表渲染
- 筛选头部
- 滚动和刷新控件
- 空态、按钮、跳转

### 状态与请求层

对应：

- `lib/page/trend/trend_provider.dart`
- `lib/common/repositories/repos_repository.dart`

适合处理：

- 首次请求
- 二阶段请求
- 刷新触发逻辑
- 趋势数据获取

## 修改策略

- UI 小改动尽量停留在 `trend_page.dart`
- 请求或缓存问题再看 `trend_provider.dart`
- 不要在普通改动里重构趋势页整体状态管理
- 修改首次加载逻辑时，要同时检查 `didChangeDependencies` 和刷新流程

## 常见误区

- 忽略模块级变量 `trendLoadingState`、`trendRequestedState`
- 只测首次加载，不测切换筛选和下拉刷新
- 误把趋势页当前实现理解成纯页面局部状态

## 最低验证

1. 进入趋势页
2. 首次加载正常
3. 切换时间筛选
4. 切换语言筛选
5. 下拉刷新
6. 点击列表项进入仓库详情并返回

## 需要额外谨慎的情况

- 修改 provider 参数结构
- 修改刷新触发时机
- 修改趋势页和仓库详情页之间的跳转

## 收尾步骤

趋势页改动完成后，先拉起新的 reviewer subagent 审查刷新、筛选和状态边界，再对外汇报完成。
