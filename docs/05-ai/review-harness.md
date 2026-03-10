# Review Harness

## 目标

让代码审查尽量摆脱 author 视角，避免“作者自己解释自己为什么没问题”。
本仓库默认采用 `author agent` 和 `reviewer subagent` 分离的方式进行 AI 审查。

这更接近 OpenAI 在《Harness engineering》里强调的做法：把 review 设计成独立反馈回路，而不是同一上下文里的自我安慰式复查。

## 核心原则

1. `author` 和 `reviewer` 不共用上下文
2. `reviewer` 应使用新的 subagent 或新的干净上下文
3. `reviewer` 不读取 author 的完整对话历史
4. `reviewer` 只拿到最小必要信息：
   - 任务目标
   - 相关文档入口
   - 变更文件
   - diff
   - 验证结果
5. `reviewer` 的默认职责是找问题，不是帮 author 辩护

这里最重要的不是“把 review 写成文档”，而是把 review 运行在一个新的思维上下文里。
如果 reviewer 继承了 author 的长上下文，它就很容易共享 author 的错误假设。

## 两种角色

### Author

负责：

- 理解任务
- 修改代码
- 运行最小验证
- 在需要时产出 review bundle

不负责：

- 在同一思路链路里给自己“盖章通过”

### Reviewer

负责：

- 在新的 subagent 或新的干净上下文中审查变更
- 优先寻找 bug、回归、越界改动、验证缺失
- 明确指出风险，而不是复述 author 目标

不负责：

- 继续帮 author 完成实现
- 读取 author 的内部推理过程

## 推荐流程

1. Author 完成代码和最小验证
2. 启动新的 reviewer subagent 或新的 reviewer 会话
3. Reviewer 只读取：
   - `docs/05-ai/prompts/reviewer-system.md`
   - 当前 diff
   - 变更相关文件
   - 相关功能文档
   - 验证结果
4. Reviewer 输出 findings、风险、验证缺口
5. Author 根据 findings 修复
6. 必要时开启下一轮 reviewer 会话

默认流程里，review bundle 不是必需的。
如果当前环境已经能直接让新的 reviewer subagent 读取代码和 diff，那么直接这样做即可。

在这个流程完成前，author 不应直接对外宣告“任务已完成”。
对外汇报应发生在至少一轮独立 reviewer 审查之后。

## Reviewer 输入边界

Reviewer 默认可以看：

- 本仓库代码
- 当前 diff
- `AGENTS.md`
- 相关功能文档和 feature playbook

Reviewer 默认不应该看：

- author 的完整聊天历史
- author 的主观解释性长文本
- “我已经确认没问题了”这类自证语句

## 最小 review bundle

如果无法方便地把当前 diff 和验证结果直接交给 reviewer，才使用 review bundle。
bundle 至少应包含：

- 任务摘要
- 变更文件列表
- diff 统计
- 关键 diff
- 运行过的验证命令
- 对应功能域和回归建议

默认情况下，`tool/ai/build_review_bundle.ps1` 会收集“当前工作区相对 `HEAD` 的未提交变更”。
它只是一个可选辅助工具，不是主流程。
如果你要审查某个分支相对基线分支的差异，可以显式传入：

- `-BaseRef origin/master`
- 或其他明确基线

## 审查标准

Reviewer 优先关注：

1. 逻辑正确性
2. 行为回归
3. 状态边界是否被破坏
4. 是否违反仓库文档中的既有约束
5. 验证是否足够支撑本次改动

## 输出格式建议

- Findings
- Open Questions
- Verification Gaps
- Residual Risks

如果没有发现问题，也要明确说明：

- 未发现明显问题
- 仍然存在哪些验证空白

## 实操要求

- 只要是中等以上改动，默认走 reviewer 分离流程
- 改共享层、根装配、状态边界、公共网络层时，必须走 reviewer 分离流程
- reviewer 分离流程的首选实现方式是新的 subagent / 新的干净上下文
- 未经过 reviewer 分离流程的代码改动，不应以“已完成”状态对外汇报
