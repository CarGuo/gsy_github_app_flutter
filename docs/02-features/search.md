# 搜索功能

## 相关文件

- `lib/page/search/search_page.dart`
- `lib/page/search/search_bloc.dart`
- `lib/page/search/widget/gsy_search_drawer.dart`
- `lib/common/repositories/repos_repository.dart`

## 当前实现

搜索页支持：

- 搜仓库
- 搜用户
- 排序和过滤
- 搜索动画展开/收起

## 数据流

1. 页面输入搜索词
2. 选择仓库或用户 tab
3. drawer 选择排序、类型、语言
4. `SearchBLoC.getDataLogic` 调 `ReposRepository.searchRepositoryRequest`
5. 列表根据当前 tab 渲染仓库项或用户项

## 状态管理

- 页面主要使用本地 state
- 查询条件保存在 `SearchBLoC`
- 列表能力依赖 `GSYListState`

## 高风险点

- 搜索条件切换会触发清空列表并重新刷新
- 仓库和用户复用同一请求入口，但渲染不同
- 搜索页有自定义圆形展开/收起动画

## 修改建议

- 纯交互或动画问题优先改 `search_page.dart`
- 查询参数问题优先改 `search_bloc.dart`
- 接口或返回结构问题再看 `ReposRepository`
