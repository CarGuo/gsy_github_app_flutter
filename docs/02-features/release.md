# Release 功能

## 相关文件

- `lib/page/release/release_page.dart`
- `lib/page/release/widget/release_item.dart`
- `lib/common/repositories/repos_repository.dart`

## 当前实现

Release 页面支持查看：

- Release 列表
- Tag 列表
- 内嵌查看 release HTML 内容
- 外部打开 release 或 tag 页面

## 数据流

1. 页面根据 tab 选择 release 或 tag
2. 调 `ReposRepository.getRepositoryReleaseRequest`
3. 列表项长按可打开外部链接
4. release 项点击可在应用内查看 HTML 内容

## 状态管理

- 页面本地 state 保存当前 tab
- 列表能力基于 `GSYListState`

## 高风险点

- release 和 tag 共用一个页面，但数据语义不同
- HTML 内容和外部链接两种打开方式都要兼容
- tab 切换时会清空并重刷列表

## 修改建议

- 展示问题优先改 `release_page.dart` 和 item widget
- 数据问题再看 `ReposRepository`
- 改 tab 逻辑时要同时验证 release 和 tag 两条链路
