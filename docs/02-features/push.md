# Push 提交详情功能

## 相关文件

- `lib/page/push/push_detail_page.dart`
- `lib/page/push/widget/push_header.dart`
- `lib/page/push/widget/push_coed_item.dart`
- `lib/common/repositories/repos_repository.dart`

## 当前实现

Push 提交详情页负责展示一次 commit 的：

- 头部信息
- 文件变更列表
- patch 预览
- 跳回仓库详情入口

## 数据流

1. 页面刷新时请求 commit 详情
2. 拿到头部信息和文件列表
3. 点击文件项后把 patch 转成 HTML 并跳到代码详情页

## 状态管理

- 主要是页面本地 state
- 列表依赖 `GSYListState`
- 数据入口在 `ReposRepository`

## 高风险点

- 头部和文件列表来自同一 commit 详情结果
- patch 需要转换成 HTML 后再展示
- 有的入口需要显示返回仓库首页按钮

## 修改建议

- UI 展示问题优先改 `push_detail_page.dart` 和 widget
- patch 展示问题同时看 `HtmlUtils`
- commit 数据问题再看 `ReposRepository`
