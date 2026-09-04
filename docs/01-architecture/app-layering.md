# 应用分层

## 目的

这个仓库不是严格单一架构实现，而是采用“整体分层明确、局部实现多样”的方式。
协作者不需要强行统一写法，但需要尊重已有边界，避免把局部需求扩散成全局耦合。

## 1. 入口与应用壳层

- `lib/main.dart`
- `lib/app.dart`
- `lib/env/`

职责：

- 应用启动
- 环境配置装配
- 根导航与多语言/主题
- 全局异常处理
- 全局状态容器接线

原则：

- 不要把功能业务逻辑直接塞进这里
- 除非是全局行为问题，否则尽量不要改 `lib/app.dart`

## 2. UI 层

- `lib/page/`
- 各功能目录下的局部 widget
- `lib/common/` 下复用 UI 组件

职责：

- 页面渲染
- 用户交互响应
- 将数据请求和状态变化委托给状态层或 repository

原则：

- 优先在功能目录内完成 UI 改动
- 页面不要直接承接太多网络协议细节

## 3. 状态层

- `lib/redux/`
- `lib/provider/`
- `lib/app.dart` 中接入的 Riverpod 容器
- 指定页面中的 Signals

职责：

- 维护视图状态
- 协调异步加载
- 向 UI 暴露状态变化

原则：

- 新改动优先沿用目标模块当前已有状态方案
- 不要在无关任务里做状态管理迁移

## 4. Repository 层

- `lib/common/repositories/`

职责：

- 将功能请求翻译成网络或数据库访问
- 隔离页面/状态层与具体传输实现

原则：

- 改接口时优先在 repository 边界收口
- 页面不要绕过 repository 直接铺开网络细节

## 5. 数据与传输层

- `lib/common/net/`
- `lib/db/`
- `lib/model/`

职责：

- HTTP/GraphQL 访问
- 拦截器与响应转换
- 本地持久化
- 序列化与模型转换

原则：

- 不要从页面直接复制网络调用逻辑
- 共用行为优先收敛到共享网络层或 repository

## 6. 自适应布局层（Adaptive Shell）

- [lib/common/style/gsy_responsive.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart)
- [lib/common/style/gsy_adaptive_shell.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)

职责：

- 提供大屏 / 横屏 / 折叠屏统一的窗口断点与"是否用 Rail"这类**布局决策**
- 把导航容器（`NavigationRail` / 后续 `NavigationDrawer` / 两栏 Master-Detail）从页面代码中隔离到 delegate
- 让页面代码只声明"我有几个入口、当前选中哪个"，具体渲染骨架由 shell 层决定

关键 API：

- `GSYBreakpoints`：Material 3 三档窗口宽度阈值（compact <600 / medium 600-839 / expanded ≥840）
- `GSYWindowSize` + `GSYResponsiveContext` extension：一次性拿到当前窗口分档、是否可展示两栏、是否处于窄高、是否命中折叠屏 hinge
- `GSYAdaptiveDestination`：**框架无关的**入口描述结构（图标 + 文本），页面代码只依赖这个类型
- `GSYAdaptiveNavigationDelegate`：Rail / Drawer / Bottom 骨架的 delegate 契约（`shouldUseRail` + `buildRail`）
- `GSYAdaptiveNavigation`：全局单例，读 delegate 并转发；默认注入 [MaterialAdaptiveNavigationDelegate](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L60-L108)

原则：

- **页面禁止**直接 `import 'package:flutter/material.dart' show NavigationRail`：一律走 `GSYAdaptiveNavigation.instance.buildRail(...)`
- **页面禁止**手写 `MediaQuery.sizeOf(ctx).width < 600` 之类的裸判断：一律走 `context.gsyWindowSize` / `context.canShowTwoPane` 等 extension
- 新增布局骨架（例如 P2 的 Master-Detail、P3 的折叠屏 hinge 感知）**只允许**扩展 delegate 契约，不允许在页面里自造条件分支
- 想换 `flutter_adaptive_scaffold` 社区继任者 / 自研 Cupertino 侧栏 / 桌面端骨架：写一个新的 `GSYAdaptiveNavigationDelegate` 实现，在应用启动早期 `GSYAdaptiveNavigation.instance.setDelegate(...)` 注入，页面代码不改
- 决策依据与替换方案对比见 [ADR-0005 大屏 / 横屏 / 折叠屏自适应导航抽象](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)
- Master-Detail 落地后"页面归哪一层 Navigator / 何时走 detailNavigator / 何时走根栈"的显式规范见 [route-topology.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/route-topology.md)（RFC，2026-09-04 起草，收敛 Search / Notify / TrendUser 归属 + caller 打标准则）

## 生成代码约束

以下内容应视为生成产物：

- `lib/model/` 下的 `*.g.dart`
- `lib/env/` 下生成文件
- `lib/common/localization/l10n/` 下生成输出
- `riverpod_annotation` 对应的 `*.g.dart`

原则：

- 优先修改源输入，再重新生成
- 非必要不要直接手改生成文件

## 改动入口建议

- 页面展示问题：先看 `lib/page/<feature>/`
- API/模型问题：看 `common/net`、`common/repositories`、`model`
- 全局主题/语言/导航问题：看 `lib/app.dart` 和共享 provider/redux
- 构建或配置问题：看 `lib/env/`、`pubspec.yaml` 和 runbook
