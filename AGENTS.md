# GSY GitHub App Flutter 协作说明

这是一个 Flutter GitHub 客户端，同时也是带有教学展示性质的示例工程。
不要假设整个仓库是单一架构风格。多种状态管理方案并存是当前设计现实，不是偶然脏代码。

## 进入仓库后先读

在进行非微小改动前，先读这些文件：

1. `README.md`
2. `docs/README.md`
3. `docs/00-overview/project-map.md`
4. `docs/01-architecture/app-layering.md`
5. `docs/01-architecture/state-management-matrix.md`

## 工作规则

- 改动尽量限制在当前功能域，不要顺手做跨模块重构。
- 非任务明确要求时，不要迁移状态管理框架。
- 优先遵循目标模块现有模式，而不是引入新的全局规范。
- 未经明确允许，不得为了满足需求擅自替换模块既有框架或状态实现，即使替换后看起来更简单。
- `*.g.dart`、多语言生成文件、env 生成文件都视为生成产物；优先重新生成，不要手改。
- 不要提交密钥。`lib/common/config/ignoreConfig.dart` 属于本地或 CI 环境材料。

## 高风险目录

- `lib/app.dart`：应用根装配、导航、全局报错、Redux 和 Riverpod 混合接线
- `lib/common/net/`：共享网络栈、拦截器、GraphQL/REST 入口
- `lib/common/repositories/`：功能数据访问边界
- `lib/env/`：构建期环境配置和生成文件
- `lib/common/localization/`：ARB 与多语言生成输出

## 建议修改策略

- 纯 UI 任务：优先只改页面或局部 widget，不碰全局状态
- API 任务：同时检查 `common/net` 与对应 `common/repositories`
- 状态任务：沿用该模块当前已有状态方案，除非任务明确要求迁移
- 配置/构建任务：同步更新 `docs/03-runbooks/` 中的操作说明

## Review 规则

- 中等以上改动默认使用独立 reviewer 上下文
- 每次非微小代码改动后，默认拉起新的 reviewer subagent 或新的干净上下文审查刚刚的修改
- author 在通过一轮新的 reviewer subagent 审查前，不应直接宣告代码任务完成
- reviewer 不应复用 author 的完整上下文历史
- 先看 `docs/05-ai/review-harness.md`
- reviewer 提示模板见 `docs/05-ai/prompts/reviewer-system.md`
- `tool/ai/build_review_bundle.ps1` 只是可选辅助，不是主流程

## 本地最小验证

按改动范围选择最小验证集合：

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter gen-l10n`
- `flutter analyze`
- `flutter build apk --release --target-platform=android-arm64 --no-shrink`

说明：

- 改模型、env、注解生成代码时跑 `build_runner`
- 改 ARB 或本地化输入时跑 `flutter gen-l10n`
- 改 Android 构建、依赖或运行时关键路径时跑 APK 构建

## 当前已知约束

- 仓库目前没有提交进来的 `test/` 测试目录
- CI 使用 GitHub Actions，当前偏重构建成功
- 项目同时使用 Redux、Riverpod、Provider、Signals
- OAuth 登录相关流程依赖本地 `ignoreConfig.dart`
