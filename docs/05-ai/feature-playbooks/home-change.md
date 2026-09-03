# 功能模板：修改首页容器相关功能

## 开始前先读

1. [docs/02-features/home.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/02-features/home.md)
2. [docs/04-quality/smoke-matrix.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/04-quality/smoke-matrix.md)
3. [lib/page/AGENTS.md](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/AGENTS.md)
4. [docs/06-decisions/ADR-0005 大屏 / 横屏 / 折叠屏自适应导航抽象](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md)（涉及 tab 结构 / 骨架切换必读）
5. [docs/01-architecture/app-layering.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/app-layering.md) §6 自适应布局层

## 优先定位

- tab 容器和搜索入口：[lib/page/home/home_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart)
- drawer：[lib/page/home/widget/home_drawer.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/widget/home_drawer.dart)
- Bottom Tab / Rail 双骨架切换：[lib/widget/gsy_tabbar_widget.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart)
- 自适应导航 delegate 抽象：[lib/common/style/gsy_adaptive_shell.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)

## 修改策略

- 首页只负责容器和导航，不要承接具体业务逻辑
- 改 tab 结构时，同时验证 dynamic/trend/my 三个入口
- 改搜索入口时，要验证右上角位置计算与动画起点

### 新增 / 删除 / 重排 tab 时（强制流程）

在 [home_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart) 里**同步**改两处：

1. `tabItems`（`List<Widget>`，当前实现是 `Tab(child: Column(icon + text))`；compact 断点由 [GSYTab.TabBar](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabs.dart) 消费。**不是** Material `BottomNavigationBarItem`）
2. `railDestinations`（`List<GSYAdaptiveDestination>` 列表，medium/expanded 断点用）

**严格约束**：

- 两个列表的**长度必须相等**，否则 [GSYTabBarWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart) 自保直接跌回 compact 分支（`GSYTab.TabBar`）——用户在横屏 / 平板上看不到 Rail，很难 debug
- 两个列表的**顺序必须一致**（同一个 `_index` 驱动 `PageView`）
- 使用 `GSYAdaptiveDestination(icon: ..., label: ...)`，**禁止**直接用 `NavigationRailDestination`（那是 Material 骨架的实现细节，属于 delegate 内部）
- **禁止**在页面里 `import 'package:flutter/material.dart' show NavigationRail`
- **禁止**在页面里手写 `MediaQuery.sizeOf(ctx).width < 600` / `context.orientation == landscape` 之类的裸判断，一律走 `context.gsyWindowSize` / `GSYAdaptiveNavigation.instance.shouldUseRail(context)`

### 涉及 Rail 骨架自身行为改动时

- 改 rail 视觉（颜色、宽度、图标间距）：改 [MaterialAdaptiveNavigationDelegate.buildRail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L60-L108)，不要改页面
- 改断点阈值 / rail 触发条件：改 [MaterialAdaptiveNavigationDelegate.shouldUseRail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart) 或调 [GSYBreakpoints](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L13-L28)
- 换整个骨架体系（例如上侧 Tab Bar、抽屉式 Drawer、`flutter_adaptive_scaffold` 继任者）：新增一个 `GSYAdaptiveNavigationDelegate` 实现，在应用启动早期 `GSYAdaptiveNavigation.instance.setDelegate(...)` 注入
- 每次改抽象层，**必须先更新** [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart)（契约测试：Delegate 可替换 + `shouldUseRail` 断点行为），再改实现

## 最低验证

1. 首页可正常进入
2. 三个 tab 可切换
3. 双击 tab 可回到顶部
4. 搜索入口可打开搜索页
5. Android 返回键行为符合预期
6. **旋转 / resize 到 medium/expanded 断点后 Rail 出现，回到 compact 后 Bottom Tab 恢复**（截图放到 `tool/dbg/adaptive_p1_iso/` 或类似目录，路径写进完成汇报）
7. 若改了抽象层：`flutter test test/common/style/gsy_adaptive_shell_test.dart` 与 `flutter test test/common/style/gsy_responsive_test.dart` 全绿

## 收尾步骤

首页容器相关改动在完成验证后，必须先经过新的 reviewer subagent 审查。
这是容器层改动，不应由 author 自己直接宣布完成。
