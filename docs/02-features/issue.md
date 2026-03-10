# Issue 功能

## 相关文件

- `lib/page/issue/issue_detail_page.dart`
- `lib/page/issue/issue_edit_dIalog.dart`
- `lib/common/repositories/issue_repository.dart`

## 当前实现

Issue 详情页同时承担：

- issue 头部信息展示
- 评论列表展示
- 回复 issue
- 编辑 issue
- 编辑/删除评论
- open/close issue

## 数据流

1. 页面刷新时先拉 issue 头部信息
2. 再拉评论列表
3. 头部和评论列表分别更新
4. 编辑、回复、删除后通过刷新重新拉取数据

## 状态管理

- 主要使用页面本地 state
- 列表部分依赖 `GSYListState`
- 数据入口集中在 `IssueRepository`

## 高风险点

- 头部信息和评论列表是两条并行数据链路
- 编辑、删除、回复之后依赖刷新回流，不是本地直接 patch
- issue 状态切换会影响头部按钮和展示状态

## 修改建议

- 评论展示问题优先改 `issue_detail_page.dart` 和 widget
- 数据或协议问题再看 `IssueRepository`
- 改编辑能力时要同时验证 reply/edit/delete/open-close 几条链路
