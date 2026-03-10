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
