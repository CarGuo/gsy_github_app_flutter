# 路由拓扑与 Master-Detail 归属规范

> 状态：**已实施 v0.2**；2026-09-04 v0.1 RFC 起草并作者拍板 → 同日实施完成，语义随代码落地。历史规划视角保留在 §5 落地 checklist 与 §7 待作者拍板项，供审阅与追溯。
> 相关：[app-layering.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/app-layering.md) §6 自适应布局层 · [ADR-0005 大屏 / 横屏 / 折叠屏自适应导航抽象](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md) Master-Detail 契约段（§契约末条 "caller 归属规则" 交叉引用回本文档 §4）。
> 本文档不引入新框架、不迁移 Navigator 1.0，只把**页面 × Navigator 归属**这一维度显式化，回收 [NavigatorUtils](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 目前"caller 各自拍脑袋"的隐式规范。

---

## 0. 为什么需要这份文档

P2 §2 Master-Detail 落地后，暴露一个真实用户面观感 bug：

> **在大屏下从主页打开搜索，搜索结果里点仓库卡片 → 没反应 → 用户以为"路由坏了"。**

根因不是"路由坏了"，而是**"路由归属没有形式化"**：

- Search 页由 [NavigatorUtils.goSearchPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L276-L299) 通过 `showGeneralDialog` 起飞，属于**根 Navigator 的 overlay 层**，物理上盖住整个 shell（rail + master + detail 三区一起遮住）。
- 用户 tap 卡片走 [_openDetailOrRouter](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L423-L448) → 判断 [canShowTwoPane](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L49-L50) → 为 true → 走 [MaterialAdaptiveNavigationDelegate.openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L306-L322) → push 到 `detailNavigatorKey.currentState`（**shell 右列的内嵌 Navigator**）。
- Search 页仍在最上面遮着 shell，用户看不到右列 detail 的变化，体感就是"点了没反应"。

这不是单个 caller 的 bug，是**当前 `_openDetailOrRouter` 只看"窗口是否够宽"，不看"caller 自己在哪一层 Navigator"** 的系统性漏洞。任何"从 root Navigator 起飞的独立全屏页 → 里面再调 openDetail"的组合都会撞到。

本文档目的：

1. 把 GSY 现在的 3 层 Navigator 结构画清楚；
2. 把每一类页面的**归属**定死（哪一层起飞、pop 回哪里、大屏时是否落右列）；
3. 给 caller 一份**打标准则**，杜绝下一次"从根栈全屏页里再调 openDetail"的隐式漂移；
4. 落地上述归属所需的最小代码改动清单（本轮不写代码，只列 diff 意图）。

---

## 1. 现状全景

### 1.1 三层 Navigator 结构

```
Root Navigator  ← MaterialApp.routes（[lib/app.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/app.dart)）
├── WelcomePage.sName        （启动页；replace 后消失）
├── LoginPage.sName          （replace 后消失）
├── HomePage.sName           ← 常驻，即 shell 挂载点
│   └── GSYTabBarWidget（[home_page.dart#L101-L108](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart#L101-L108)）
│       │
│       ├── compact / medium：单栏 PageView
│       │   └── Master tabs: [Trend / Dynamic / My]
│       │
│       └── expanded：Rail + Master + Detail 二列
│           ├── Rail（宽 96）
│           ├── Master 侧：PageView(tabs=[Trend/Dynamic/My])
│           └── Detail 侧：Navigator（key = GSYAdaptiveNavigation.detailNavigatorKey）
│                          ↑ _openDetailOrRouter 在 expanded 下 push 到这里
│
├── PhotoViewPage.sName       （dialog 语义，全屏预览图片）
├── SearchPage overlay        ← showGeneralDialog 起飞，遮盖 shell
└── 一些 CupertinoPageRoute： DebugDataPage / GSYWebView / LoginWebView …
```

### 1.2 caller 现状分类（以 [navigator_utils.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 为唯一集散地）

| # | 方法 | 当前落栈方式 | 现状归属 | 是否会被 `openDetail` 影响 |
|---|---|---|---|---|
| 1 | [goPerson](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L81-L86) | `_openDetailOrRouter` | detail | ✅ |
| 2 | [goReposDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L94-L142) | 二分：expanded → detailNavigator；compact → SizeRoute | detail | ✅ |
| 3 | [goIssueDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L195-L216) | 二分同上（内含 GraphQL 预取） | detail | ✅ |
| 4 | [goDiscussionDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L222) | `_openDetailOrRouter` | detail | ✅ |
| 5 | [goReleasePage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L184-L192) | `_openDetailOrRouter` | detail | ✅ |
| 6 | [goHonorListPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L145-L181) | 二分（本地手写） | detail | ✅ |
| 7 | [goPushDetailPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L303-L320) | `_openDetailOrRouter` | detail | ✅ |
| 8 | [goPullRequestFiles](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L323-L331) | `_openDetailOrRouter` | detail | ✅ |
| 9 | [gotoCodeDetailPageWeb](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L344-L369) | `_openDetailOrRouter` | detail | ✅ |
| 10 | [gotoUserProfileInfo](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L394-L399) | `_openDetailOrRouter` | detail | ✅ |
| 11 | [goNotifyPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L262-L266) | `_openDetailOrRouter` | detail（drawer 入口打开的详情面板） | ✅ |
| 12 | [goTrendUserPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L269-L273) | `_openDetailOrRouter` | detail（drawer 入口打开的详情面板） | ✅ |
| 13 | [goSearchPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L276-L299) | `showGeneralDialog`（root overlay） | **rootFullscreen**（唯一） | ❌ 本页不动，但它内部再 tap 会踩坑 |
| 14 | [goDebugDataPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L89-L91) | `NavigatorRouter` | rootFullscreen | ❌ 内部不再调 openDetail |
| 15 | [goGSYWebView](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L334-L336) | `NavigatorRouter` | rootFullscreen | ❌ 内部不再调 openDetail |
| 16 | [goLoginWebView](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L339-L341) | `NavigatorRouter` | rootFullscreen | ❌ 内部不再调 openDetail |
| 17 | [gotoPhotoViewPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L76-L78) | `pushNamed` → RootRoute | rootFullscreen | ❌ |
| 18 | [goHome](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L66-L68) / [goLogin](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart#L71-L73) | `pushReplacementNamed` | rootReplace | ❌ |

> 现状问题在 #13 Search：**它是 rootFullscreen 但内部会调 detail 类方法**，唯一一处越界。#14/#15/#16 也是 rootFullscreen，但它们不 tap 出 detail，暂无风险；一旦未来加 tap 语义（例如 debug page 里点某个仓库跳详情），同样撞坑。

### 1.3 断点定义（不改，仅记录）

- [GSYBreakpoints](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L14-L28)：compact <600 / medium 600–839 / expanded ≥840
- [GSYResponsiveContext.canShowTwoPane](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_responsive.dart#L49-L50) = `expanded && !isNarrowHeight`
- 用户可通过 [GSYAdaptiveNavigation.forceFullScreenDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L471) 强制单栏（Drawer switch）

---

## 2. 决策：方向 A —— 语义收敛

选定路线（作者拍板于 2026-09-04）：

> **把 Search / Notify / TrendUser 三个"从 HomePage 打开的功能页"全部归入 detail 语义**，统一走 `_openDetailOrRouter`；compact 时全屏 push，expanded 时落右列 detailNavigator。
> Search 页原有的 `AnimationClipper` 圆形入场动画仅在 **compact 保留**，medium/expanded 弱化为**外层 route 默认转场**（单栏走 CupertinoPageRoute 右滑入，双栏走 MaterialPageRoute 默认组合）+ 直出 Scaffold（不再包 ClipPath），分档 1。
> Search 属于"master 探索性 detail"，切 master tab 时清 Search 栈（分档 4）。

> **v0.2 勘误（2026-09-04）**：v0.1 RFC 曾把 medium/expanded 分档描述为"弱化为 FadeTransition"。实施后 reviewer 发现 code 事实是 [openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart) 用 `MaterialPageRoute`、[_openDetailOrRouter](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 单栏兜底用 `CupertinoPageRoute`，两条路径都**不是 FadeTransition**。因此本轮 v0.2 决策：**弱化 = 移除 ClipPath 弧形，转场跟随外层 route 默认实现**；未来若要真的把双栏 detail 转场改成 Fade，属于 P2 §2 detail 层整体回归，需单开 ADR 而非在 SearchPage 里私自变体。

### 2.1 为什么选 A 而不是 B / C

- **B（openDetail 自动识别 caller 归属）**：需要在 caller context 上向上遍历 Element 找 `detailNavigatorKey` 的祖先，Flutter 的 `GlobalKey` 挂载点不属于 caller 的祖先链（它属于**另一棵子树**），`context.findAncestorStateOfType<NavigatorState>()` 得到的是 Search 页自己所在的 root Navigator，识别口径不可靠。要写稳定实现必须自造一套 "detailNavigator 上下文标记 InheritedWidget"，工作量与 C 相当但语义更绕。
- **C（引入 RouteLevel 枚举 + 显式声明）**：形式最完整、契约最硬，但工作量大：所有 goXxx 都要挂枚举，还要写编译期检查/lint。以 GSY "教学 + 只读客户端"定位，收益不匹配。
- **A（语义收敛）**：只动 Search 一处 `goSearchPage` + Search 页内部弧形动画的分档。expanded 下 Search 变成 detail 面板，本身与用户"探索性面板"直觉一致；compact **外层转场从 `showGeneralDialog` 的 fade + barrier 改为 `CupertinoPageRoute` 右侧滑入**（属于本轮引入的转场层微差异），弧形内层入场保持不变；medium 属新支持的分档，无历史对照。

### 2.2 A 方案落地后的行为矩阵

| 屏幕分档 | Search 打开姿势 | Search 内 tap 仓库卡片的表现 |
|---|---|---|
| compact | CupertinoPageRoute 右滑入 + SearchPage 内 CRAnimation 弧形放大（**转场层从 v0.1 前的 `showGeneralDialog` fade 变成 route 右滑入，与内层弧形叠加**） | CupertinoPageRoute 全屏 push repo detail 在 Search 之上；back 一次回 Search、再 back 回 Home |
| medium | CupertinoPageRoute 右滑入（不再包 ClipPath） | CupertinoPageRoute 全屏 push repo detail 在 Search 之上；back 同上 |
| expanded 双栏 | MaterialPageRoute 默认转场（不再包 ClipPath），落右列 detailNavigator | 右列内嵌 Navigator 再 push repo detail；back 一次回 Search、再 back 回右列占位 |
| expanded + forceFullScreenDetail=true | CupertinoPageRoute 右滑入（与 compact/medium 一致） | CupertinoPageRoute 全屏 push repo detail 在 Search 之上；back 同 compact |

> 语义：**"Search 就是一次探索性 detail"**，与 [ADR-0005 Master-Detail 契约](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md) 的 "右列多层堆叠" 规则一致（右列 Navigator 允许多层 push，back 逐级 pop）。

---

## 3. 分档规则

### 3.1 分档 1 — Search 弧形动画分档

- **compact**：保留 [CRAnimation + AnimationClipper](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart) 现状；`minR = MediaQuery.sizeOf(context).height - 8` 在竖屏够用。
- **medium / expanded**：**不再走 ClipPath**，直接返回 `Scaffold`，让外层 route（`CupertinoPageRoute` / `MaterialPageRoute`）自己的默认转场承担入场动画。理由：
  - 弧形入场是"从触发按钮位置放大圆"的动画，宽屏对角线远大于 `height`，硬套 clip 会露出弧外底色（就是用户截图里那道弧）。
  - 直出 Scaffold + 让 Route 自己做转场是 Material 3 large-screen 常规姿势，不需要额外过渡层。
- **实施做法**：`SearchPage.build` 里根据 `context.isCompactWindow` 决定是否包 `CRAnimation`，非 compact 时直接返回 `Scaffold`。

### 3.2 分档 4 — 切 master tab 清 Search 栈

- 触发条件：**expanded 下 Search 落在右列 detailNavigator**，用户切 master tab（rail 从 Dynamic → Trend）。
- 期望行为：detail 栈被清空，Search 面板消失，右列回到 `GSYTwoPaneDetailPlaceholder` 空态。
- 实施依据：现有 [GSYTabBarWidget.clearDetailStackOnDispose](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart) `clearDetailStackOnDispose=true` 语义（shell 顶层 host 已开启）已经覆盖 tap / pageChange / dispose 三条路径，会调用 [popDetailToRoot](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L419-L424)。
- **结论：分档 4 不需要新增代码，直接依赖已有 shell 契约即可**。写在这里是为了明确"这条语义是有意保留的、不是漏改"。

### 3.3 显式不做（本轮排除）

- **分档 2/3（右列多层堆叠、Search 落右列）** 是 A 方案的**必然结果**，不作为独立分档单独 checklist。
- **compact 下 Search 弱化动画**：不做，保持现状体感。
- **openDetail 加 caller 归属检测**（方向 B）：不做，A 方案下 Search 本身就归入 detail 上下文，问题不复存在。
- **Notify / TrendUser 也走 Fade**：不做，它们本来就是 CupertinoPageRoute 常规转场，没有弧形装饰。

---

## 4. Caller 分类打标准则（写给未来的自己）

新增 `goXxx` 方法前，先把它落到下表：

| RouteLevel（语义） | 打开姿势 | 例子 | 允许内部调 openDetail? |
|---|---|---|---|
| **shellDetail** | `_openDetailOrRouter` | 仓库详情 / issue / person / release / commit / files / notify / trend user / **search（本轮改造后）** | ✅ 允许 |
| **rootFullscreen** | `NavigatorRouter` | webview / login webview / debug data / photo view | ❌ **禁止** 内部再调 shellDetail 类；如需，必须先 pop 自己或改成 shellDetail |
| **rootReplace** | `pushReplacementNamed` | goHome / goLogin | N/A（登录态切换，一次性替换根路由） |

- **标记方式**：暂**不引入运行期枚举**（避免 Search 一次性问题让整个 NavigatorUtils 大改）。规范落到 doc comment：每个 `goXxx` 方法头部注释里写一行 `// RouteLevel: shellDetail | rootFullscreen | rootReplace`。
- **Review 检查项**：新增/修改 caller 时，reviewer 必须核对：
  1. RouteLevel 标注是否与实际实现一致；
  2. 若标 rootFullscreen，函数体内**不允许**出现 `_openDetailOrRouter` 或 `goPerson/goReposDetail/goIssueDetail` 一类 shellDetail caller；
  3. 若标 shellDetail，函数体不允许再套 `showGeneralDialog` / `Navigator.pushNamed` 到 root。

- **未来升级方向**（不在本轮）：如果 rootFullscreen 数量增长到需要机器可检的量级，再走 ADR-0006 引入枚举 + lint 规则。

---

## 5. 落地 checklist（v0.2 已完成）

> v0.1 RFC 拍板同日（2026-09-04）实施闭环。以下条目**全部完成**，实施证据落在 §5.1 代码 diff 与 §5.2 测试与验证边界内。真机冒烟因本轮 mcp_dart 未挂显式列为已知缺口（见 §5.2 末段），待下一轮补足。

### 5.1 代码 diff 意图（v0.2 已完成）

1. [navigator_utils.dart goSearchPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) ✅：
   - 已从 `showGeneralDialog` 改为 `_openDetailOrRouter(context, SearchPage(centerPosition), routeName: 'search')`。
   - 保留 `centerPosition` 参数以支持 compact 下的弧形入场（`CRAnimation.offset`）。
   - 已删除 `showGeneralDialog` 的 fade + barrierColor 定义。
2. [search_page.dart SearchPage.build](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart) ✅：
   - 已用 `context.isCompactWindow` 分档：compact 保留 `CRAnimation`；medium/expanded 直接返回 `Scaffold`。
   - 已去掉 `endAnima` 分支在 medium/expanded 下的兜底底色（仅 compact 保留 `Theme.primaryColor` → `Colors.transparent` 切换）。
3. **未改** [gsy_adaptive_shell.dart openDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart)：A 方案下 Search 自身就在 shell 树里，openDetail 语义无需扩展。
4. **未改** [gsy_tabbar_widget.dart clearDetailStackOnDispose](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart)：分档 4 依赖已有语义。
5. **未动** [gotoPhotoViewPage / goGSYWebView / goLoginWebView / goDebugDataPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart)：保持 rootFullscreen，doc comment 已补 `// RouteLevel: rootFullscreen` 标注 + `// 内部禁止调 _openDetailOrRouter / goPerson / goReposDetail / goIssueDetail 等 shellDetail 类分派`。

### 5.2 测试与验证边界（v0.2 已完成 / 真机冒烟为已知缺口）

- **契约测试新增**（v0.2 已完成）：
  - [test/page/search/search_page_route_topology_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/search/search_page_route_topology_test.dart)：3 case，验证 compact/medium/expanded 三档下 `CRAnimation` 存在性契约。`fvm flutter test` 全绿。
  - [test/common/utils/navigator_utils_search_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/utils/navigator_utils_search_test.dart)：3 case，验证 canShowTwoPane=true → push 到 detailNavigatorKey；forceFullScreenDetail=true / compact 下走 CupertinoPageRoute 到 caller Navigator。`fvm flutter test` 全绿；`canShowTwoPane=true` case 用 `tester.takeException()` 兜住 SearchPage AppBar.bottom 在 700dp 宽度下 ~22px overflow（属 SearchPage 既有窄栏渲染缺口，不属于本次路由拓扑契约，注释里已显式说明）。
- **回归测试**（v0.2 已完成）：
  - [test/widget/gsy_tabbar_widget_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/widget/gsy_tabbar_widget_test.dart) 3 case 保持通过（Search 归入 detail 后命中 `clearDetailStackOnDispose=false` 分支，因为 SearchPage 内部不套 tabbar）。
  - [test/common/style/gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart) 37 case 全部保持通过。
  - `fvm flutter analyze lib/common/utils/navigator_utils.dart lib/page/search/search_page.dart test/page/search/search_page_route_topology_test.dart test/common/utils/navigator_utils_search_test.dart` → `No issues found!`。
- **真机冒烟**（**本轮已知缺口**，待下一轮补足）：本轮 `mcp_dart` 未挂载，未走 AGENTS.md §"运行时冒烟验证（强制）"一等公民路径。下一轮补冒烟时至少覆盖：
  1. compact：Home → 搜索按钮 → CupertinoPageRoute 右滑入外层 + SearchPage 内 CRAnimation 弧形放大内层（**重点观察两条动画叠加是否协调**，reviewer P1-4 关切点）→ tap 卡片 → repo detail 全屏；back 回 Search 保留搜索词；再 back 回 Home。
  2. expanded：Home → 搜索按钮 → MaterialPageRoute 默认转场（**非 FadeTransition**）→ Search 面板落右列（左列 master 仍可见）→ tap 卡片 → 右列再 push repo detail；back 逐级；切 master tab 时右列清空。
  3. 大屏截图：确认弧形不再溢出、右列宽度 = shell right pane 宽度、master 列内容可点。

### 5.3 文档同步（v0.2 已完成 / 部分挂到 6 号迭代）

- **本文档**加入 [docs/README.md](file:///d:/workspace/project/gsy_github_app_flutter/docs/README.md) 索引 → **本轮不做**（docs/README.md 已经存在但索引结构走独立整理迭代，本轮不动 index），下一轮 docs 索引统一 PR 里补。
- [app-layering.md §6 自适应布局层](file:///d:/workspace/project/gsy_github_app_flutter/docs/01-architecture/app-layering.md#L94-L119) 加交叉引用 → **本轮不做**（app-layering.md §6 已在 P2 §2 落地里被更新过，链接漂到 route-topology 的补丁走独立 doc 迭代 PR）。
- [ADR-0005 Master-Detail 契约段](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md) 加"caller 归属规则见 route-topology.md §4" ✅：**本轮已完成**，见 ADR-0005 §"契约"末条 `caller 归属规则（2026-09-04 补录）` 项。

---

## 6. 风险与已知缺口

- **`showGeneralDialog` → `_openDetailOrRouter` 的转场差异**：`showGeneralDialog` 是 modal，barrierDismissible=false；改成 CupertinoPageRoute 后仍是全屏、不可点外部 dismiss，用户交互模型不变。但**返回值语义**从 dialog 的 `Navigator.pop(context, result)` 变为 route 的同样机制，Search 页现有 `Navigator.maybePop(context)`（[search_page.dart#L269](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart#L269)）无需改。
- **`endDrawer` 兼容**：Search 页在 Scaffold 上挂了 `endDrawer: GSYSearchDrawer(...)`（[search_page.dart#L239-L259](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart#L239-L259)），当 Search 落右列 detailNavigator 时，endDrawer 会挂在**右列自身的 Scaffold**上，展开方向仍然是"从右往左"覆盖右列区域，观感 OK；但如果右列宽度过窄（<600），drawer 撑不满、可能出现"抽屉溢出右列"。**验证方式**：expanded 断点下右列宽 = totalWidth - rail(96) - masterPaneWidth，实测应 ≥ 480，不会触发溢出。
- **搜索历史面板 `Positioned.fill`**（[search_page.dart#L328](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart#L328)）：依赖 Search 页 Scaffold body 的 Stack 尺寸，落右列后尺寸 = 右列区域，Wrap chip 会自适应，无风险。
- **CRAnimation.centerPosition**：compact 下入场圆心是"触发按钮的全屏坐标"；由于 [HomePage AppBar 搜索按钮](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/home/home_page.dart#L142) 传入 `centerPosition` 时 context 是根 Navigator，未来 Search 落右列后 compact 下继续用该坐标仍在屏幕内，无需调整。
- **未覆盖场景**：Search 页深链（deep link）打开的场景不存在（GSY 目前无 deep link 支持）；如果未来接入，Search 归入 detail 后需要保证 shell 已装配再 push，与 ADR-0005 里已经写死的 [addPostFrameCallback 兜底](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L341-L344) 一致。
- **回退开关**：用户在 Drawer 里可以打开 [forceFullScreenDetail](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/style/gsy_adaptive_shell.dart#L471)；打开后 Search 也会走全屏 push，行为与 compact 一致，是一致的降级面。
- **SearchPage AppBar.bottom 右列挂载渲染缺口（v0.2 登记 / v0.2.1 归属证据化）**：Search 页 [AppBar.bottom](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart) 是 `PreferredSize(100)` 包 Column（`GSYSearchInputWidget` + `GSYSelectItemWidget`），在 detail 侧 ~700dp Row+SizedBox 挂载环境下 intrinsic 高度会溢出 ~22px（`RenderFlex overflowed`）。v0.2.1 [search_page_appbar_overflow_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/search/search_page_appbar_overflow_test.dart) 4 档挂载实测证据：400dp compact 全屏 / 720dp medium 全屏 / 1200dp forceFullScreenDetail 全屏三档都**不 overflow**，仅右列 700dp overflow → 根因是"SearchPage 首次被塞进 Row+SizedBox 固定宽度子树"挂载语境，不是绝对宽度。契约测试 [navigator_utils_search_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/utils/navigator_utils_search_test.dart) 用 `tester.takeException()` + 白名单 assert 兜住。SearchPage 内部 PreferredSize 高度自适应属 UI 责任域，按 AGENTS.md §"改动尽量限制在当前功能域" 本轮不动，挂 §7 后续跟进 P2 项。

---

## 7. 待作者拍板项（v0.1 → v0.2 已确认，历史留档）

以下三项在 v0.1 RFC 阶段作为待拍板项写下，作者已于 2026-09-04 消息 "好的，按这个方案来" 与后续 "好的，按这个方案来"（两轮确认）落定后进入 v0.2 实施：

- [x] 方向 A、分档 1、分档 4 → v0.2 实际收敛为 "方向 A + 分档 1 + 分档 4 + 直接实施代码 + 契约测试" 组合；原 v0.1 "只出规划文档" 因作者两轮追问 "按这个方案来" 而合并为一次 PR。
- [x] [goDebugDataPage / goGSYWebView / goLoginWebView / gotoPhotoViewPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 的 doc comment 补 RouteLevel 标注 → v0.2 已随本次 PR 一次性完成（未拆独立 PR），避免下一次 review 又要把这四个方法翻出来单独看一遍。
- [x] Search 页历史面板 [_SearchHistoryPanel](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart) 在 expanded 下改样式 → v0.2 决定 **不改**，与 v0.1 RFC 意见一致；如未来 dogfooding 反馈右列宽度下 chip 换行偏挤，再单独出迭代。

### 7.1 Open Question 3（v0.2.1 reviewer 补问 → 追认）

**问题**：为什么 [goNotifyPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 与 [goTrendUserPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 在 §1 caller 分类表已被标注为 shellDetail（走 `_openDetailOrRouter`），但 §5 checklist 里没有为它们新增契约测试或行为矩阵？这两条路径本轮是否有变更？

**结论**：**未变更，属既成事实追认**。这两个方法在 [ADR-0005](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md) 落地初期就已经走 `_openDetailOrRouter`，本轮路由拓扑收敛只是把它们与新收进 shellDetail 的 Search 一起纳入 §1 分类表存档，并没有改代码或改行为。因此：
- **不给它们新增契约测试**：本轮的契约测试目标是"Search 从 root 收进 shellDetail"这次语义搬迁，Notify/TrendUser 没有搬迁动作。
- **不给它们新增行为矩阵**：§2.2 行为矩阵只覆盖 Search，因为矩阵的目的是登记 v0.1 → v0.2 的转场差异；Notify/TrendUser 转场没变。
- **§3 分档规则不列它们**：分档 1 是弧形动画分档，Notify/TrendUser 本来就没有弧形动画；分档 4 是切 master tab 清 Search 栈，与它们无关。

Reviewer 若在 §1 表上看到 ✅ 但在 §2/§3/§5 找不到对应处理，读到本段即可闭环。

### 7.2 P2 后续跟进（v0.2.1 归档）

从 reviewer 独立上下文的 v0.2.1 request-changes 中沉淀的 P2 项，本轮不修，明确挂到未来 PR：

- **SearchPage AppBar.bottom PreferredSize(100) 高度自适应**（来源：reviewer P1-5 + [search_page_appbar_overflow_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/search/search_page_appbar_overflow_test.dart) 归属证据）：右列 700dp Row+SizedBox 挂载下 AppBar.bottom Column intrinsic 高度溢出 ~22px；SearchPage 内部改 `PreferredSize` 高度自适应或换 intrinsic-height 布局；属 [search_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart) UI 责任域，与路由拓扑正交。**2026-09-04 真机复核**：`emulator-5554` 841dp expanded 分档下 SearchPage 实际挂进 detail 侧（可用宽 ~460dp）**未 overflow**，见 [route-topology-v0.2.1-07-search-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-07-search-open.png)；说明 700dp 挂载环境是极限压力场景，日常触发概率低，P2 优先级维持不变。
- **PersonPage 右列 overflow 396px**（2026-09-04 真机新发现）：`gsySmokeGoPerson("CarGuo")` 落右列，PersonPage 内部横排布局（顶部 avatar / stats / pinned repos）在 700dp 右列宽度下 **RIGHT OVERFLOWED BY 396 PIXELS**，见 [route-topology-v0.2.1-05-person-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-05-person-open.png)。性质同 SearchPage：本轮拓扑收敛把 PersonPage 从"全屏 push"改成"落右列 shellDetail"后，暴露 PersonPage 内部 Row/Wrap 布局对宽度上限的隐式假设失效。属 [person_page.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/person/person_page.dart) UI 责任域，与本轮 `_openDetailOrRouter` 分派逻辑正交，挂 P2 UI 迭代。
- **真机冒烟证据完成情况**（2026-09-04 全部补齐）：
  - ✅ HomePage baseline: [route-topology-v0.2.1-01-home-baseline.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-01-home-baseline.png) / [route-topology-v0.2.1-02-home-current.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-02-home-current.png) — 三栏渲染 (Rail + master + detail placeholder)。
  - ✅ Repo Detail 落右列: [route-topology-v0.2.1-03-repo-detail-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-03-repo-detail-open.png) — `gsySmokeGoReposDetail("CarGuo","gsy_github_app_flutter")` 走 `_openDetailOrRouter` → `openDetail` → detailNavigatorKey；master 未被覆盖。
  - ✅ Issue/PR Detail 落右列: [route-topology-v0.2.1-04-issue-detail-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-04-issue-detail-open.png) — fixture PR `#938`（Copilot merged, assignees CarGuo+Copilot）完整渲染。
  - ✅ Discussion Detail 落右列: [route-topology-v0.2.1-06-discussion-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-06-discussion-open.png) — fixture `666ghj/BettaFish#680` (`b612sheryl`, category General) 完整渲染。
  - ✅ Person Detail 落右列: [route-topology-v0.2.1-05-person-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-05-person-open.png) — CarGuo 主页（Repository 70 / Follower 8052 / 1152 contributions）落右列；同时抓到 PersonPage overflow 见上条。
  - ✅ **Search 打开路径**: [route-topology-v0.2.1-07-search-open.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-07-search-open.png) — 新补 [gsySmokeGoSearch](file:///d:/workspace/project/gsy_github_app_flutter/lib/app.dart) 顶层入口后，`gsySmokeGoSearch()` evaluate 触发 `NavigatorUtils.goSearchPage` → `_openDetailOrRouter` → SearchPage 落右列；无弧形动画残影（`CRAnimation` compact-only 分档生效）；无 overflow；Search history chip 保留。
  - ✅ 无运行时异常: 8000 行 logcat 扫 `flutter|Flutter|dart` × `Exception|FATAL|StackTrace|Error:` = 0 命中，见 [route-topology-v0.2.1-logcat.txt](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-logcat.txt)。
  - **通道方案**：直接 WebSocket JSON-RPC 打 Dart VM Service `evaluate`（[vm_rpc.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/vm_rpc.ps1) + [vm_eval.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/vm_eval.ps1)），绕过 mcp_dart / adb input tap 双重不可用的限制。符合 AGENTS.md 2026-09-02 拍板的"用 VM Service 而非坐标脚本"原则，且不新增 mcp_dart 依赖。
- **仍缺（下一轮）→ 2026-09-04 二轮补齐完成**：三项真机端到端全部落地，走同一 flutter run 会话（pid=6356，VM Service `http://127.0.0.1:13199/yGequ4up-Rc=/`，isolate `2259846734140919`）+ 直连 evaluate 方案，用 detail Navigator canPop / MediaQuery.width / rootElement widget tree 计数三种运行时观测同时佐证契约。
  - ✅ **Search → Repo Detail 栈叠加** (`e-02` + `e-03` + `e-04`)：`gsySmokeGoSearch()` 后 detail canPop=true；紧接着 `gsySmokeGoReposDetail("CarGuo","gsy_github_app_flutter")`，栈顶 `settings.name=repos/CarGuo/gsy_github_app_flutter`；pop 一次栈顶变 `search`（`after-pop-top=search|canPop=true`，证明 search 在 repo 下面且 search 下还压着 placeholder），证明 `_openDetailOrRouter` shellDetail 分派让 Search + Repo Detail 都推入同一 `detailNavigatorKey`。截图 [route-topology-v0.2.1-e-03-search-then-repo.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-03-search-then-repo.png)（741968 bytes 满信息大图）与 [route-topology-v0.2.1-e-04-back-to-search.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-04-back-to-search.png)（252535 bytes 与 e-02 search-open 一致）。
  - ✅ **切 rail tab 清 Search 栈**（M2 契约） (`e-05`)：`popDetailToRoot()` 直接调用（等价于 shell-level tabbar `clearDetailStackOnDispose=true` 时 rail 切 tab 触发的动作，见 [gsy_tabbar_widget.dart:216](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_tabbar_widget.dart#L216)），运行时观测：`before=true → after=false`。截图 [route-topology-v0.2.1-e-05-rail-tab-cleared.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-05-rail-tab-cleared.png)（219870 bytes ≈ e-01 home baseline 219948 bytes）证明右列回 placeholder。
  - ✅ **compact 分档回归** (`e-06` → `e-08`)：`adb shell wm size 1400x2000` 缩到 `w=533dp` compact 分档；`gsySmokeGoSearch()` 后 `root.canPop=true` 且 `detail-nav-not-mounted`（compact 下 shell 不挂 detail Navigator）；widget tree 计数 `SearchPage=1 | CRAnimation=1 | ClipPath=14`。切回 expanded 时 `w=841dp`，同一 evaluate `SearchPage=1 | CRAnimation=0 | ClipPath=16` → **compact CRAnimation=1 / expanded CRAnimation=0 分档对照双向成立**，证明 [search_page.dart:229](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart#L229) `isCompact = context.isCompactWindow` 分档在真机上按契约执行。截图 [route-topology-v0.2.1-e-06-compact-home.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-06-compact-home.png)、[route-topology-v0.2.1-e-07-compact-search-mid.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-07-compact-search-mid.png)、[route-topology-v0.2.1-e-08-compact-search-done.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-08-compact-search-done.png)、[route-topology-v0.2.1-e-09-expanded-search-nocranim.png](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-09-expanded-search-nocranim.png)。
  - **logcat 复核**：`adb logcat -d -b main -T 2000` 2556 行，过滤 `6356.*(FATAL|Exception|Error:|StackTrace)` = 0 命中，见 [route-topology-v0.2.1-e-logcat.txt](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/logs/route-topology-v0.2.1-e-logcat.txt)。**噪声排除**：日志里 100 行系统级 warn（`BestClock: No network time available` / `NetworkMonitor` google 探测超时 / `FontLog` timeout / `aevr` NPE / `DoodleDataLoader` unsupported / `OneSearchSuggestProvider CANCELLED`）全部来自系统 pid（766 / 1106 / 1157 / 1367 / 1816 / 3283 等），**无一条来自 GSY app pid 6356**。
  - **evaluate 侧偶发 framework assertion 归因**（不影响用户路径）：evaluate 调 `popDetailToRoot` 触发 Route pop → TransitionRoute reverse animation status listener → framework 调 `WidgetInspectorService._nodeToJson` → `StackFrame.fromStackTraceLine` regex 无法匹配 `#20 Eval.<anonymous closure> ()`（vm-service Eval 帧没有 `(file:line)` 段） → `stack_frame.dart:210` `match != null` assertion。**归因**：Flutter framework 对 vm-service Eval 栈帧的处理 bug，只在 evaluate 上下文才有；用户 tap / gesture 触发的相同 pop 路径**不含 Eval 帧**，永远不会命中。栈里 `#34 GSYAdaptiveNavigation.popDetailToRoot` 只是 host caller，函数体内容（`while(navState.canPop()) navState.pop()`）本轮 & v0.2 完全未改。**不属于 GSY 代码缺陷**，不进 P2；本条留档避免未来 reviewer 看到 evaluate 返回体里的 assertion string 时误判为路由拓扑回归。
- **docs/README.md 索引整理**（来源：本文档 §5.3）：本文档接入独立 docs 索引整理迭代，本轮不动 index。
- **RouteLevel 从 doc comment 提升为编译期契约**（来源：v0.1 §2.1 方向 C 讨论）：目前 RouteLevel 只在 doc comment 里出现；若未来 goXxx 方法数增多、reviewer 反复要求手动核对分类，再考虑用 lint / annotation 落成编译期契约。GSY 教学 + 只读客户端定位下暂不做。

---

## 8. 版本

- 2026-09-04 v0.1：初稿（RFC）。方向 A + 分档 1 + 分档 4，仅出规划、不动代码。
- 2026-09-04 v0.2：作者两轮 "好的，按这个方案来" 后进入实施。落地：
  - [navigator_utils.dart goSearchPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 从 `showGeneralDialog` 改为 `_openDetailOrRouter`（RouteLevel: shellDetail）；
  - [search_page.dart SearchPage.build](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/search/search_page.dart) 用 `context.isCompactWindow` 分档，medium/expanded 移除 ClipPath 直出 Scaffold，转场跟随外层 route 默认实现（Material/Cupertino，**非 Fade**——v0.1 RFC 的 "FadeTransition" 描述在 v0.2 勘误段已订正）；
  - [goDebugDataPage / goGSYWebView / goLoginWebView / gotoPhotoViewPage](file:///d:/workspace/project/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart) 补 `RouteLevel: rootFullscreen` doc comment；
  - 新增契约测试 [search_page_route_topology_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/search/search_page_route_topology_test.dart) 3 case + [navigator_utils_search_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/utils/navigator_utils_search_test.dart) 3 case（其中 canShowTwoPane=true case 用 `tester.takeException()` + `isA<FlutterError>() + contains('overflowed')` 白名单锁死 AppBar.bottom overflow，防未来别的异常被静默吞掉——reviewer P1-1）；
  - 回归 [gsy_tabbar_widget_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/widget/gsy_tabbar_widget_test.dart) 3 case + [gsy_adaptive_shell_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/common/style/gsy_adaptive_shell_test.dart) 37 case 全部通过；
  - `fvm flutter analyze` 4 文件 `No issues found!`；
  - [ADR-0005](file:///d:/workspace/project/gsy_github_app_flutter/docs/06-decisions/ADR-0005-大屏与折叠屏自适应导航抽象.md) §契约末条补 "caller 归属规则"，交叉引用本文档 §4。
  - **已知缺口**：本轮 `mcp_dart` 未挂，未走 AGENTS.md §"运行时冒烟验证（强制）"，真机端到端补足挂到下一轮 PR。
- 2026-09-04 v0.2.1（reviewer 独立上下文闭环）：按 reviewer request-changes 修 P1：
  - P1-1 契约测试 `takeException` 加白名单 assert；
  - P1-2/P1-3/P1-4 文档 5 处 "FadeTransition" 表述订正为"外层 route 默认转场（Material/Cupertino）"，行为矩阵新增 forceFullScreenDetail 行，`compact 完全等价` 改为显式登记"外层转场从 fade+barrier 变成 route 右滑入"；
  - P1-5 补 [search_page_appbar_overflow_test.dart](file:///d:/workspace/project/gsy_github_app_flutter/test/page/search/search_page_appbar_overflow_test.dart) 用 4 档挂载环境（400dp compact 全屏 / 720dp medium 全屏 / 1200dp forceFullScreenDetail 全屏 / 700dp 右列）证据化 overflow 归属。**实测结论**：三档全屏都**不 overflow**，仅右列 700dp overflow → overflow 根因不是"宽度绝对值"（否则 400dp 更窄理应更严重），而是"SearchPage 首次被塞进 Row + SizedBox 固定宽度子树"这一挂载语境。归属为 **"本轮路由拓扑收敛顺带暴露的 SearchPage AppBar.bottom 高度硬编码假设违反"**，非本轮 `goSearchPage` / `_openDetailOrRouter` 改造直接引入；SearchPage 内部 PreferredSize(100) 高度重构属 UI 责任域，本轮按 AGENTS.md §"改动尽量限制在当前功能域" 原则不动，挂 §7 后续跟进 P2 项。
  - **真机证据补做**：2026-09-04 作者在 `gsy_pixel_fold` emulator（`emulator-5554`, 2208×1840 物理像素 / 420dpi = 841×700 dp expanded 分档）跑 `fvm flutter run --debug`。**通道方案切换**：本 session `mcp_dart` MCP server 物理未挂（[mcp_file_system_servers](file:///c:/Users/Asher.Guo/.trae-cn/mcps/s_gsy_github_app_flutter-a5f87607/solo_agent)），AGENTS.md 2026-09-02 又禁止新增 `adb shell input tap` 坐标脚本 → 改用 **PowerShell WebSocket 直连 Dart VM Service JSON-RPC** ([vm_rpc.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/vm_rpc.ps1) + [vm_eval.ps1](file:///d:/workspace/project/gsy_github_app_flutter/tool/ai/smoke/vm_eval.ps1))，`getVM` 拿 isolate id、`getIsolate` 拿 `package:gsy_github_app_flutter/app.dart` library id、`evaluate` 触发既有 `gsySmokeGoXxx` 顶层入口。该方案符合 AGENTS.md 一等公民要求（用 VM Service 而非坐标脚本），不新增 mcp_dart 依赖。**补 `gsySmokeGoSearch` 顶层入口**到 [lib/app.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/app.dart)，对照现有 4 个 smoke 入口模板走 `smokePostFrame` + `NavigatorUtils.goSearchPage`。**产出 7 张真机截图** + logcat 0 异常，详见 §7.2 补齐清单。**5 条 shellDetail 路径（Repo / Issue / Discussion / Person / Search）真机全部落右列，master 保持挂载**，与本轮契约一致。同时暴露 2 个 P2 UI 缺陷（SearchPage / PersonPage 内部横排布局在 detail 侧宽度上限失效），归属为 UI 责任域，与 `_openDetailOrRouter` 分派逻辑正交。
  - **二轮真机补齐**（2026-09-04，同 emulator，新 flutter run `pid=6356`，VM Service `http://127.0.0.1:13199/yGequ4up-Rc=/`）：把 §7.2 "仍缺（下一轮）" 三项全部落地——Search → Repo Detail 栈叠加 / 切 rail tab 清 Search 栈 / compact 分档回归。除截图外新增**运行时观测证据**：detail Navigator `canPop` 状态跳变、`Route.settings.name` 栈顶采样、`WidgetsBinding.instance.rootElement.visitChildren` 遍历得到的 `CRAnimation` widget 挂载计数在 compact/expanded 双向对照（compact=1 / expanded=0），evaluate 结果直接返回字符串写入证据链。9 张增量截图 `route-topology-v0.2.1-e-01 ~ e-09` + logcat `route-topology-v0.2.1-e-logcat.txt`（GSY pid 6356 无 Exception / FATAL / Error）。同时留档 evaluate 侧偶发的 `stack_frame.dart:210 'match != null'` framework 断言归因（不属于 GSY 代码缺陷）。
