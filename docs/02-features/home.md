# 首页容器功能

## 相关文件

- `lib/page/home/home_page.dart`
- `lib/page/home/widget/home_drawer.dart`
- `lib/page/dynamic/dynamic_page.dart`
- `lib/page/trend/trend_page.dart`
- `lib/page/my_page.dart`
- [lib/widget/gsy_tabbar_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart)：Bottom Tab / Rail 双骨架切换
- [lib/common/style/gsy_adaptive_shell.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)：Rail 骨架的 delegate 抽象
- [lib/common/style/gsy_responsive.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart)：窗口断点

## 当前实现

首页不是单一业务页，而是应用主容器，负责：

- 三个主 tab 切换
- 搜索入口
- drawer 入口
- 双击 tab 回到顶部
- Android 返回键回桌面
- **自适应导航骨架**：compact（<600dp）走 Scaffold 的 `bottomNavigationBar` slot，实际渲染器是**自定义** [GSYTab.TabBar](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabs.dart)（不是 Material 原生 `BottomNavigationBar`）；medium/expanded（≥600dp，含手机横屏）走侧边 `NavigationRail`（由 delegate 渲染）

## 数据流

首页主要负责导航和容器调度，本身不直接承接业务数据。
业务数据由各 tab 页面自己拉取。

## 状态管理

- 主要是页面容器本地状态
- 通过 `GlobalKey` 驱动各 tab 的 `scrollToTop`

## 自适应导航协议（P1 引入）

首页在 [home_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart) 里同时声明两套入口：

- `tabItems`：`List<Widget>`（当前实现为 `Tab(child: Column(icon + text))`，由 [_renderTab](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart#L47-L54) 构造），compact 断点交给 [GSYTab.TabBar](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabs.dart) 消费
- `railDestinations`：`List<GSYAdaptiveDestination>` 列表，medium/expanded 断点使用（**框架无关类型**）

两个列表的**长度和顺序必须严格一致**，`GSYTabBarWidget` 会用同一个 `_index` 驱动 `PageView`。

具体是否切换成 Rail 由 [GSYTabBarWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart) 调 `GSYAdaptiveNavigation.instance.shouldUseRail(context)` 决定，页面代码**不做**断点判断。

想让整个 GSY 换一套自适应框架（例如 `flutter_adaptive_scaffold` 社区继任者、桌面端骨架）：只需在应用启动早期 `GSYAdaptiveNavigation.instance.setDelegate(...)`，首页代码零改动。

## 高风险点

- 改 tab 结构会影响动态页、趋势页、我的页面联动
- 搜索入口依赖右上角控件位置计算
- 返回键行为是首页特有容器逻辑
- **`tabItems` 与 `railDestinations` 长度不一致会直接跌回 compact 分支（`GSYTab.TabBar`）**（`GSYTabBarWidget` 的自保：`railDestinations!.length == tabItems!.length` 才启用 Rail）

## 修改建议

- 首页问题优先限制在容器和导航层
- 不要把某个 tab 的业务逻辑加回首页
- 改搜索入口时要验证动画起点和跳转
- 新增 / 删除 tab 时**必须同步改 `tabItems` 与 `railDestinations`**，两个列表下标要对齐
- 不要在首页里 `import NavigationRail` 或写 `MediaQuery.sizeOf(ctx).width < 600`，一律走抽象层，规约见 [app-layering §6 自适应布局层](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/app-layering.md) 与 [ADR-0005](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)
