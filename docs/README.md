# 文档索引

这个目录同时服务于人类协作者和代码 agent。
第一次进入仓库时，建议按顺序阅读，不要只看根 README 就直接改代码。

## 推荐阅读顺序

1. `00-overview/project-map.md`
2. `01-architecture/app-layering.md`
3. `01-architecture/state-management-matrix.md`
4. `03-runbooks/local-setup.md`
5. `04-quality/test-strategy.md`
6. `04-quality/smoke-matrix.md`
7. `05-ai/agent-guide.md`

## 目录说明

- `00-overview/`：快速理解项目和目录职责
- `01-architecture/`：分层边界、状态管理边界、生成代码与配置规则
- `02-features/`：按功能说明关键页面、数据流和高风险点
- `03-runbooks/`：本地运行和常见操作手册
- `04-quality/`：验证方式、质量门槛、测试策略
- `05-ai/`：面向 agent 的工作约束和执行方式
- `06-decisions/`：需要长期保留的架构决策记录

## 当前关键文档

- 架构边界：`01-architecture/app-layering.md`
- 状态管理边界：`01-architecture/state-management-matrix.md`
- 手工回归入口：`04-quality/smoke-matrix.md`
- 长期规则：`06-decisions/ADR-0001-状态管理收敛策略.md`
- 任务模板入口：`05-ai/task-playbooks/`
- 功能模板入口：`05-ai/feature-playbooks/`
- AI 协作导航：`CONTRIBUTING_AI.md`

## 当前目标

当前这批文档的重点不是先做“AI 功能”，而是先把仓库整理成：

- 更容易理解
- 更容易局部修改
- 更容易验证
- 更不容易让 agent 猜错边界
