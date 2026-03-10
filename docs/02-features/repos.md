# 仓库详情功能

## 相关文件

- `lib/page/repos/repository_detail_page.dart`
- `lib/page/repos/provider/repos_detail_provider.dart`
- `lib/page/repos/provider/repos_network_provider.dart`
- `lib/common/repositories/repos_repository.dart`
- `lib/common/repositories/issue_repository.dart`

## 当前实现

仓库详情页是一个典型的“功能复杂且跨 tab 共享状态”的模块。
页面包含：

- 信息页
- Readme 页
- Issue 列表页
- 文件列表页

它通过 `MultiProvider` 在 tab 间共享 `ReposDetailProvider` 和 `ReposNetWorkProvider`。

## 数据流

初始化主链路：

1. `RepositoryDetailPage` 创建 `ReposDetailProvider`
2. `initState` 中先拉取分支列表
3. tab 子页面通过共享 provider 请求详情、readme、issue、文件等数据
4. provider 继续委托给 `ReposRepository` 或 `IssueRepository`

分支切换链路：

1. 顶部更多菜单选择 branch
2. 更新 `currentBranch`
3. 主信息、文件列表、readme 分别触发刷新

## 状态管理

- 当前模块主要使用 Provider
- `ReposDetailProvider` 负责共享仓库详情、分支、底部按钮、当前 tab、readme 内容等状态
- `ReposNetWorkProvider` 只是对 repository 调用做一层包装，主要用于演示 provider 依赖 provider

## 高风险点

- 这是跨 tab 共享状态模块，不要把共享状态拆回单页局部变量
- `currentBranch` 会影响多个子页面数据源，改分支逻辑时要检查联动刷新
- 底部按钮依赖仓库详情状态，不要只改显示不改数据更新链路
- 该模块同时触及 repo、issue、readme、file，多点回归风险高

## 修改建议

- UI 结构改动：先停留在 `lib/page/repos/`
- 数据字段改动：同步检查 `ReposDetailProvider` 和 repository 返回模型
- 如果只是改某个 tab，不要顺手重做整个 provider 结构
