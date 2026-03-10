# 功能模板：修改搜索相关功能

## 开始前先读

1. `docs/02-features/search.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- 页面、动画、输入交互：`lib/page/search/search_page.dart`
- 搜索参数与请求：`lib/page/search/search_bloc.dart`
- 接口结果：`ReposRepository.searchRepositoryRequest`

## 修改策略

- 搜索条件变更后要清空旧列表并重刷
- 仓库搜索和用户搜索要分别验证
- 动画问题不要误伤搜索逻辑，请求问题也不要顺手改动画

## 最低验证

1. 打开搜索页
2. 输入关键字后搜索仓库
3. 切换到用户搜索
4. 改变排序或过滤条件
5. 返回首页时动画正常收起

## 收尾步骤

搜索页改动完成后，需先由新的 reviewer subagent 审查搜索参数、动画和页面生命周期处理，再对外汇报。
