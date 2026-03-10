# Agent 工作指引

## 目标

做范围清晰、容易验证、方便评审的改动。
不要把 agent 的“能改”误当成“应该改很多”。

## 编辑前先读

1. `AGENTS.md`
2. `docs/00-overview/project-map.md`
3. `docs/01-architecture/app-layering.md`
4. `docs/01-architecture/state-management-matrix.md`
5. `docs/04-quality/smoke-matrix.md`
6. `docs/06-decisions/ADR-0001-状态管理收敛策略.md`
7. 目标功能对应的 `docs/02-features/*.md`

## 任务模板

按任务类型优先参考：

- 修 Bug：`docs/05-ai/task-playbooks/fix-bug.md`
- 新增页面：`docs/05-ai/task-playbooks/add-page.md`
- 新增接口：`docs/05-ai/task-playbooks/add-api.md`
- 状态整理：`docs/05-ai/task-playbooks/refactor-state.md`

这些模板现在都内置了统一收尾步骤：

- author 完成修改和最小验证后
- 必须先拉起新的 reviewer subagent
- reviewer 独立审查后，author 才能对外汇报完成

## 功能模板

按功能域优先参考：

- 仓库详情：`docs/05-ai/feature-playbooks/repos-change.md`
- 趋势页：`docs/05-ai/feature-playbooks/trend-change.md`
- 通知页：`docs/05-ai/feature-playbooks/notify-change.md`
- Issue：`docs/05-ai/feature-playbooks/issue-change.md`
- 搜索：`docs/05-ai/feature-playbooks/search-change.md`
- 用户页：`docs/05-ai/feature-playbooks/user-change.md`
- 首页容器：`docs/05-ai/feature-playbooks/home-change.md`
- 动态页：`docs/05-ai/feature-playbooks/dynamic-change.md`
- Release：`docs/05-ai/feature-playbooks/release-change.md`
- Push 提交详情：`docs/05-ai/feature-playbooks/push-change.md`
- 调试页：`docs/05-ai/feature-playbooks/debug-change.md`

统一入口：

- `docs/CONTRIBUTING_AI.md`

## Review 分离

- review 采用 author / reviewer 分离上下文
- 每次非微小代码改动后，默认拉起新的 reviewer subagent 做审查
- 在 reviewer subagent 完成一轮审查前，不应直接向用户汇报“已完成”
- 说明见 `docs/05-ai/review-harness.md`
- reviewer 提示模板见 `docs/05-ai/prompts/reviewer-system.md`
- author 交接模板见 `docs/05-ai/prompts/author-handoff.md`
- `tool/ai/build_review_bundle.ps1` 只是可选辅助，不是主路径

## 工作规则

- 优先遵循目标模块现有模式，不主动创造新的抽象层
- 页面局部问题不要上升到根装配层
- 优先通过 repository 或共享网络边界收口，不要把传输细节散落到页面
- 需要生成的内容改源文件，不改生成输出
- 新出现的架构规则应写入 `docs/06-decisions/`，不要只留在对话或 PR 评审里

## 改动后最低报告要求

- 改了什么
- 为什么改动边界合理
- 跑了哪些命令或做了哪些手工验证
- 还剩哪些风险
