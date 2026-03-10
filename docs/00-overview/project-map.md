# 项目地图

## 项目定位

`gsy_github_app_flutter` 是一个跨平台 GitHub 客户端。
它既是完整功能应用，也是偏教学展示风格的工程，因此仓库中会刻意保留多种实现方式，而不是追求所有模块都完全统一。

## 运行主链路

高层数据链路可以概括为：

`UI/Page -> 状态层 -> Repository -> 网络/数据库 -> Model -> UI 刷新`

应用入口和全局装配主要集中在：

- `lib/main.dart`
- `lib/app.dart`

这些位置负责：

- 应用启动
- 环境配置装配
- 根导航
- 多语言和主题
- 全局错误处理
- 全局状态容器接线

## 目录地图

- `lib/main.dart`：应用启动、Zone 异常兜底、环境包装
- `lib/app.dart`：`MaterialApp`、路由、Redux 根 store、Riverpod 容器、HTTP 错误监听
- `lib/common/config/`：应用配置和 OAuth 本地配置
- `lib/common/net/`：API 客户端、拦截器、GraphQL、数据转换
- `lib/common/repositories/`：功能层数据访问边界
- `lib/common/localization/`：本地化扩展、ARB、生成代码
- `lib/db/`：本地数据库 provider 和 SQL 辅助
- `lib/env/`：环境配置及其生成文件
- `lib/model/`：数据模型和序列化生成文件
- `lib/page/`：页面功能目录，如 `repos`、`issue`、`trend`、`notify`、`user`
- `lib/provider/`：Provider/Riverpod 相关共享状态
- `lib/redux/`：Redux state、reducer、middleware
- `static/`：静态资源
- `.github/workflows/`：GitHub Actions 配置

## 对协作者很重要的现实

- 项目里同时存在多种状态管理方案
- 同时使用 REST 和 GraphQL
- 生成代码是日常开发流程的一部分
- 根 README 主要承担项目介绍和运行说明，不足以替代工程地图

## AI 最容易犯错的地方

- 误以为整个项目已经统一到某一种状态管理
- 为了解决页面局部问题去改 `lib/app.dart`
- 直接手改生成文件而不是回到源输入
- 忘记 `ignoreConfig.dart` 的本地依赖

在修改共享链路前，先看架构文档和对应模块文档。
