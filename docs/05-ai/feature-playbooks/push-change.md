# 功能模板：修改 Push 提交详情相关功能

## 开始前先读

1. `docs/02-features/push.md`
2. `docs/04-quality/smoke-matrix.md`
3. `lib/page/AGENTS.md`

## 优先定位

- 页面与 patch 展示：`lib/page/push/push_detail_page.dart`
- patch 转 HTML：`common/utils/html_utils.dart`
- commit 数据：`ReposRepository`

## 修改策略

- 头部和文件列表来自同一请求结果
- patch 展示问题不要忽略 HTML 转换逻辑
- 改导航时要验证返回仓库详情按钮

## 最低验证

1. 进入 push 提交详情
2. 头部信息正常
3. 文件变更列表正常
4. 点击文件项进入 patch 详情
5. 返回仓库详情链路正常

## 收尾步骤

Push 提交详情改动完成后，必须先经过新的 reviewer subagent 审查 patch 展示和返回链路。
