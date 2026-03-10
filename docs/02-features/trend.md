# 趋势功能

## 相关文件

- `lib/page/trend/trend_page.dart`
- `lib/page/trend/trend_provider.dart`
- `lib/page/trend/trend_user_page.dart`
- `lib/common/repositories/repos_repository.dart`

## 当前实现

趋势页展示热门仓库列表，并支持按时间范围和语言筛选。
它现在主要基于 Riverpod provider 获取数据，但页面内部仍保留了一些本地状态和历史兼容写法。

## 数据流

1. 页面首次进入时设置默认筛选条件
2. 触发 `trendFirstProvider`
3. `trendFirstProvider` 先请求第一阶段结果
4. `trendSecondProvider` 再等待第一阶段结果，并在需要时继续追第二阶段数据
5. 页面优先读第二阶段结果，否则回退到第一阶段结果

这里的设计重点不是“两个列表源”，而是展示先后阶段的数据请求处理方式。

## 状态管理

- 列表数据请求：Riverpod
- 筛选条件、滚动、刷新控制：页面本地 state
- 还有 `trendLoadingState`、`trendRequestedState` 这样的模块级变量

## 高风险点

- `trendLoadingState` 和 `trendRequestedState` 是模块级共享变量，改并发或刷新逻辑时要格外小心
- 首次加载和筛选切换都依赖 `didChangeDependencies`
- 页面同时用到了局部 state、Riverpod 和刷新控件，不要只改其中一段就认为链路完整

## 修改建议

- 小功能改动先只改 `trend_page.dart`
- 数据请求或缓存逻辑改动再看 `trend_provider.dart` 和 `ReposRepository`
- 如果要重构趋势页状态，先单独立决策，不要夹在普通需求里做
