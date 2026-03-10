# AI 协作入口

这个入口页用于帮助人和 agent 快速选择正确的文档路径。
不要从根 README 直接跳进代码，先判断你当前属于哪类任务。

## 如果你要修 Bug

先读：

1. `docs/05-ai/task-playbooks/fix-bug.md`
2. 对应功能文档 `docs/02-features/*.md`
3. `docs/04-quality/smoke-matrix.md`

注意：

- 任务模板和功能模板都已经内置 reviewer subagent 收尾步骤
- author 不应跳过这一步直接宣布完成

## 如果你要新增页面

先读：

1. `docs/05-ai/task-playbooks/add-page.md`
2. `docs/06-decisions/ADR-0002-新增功能默认状态方案.md`
3. 对应功能文档 `docs/02-features/*.md`

## 如果你要新增接口

先读：

1. `docs/05-ai/task-playbooks/add-api.md`
2. `lib/common/net/AGENTS.md`
3. 对应功能文档 `docs/02-features/*.md`

## 如果你要整理状态

先读：

1. `docs/05-ai/task-playbooks/refactor-state.md`
2. `docs/06-decisions/ADR-0001-状态管理收敛策略.md`
3. `docs/01-architecture/state-management-matrix.md`

## 如果你要改仓库详情相关功能

先读：

1. `docs/05-ai/feature-playbooks/repos-change.md`
2. `docs/02-features/repos.md`
3. `docs/04-quality/smoke-matrix.md`

## 如果你要改趋势页

先读：

1. `docs/05-ai/feature-playbooks/trend-change.md`
2. `docs/02-features/trend.md`
3. `docs/04-quality/smoke-matrix.md`

## 如果你要改通知页

先读：

1. `docs/05-ai/feature-playbooks/notify-change.md`
2. `docs/02-features/notify.md`
3. `docs/04-quality/smoke-matrix.md`

## 如果你要改 Issue

先读：

1. `docs/05-ai/feature-playbooks/issue-change.md`
2. `docs/02-features/issue.md`

## 如果你要改搜索

先读：

1. `docs/05-ai/feature-playbooks/search-change.md`
2. `docs/02-features/search.md`

## 如果你要改用户页

先读：

1. `docs/05-ai/feature-playbooks/user-change.md`
2. `docs/02-features/user.md`

## 如果你要改首页容器

先读：

1. `docs/05-ai/feature-playbooks/home-change.md`
2. `docs/02-features/home.md`

## 如果你要改动态页

先读：

1. `docs/05-ai/feature-playbooks/dynamic-change.md`
2. `docs/02-features/dynamic.md`

## 如果你要改 Release

先读：

1. `docs/05-ai/feature-playbooks/release-change.md`
2. `docs/02-features/release.md`

## 如果你要改 Push 提交详情

先读：

1. `docs/05-ai/feature-playbooks/push-change.md`
2. `docs/02-features/push.md`

## 如果你要改调试页

先读：

1. `docs/05-ai/feature-playbooks/debug-change.md`
2. `docs/02-features/debug.md`

## 通用入口

无论哪类任务，默认都建议先过一遍：

1. `AGENTS.md`
2. `docs/README.md`
3. `docs/00-overview/project-map.md`
4. `docs/01-architecture/app-layering.md`

## 如果你要做 AI review

先读：

1. `docs/05-ai/review-harness.md`
2. `docs/05-ai/prompts/reviewer-system.md`
3. 如需 review bundle，再看 `tool/ai/build_review_bundle.ps1`
