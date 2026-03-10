# 功能模板：修改仓库详情相关功能

## 适用场景

- 修改仓库详情页 UI
- 调整 Readme、Issue、文件列表其中一个 tab
- 修改分支切换逻辑
- 调整仓库详情底部按钮行为
- 修复仓库详情页的联动刷新问题

## 开始前先读

1. `docs/02-features/repos.md`
2. `docs/01-architecture/state-management-matrix.md`
3. `docs/04-quality/smoke-matrix.md`
4. `lib/page/AGENTS.md`

## 先判断问题属于哪一层

### 页面壳层

对应：

- `lib/page/repos/repository_detail_page.dart`
- tab 容器、标题栏、更多菜单、浮动按钮

适合处理：

- 页面布局
- tab 切换
- 分支选择入口
- 顶部和底部操作区

### 共享状态层

对应：

- `lib/page/repos/provider/repos_detail_provider.dart`
- `lib/page/repos/provider/repos_network_provider.dart`

适合处理：

- 当前 tab
- 当前分支
- 仓库详情共享数据
- readme 内容
- 底部按钮联动

### 数据层

对应：

- `lib/common/repositories/repos_repository.dart`
- `lib/common/repositories/issue_repository.dart`
- 相关 model

适合处理：

- 请求字段
- 数据解析
- readme、issue、file 等数据源问题

## 修改策略

- 只改某一个 tab 时，优先停留在该 tab 及其直接依赖
- 涉及分支切换时，必须检查 info/readme/file 三者联动
- 涉及 issue 创建时，检查弹窗输入、提交、刷新回流
- 不要为了某个 tab 的问题重做整个 Provider 结构

## 常见误区

- 把跨 tab 共享状态拆成各页面自己的局部变量
- 只改 UI 显示，不改 provider 内状态更新
- 忽略 `currentBranch` 对多个子页的数据源影响

## 最低验证

1. 从入口进入仓库详情页
2. 信息页正常展示
3. Readme 页能加载
4. Issue 页能切换并加载
5. 文件列表页能切换并加载
6. 切换分支后，至少验证信息页、Readme、文件列表联动

## 需要额外谨慎的情况

- 修改 provider 字段定义
- 修改共享底部按钮逻辑
- 修改和 issue、readme、file 同时相关的请求入口

## 收尾步骤

仓库详情相关改动完成后，必须先经过新的 reviewer subagent 审查。
这是跨 tab、跨状态共享模块，不应由 author 直接宣布完成。
