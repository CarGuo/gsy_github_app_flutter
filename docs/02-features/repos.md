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

### 主语言与旧缓存（2026-10-24 / FPR-120）

仓库详情与 parent 的主语言来自 GitHub GraphQL `primaryLanguage.name`；
`languages.totalSize` 只保留代码总大小，不能从语言组成列表的首项推断主语言。
[GitHub 官方字段说明](https://docs.github.com/en/graphql/reference/repos#repository)。
Trend User 的 User / Organization、首屏 / 游标查询同样使用所选最高星标仓库的
`primaryLanguage`，不把它解释为用户全部仓库的综合语言。

详情 SQLite 与阅读历史保存原始 GraphQL JSON。旧记录没有 `primaryLanguage` key，
以及新响应显式返回 `primaryLanguage: null`，都会得到未知语言；其它资料照常保留。
详情沿既有 `DataResult.next` 取新数据并覆盖该仓库缓存与阅读历史；旧离线历史未重访前
保持未知，不回退 `languages.nodes[0]`，不清库、重建历史或逐行批量联网迁移。
既有 UI 的空语言表示继续生效，本次不新增页面文案或改变状态管理。

`RepositoryQL.toMap` 同步编码 `primaryLanguage`、语言总大小和 parent 的相同边界。
它仍有与本问题无关的既有计数/topics 键形不对称，不能据此宣称全对象
`fromMap(toMap(model))` 已成立；当前编码边界是主语言、身份、总大小和 parent。

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
