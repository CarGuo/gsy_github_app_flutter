# 任务模板：新增接口或数据请求

## 适用场景

- 新增 REST 或 GraphQL 请求
- 扩展已有 repository 的数据读取能力
- 新增页面所需的数据接口

## 开始前先确认

1. 这是 REST 还是 GraphQL
2. 是已有 repository 的扩展，还是确实需要新的边界
3. 是否需要新增模型或更新现有模型
4. 页面是否真的需要新的接口，而不是已有接口字段未使用

## 先读哪些文档

1. `AGENTS.md`
2. `docs/01-architecture/app-layering.md`
3. 对应功能文档
4. `lib/common/net/AGENTS.md`

## 执行步骤

1. 先找最接近的现有请求入口
2. 优先在 repository 层新增或扩展能力
3. 必要时再补 `common/net` 或 `graphql/` 细节
4. 如需新模型，更新模型定义并重新生成
5. 在页面层只消费 repository 结果，不扩散传输细节
6. 若接口会被多个页面复用，避免把逻辑藏在单页内部

## 本仓库的修改顺序建议

1. `lib/common/repositories/*`
2. `lib/common/net/*` 或 `lib/common/net/graphql/*`
3. `lib/model/*`
4. 对应 `lib/page/*` 或 provider/redux 层

## 禁止事项

- 不要把接口细节直接塞进页面
- 不要先改 UI 再临时拼接网络逻辑
- 不要漏掉模型和生成代码同步

## 最低验证

- `flutter analyze`
- 若改模型或注解，执行生成命令
- 手工验证至少一个使用该接口的页面
- 若改公共网络层，按 `smoke-matrix.md` 抽查多个功能

## 输出要求

至少说明：

- 新接口加在了哪个 repository 边界
- 是否新增或更新了模型
- 是否影响共享网络层
- 验证覆盖了哪些页面

## 收尾步骤

接口或数据请求改动在完成最小验证后，必须经过新的 reviewer subagent 审查。
尤其当改动触及共享网络层、repository 边界或模型时，不应跳过这一步。
