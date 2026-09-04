# 测试策略

## 当前现状（2026-09-03 更新）

- 仓库已有 `test/` 目录：`test/utils/`、`test/model/`、`test/page/`、`test/widget/`、`test/common/style/` 等，`fvm flutter test` 全量 353 case 绿
- 集成测试脚手架 `patrol_test/`（`patrol ^4.7.0`）已在跑，回归入口见 [patrol-regression.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/04-quality/patrol-regression.md)
- [pubspec.yaml](file:///d:/workspace/project/gsy_github_app_flutter/pubspec.yaml#L132-L133) `dev_dependencies.flutter_test` 已正常声明（不再是注释状态）
- 质量保障组合：单测 + Patrol 集成 + 手工冒烟 + CI 构建 + `mcp_dart` 真机 widget tree / runtime errors

## 近期目标

在既有单测 + Patrol 基线上按功能域**扩容测试覆盖率**（不再是"从零建 harness"）。
新写测试的原则：优先覆盖模型序列化、状态流转、事件识别、GraphQL 分页边界这类"改一处影响一片"的高频回归点。

## 当前基线

1. 静态检查
   - `flutter analyze`
2. 生成代码一致性
   - 输入变化后重新生成相关文件
3. 高价值手工冒烟
   - 应用启动
   - 登录入口
   - 仓库详情
   - 趋势页
   - 通知页
4. Android 构建验证
   - 对构建相关改动执行 release APK 构建

当前手工回归入口见：

- `docs/04-quality/smoke-matrix.md`

当前 Patrol 自动回归入口见：

- `docs/04-quality/patrol-regression.md`
- `patrol_test/app_regression_test.dart`

## 第一批值得补的测试

- 高频模型的序列化测试
- 应用壳层和高频页面的 widget smoke test
- repository 层的解析与适配测试

## 典型改动的完成标准

### UI 小改动

- 页面可正常渲染
- 交互没有破坏导航和状态恢复

### API 或模型改动

- 请求入口正确
- 模型解析仍正常
- 受影响页面能拿到正确数据

### 应用壳层或共享状态改动

- 应用能启动
- 主题、语言、登录态相关行为仍正确
- 根导航无明显回归

## 原则

可靠的小测试集，比覆盖面大但没人维护的测试集更有价值。
测试策略的目标不是形式完整，而是建立可执行、可复用的验证闭环。
