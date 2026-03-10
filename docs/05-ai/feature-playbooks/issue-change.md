# 功能模板：修改 Issue 相关功能

## 开始前先读

1. `docs/02-features/issue.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- 展示和交互问题：`lib/page/issue/issue_detail_page.dart`
- 数据协议问题：`lib/common/repositories/issue_repository.dart`

## 修改策略

- 头部信息和评论列表分开看，不要混成一条链路
- 编辑、删除、回复逻辑都依赖刷新回流
- 不要只改按钮显示，不改实际提交链路

## 最低验证

1. 进入 issue 详情
2. 头部正常展示
3. 评论列表正常加载
4. 回复 issue
5. 编辑 issue 或评论
6. open/close issue 后头部状态更新

## 收尾步骤

Issue 相关改动完成后，先用新的 reviewer subagent 审查评论链路和头部状态回流，再对外汇报完成。
