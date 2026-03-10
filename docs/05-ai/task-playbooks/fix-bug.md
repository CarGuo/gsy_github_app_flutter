# 任务模板：修复 Bug

## 适用场景

- 页面行为异常
- 接口数据展示错误
- 刷新、分页、跳转、状态同步问题
- 某个已有功能回归

## 开始前先确认

1. Bug 属于哪个功能域
2. 问题发生在 UI、状态层、repository，还是共享网络层
3. 是否已经有稳定复现路径

## 先读哪些文档

1. `AGENTS.md`
2. `docs/00-overview/project-map.md`
3. 对应功能文档，例如 `docs/02-features/repos.md`
4. 若涉及共享层，再读：
   - `docs/01-architecture/app-layering.md`
   - `docs/04-quality/smoke-matrix.md`

## 执行步骤

1. 先定位最小复现路径
2. 找到最靠近问题的模块，不要一上来改全局
3. 判断问题属于：
   - 页面展示错误
   - 局部状态错误
   - 共享状态错误
   - repository/网络返回错误
4. 只在必要范围内修改
5. 回归受影响功能和相邻链路

## 本仓库的定位建议

- 登录问题：先看 `lib/page/login/` 和 `lib/redux/login_redux.dart`
- 仓库详情问题：先看 `lib/page/repos/` 与对应 provider
- 趋势页问题：先看 `lib/page/trend/`
- 通知页问题：先看 `lib/page/notify/`
- 多页面同时异常：再考虑 `lib/common/net/`、`lib/common/repositories/` 或 `lib/app.dart`

## 禁止事项

- 不要借修 bug 顺手迁移状态管理框架
- 不要为了页面问题直接修改根装配层
- 不要手改生成文件来掩盖真实问题

## 最低验证

- 按 `docs/04-quality/smoke-matrix.md` 执行该功能的基础用例
- 若动到共享层，额外抽查一个高频功能
- 若改模型或生成输入，执行相应生成命令

## 输出要求

至少说明：

- 复现路径
- 根因在哪一层
- 改动边界为什么足够小
- 跑了哪些验证

## 收尾步骤

在 author 自己完成修改和最小验证后，不应直接宣布任务完成。
必须先拉起新的 reviewer subagent 或新的干净 reviewer 上下文，对这次 bug 修复做一轮独立审查。
