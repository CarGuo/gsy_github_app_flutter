# tool/ai/smoke

GSY GitHub App 冒烟操作手册。用于满足 [AGENTS.md 运行时冒烟验证章节](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L67-L107)
中"UI 渲染 / 文案 / 事件行"级别改动的最低证据要求。

## 2026-09-02 全面转向 mcp_dart（不再有 adb 坐标脚本）

历史上这个目录堆了一堆 `.sh` / `.ps1` 坐标脚本（`adb shell input tap/swipe`）。
2026-09-02 作者拍板**全部删除**，回归 [mcp_dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L77-L107)：

1. **adb 只是 Android 平台工具**，天然把 iOS 排除在外——GSY 用 iOS Simulator 冒烟时它一点忙都帮不上。
2. **坐标硬编码脆弱**：分辨率一变就全坏；系统条高度、键盘弹起、tab 数量变化都会导致 tap 落错，反复吃过亏（旋转 override / 状态栏拦截 / 讨论 tab 是否可见 / IDE 缩略图坐标 vs 物理坐标）。
3. **`mcp_dart` 是随 Flutter 演进的一等公民**：直接连 DTD/VM Service，能拉真实的 `widget_inspector get_widget_tree`（含 `textPreview` 文案）、拉 `get_runtime_errors`，跨平台、随版本演进、天然消除坐标依赖。

因此本目录不再放执行脚本。每个冒烟场景改为一份**路径描述 md**，说明用 `mcp_dart` 该走哪条路径、该 grep widget tree 的哪几个命中项、该抓哪几张截图。

## 前置条件

1. 设备（iOS Simulator 或 Android 真机 / 模拟器）已启动、`flutter` 能识别到。
   - iOS：`xcrun simctl list devices booted`
   - Android：`adb devices`
2. GSY app 已在设备上运行（debug 首选，release 也可以）。
3. `flutter run` 的 stdout 里能看到 `Dart VM Service on ... is available at: <uri>`（debug 才有）。
4. 已登录任意 fixture 账号（推荐 `CarSmallGuo`，`gho_` token 只读）。

## 装机命令（重要）

**禁止使用 `flutter install`**。该命令内部走 `adb uninstall <pkg>` + `adb install`，
会顺手把 `/data/data/com.shuyu.gsygithub.gsygithubappflutter/` 下的全部
SharedPreferences 抹掉，`TOKEN_KEY` 一并没了——设备上等同强制登出，reviewer
无法直接复核 fixture。

正确姿势（已固化到 [AGENTS.md 禁止行为](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L137-L155)）：

**iOS**：

```bash
flutter build ios --release
# 装机走 Xcode 或
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
```

**Android**：

```bash
# 1. 构建 release APK（首选 arm64，跟 CarGuo 主设备一致）
flutter build apk --release --target-platform=android-arm64 --no-shrink

# 2. 用 adb install -r 覆盖安装，保留 app data
adb install -r build/app/outputs/flutter-apk/app-release.apk
#              ^^ 关键：-r = reinstall，保留 /data/data/<pkg>/
```

如果**必须**重装（例如包名或签名变了），先手动导出 token：Android 走 `run-as` +
`cat shared_prefs/FlutterSharedPreferences.xml`，iOS 走 Xcode Container 拷贝
`Library/Preferences/*.plist`。装完可以用 GSY 登录页的 "Token 登录" 入口
（见 [login_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/login/login_page.dart)）粘回来。

## 场景清单

| 场景 md | 覆盖对象 |
|---|---|
| [open_pr_timeline.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_pr_timeline.md) | PR timeline 事件行 / `reviewed body 卡片` |
| [open_home_dynamic.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_home_dynamic.md) | 首页 Dynamic tab / 事件识别 / 下拉刷新 + 上拉分页 |
| [open_repo_discussions_tab.md](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/open_repo_discussions_tab.md) | 仓库详情 → 讨论 tab / discussion 列表 / 详情页 Markdown |

每份 md 内含"目标 / fixture / 步骤 / 完成汇报必填 / 反例"。执行者按步骤走一遍，
把证据（widget tree 命中项 + 截图绝对路径 + `get_runtime_errors` 结果）写进
[AGENTS.md 完成汇报三段式](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/AGENTS.md#L129-L135)的"看运行"段。

## 通用步骤模板

**这是一个 Flutter 项目。**点击 / 触发 / 验证一律走 `mcp_dart`（VM Service 一等公民），
不基于 `adb` / 坐标 / 屏幕像素。`adb` / `xcrun simctl` 只承担"截图"这一件事。

1. **起 app**：`flutter run -d <deviceId>`，等 stdout 打印 DTD/VM Service URI。
2. **连 DTD**：`mcp_dart` `dtd listDtdUris` → `dtd connect <uri>`。
3. **基线**：`mcp_dart` `get_runtime_errors`（应为 `No runtime errors found.`）。
4. **触发路由 / 交互（一等公民 = `mcp_dart` `vm_service` `evaluate`）**：
   - GSY 已经在 [app.dart#L99-L163](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/app.dart#L99-L163)
     挂了全局 `GlobalKey<NavigatorState> navKey`，跳转全部走
     [navigator_utils.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/utils/navigator_utils.dart)
     里的 `NavigatorUtils.goXxx(context, ...)`。用 `widget_inspector` 拿任意
     `Element` 的 `objectId` 作为 `targetId`，然后 `evaluate`：

     ```
     evaluate(
       targetId: <element_object_id>,
       expression: 'NavigatorUtils.goIssueDetail(_element!.buildContext, "CarGuo", "gsy_github_app_flutter", "938")'
     )
     ```

   - 页面内交互（下拉刷新 / 上拉分页 / tab 切换）：拿到对应 `State` 的 `objectId`，
     eval `_pullLoadWidgetControl.onRefresh?.call()` / `_tabController.animateTo(3)` 之类。
   - **失败时**才降级。降级选项：
     - **降级 A**：给 `app.dart` 加一个 debug-only 顶层函数（`kDebugMode`），
       在 eval 里一行调用。**需作者拍板一次**再落地；落地后所有 md 共享。
     - **降级 B（最后的最后）**：人肉在 Simulator 上点。**必须在完成汇报里说明"这一步为什么无法自动化"**。
5. **拉 tree**：`mcp_dart` `widget_inspector get_widget_tree summaryOnly=true`，
   在返回 JSON 里 grep 该场景 md 指定的 `textPreview` 或 widget 类型。
6. **截图（仅人眼补充证据，不承担业务验证职责）**：iOS `xcrun simctl io <UDID> screenshot <path>`，
   Android `adb exec-out screencap -p > <path>`。
7. **收尾**：`mcp_dart` `get_runtime_errors` 再拉一次，应仍空。

## 为什么触发操作要走 `vm_service eval` 而不是 `adb shell input tap`

- GSY 是 **Flutter 项目**，widget 是 Dart 世界里的对象。`adb shell input tap X Y`
  只是在系统层伪造触摸事件，命中的是"屏幕像素点"，跟 Flutter 的 widget hit test
  没有直接映射：分辨率变一变、系统条高度变一变、键盘弹起 / tab 数量变一变，全炸。
  历史 fixture 已经反复吃过这个亏（旋转 override / 状态栏拦截 / IDE 缩略图坐标 vs 物理坐标）。
- `vm_service` `evaluate` 直接在 Dart 层执行表达式，等同于让 Dart 自己调用
  `NavigatorUtils.goXxx` / `TabController.animateTo` / 任意 controller 方法。
  **随 Flutter 版本演进、跨 iOS/Android、随 UI 微调不变**，天生就是 Flutter 项目该有的操控姿势。
- `adb` / `xcrun simctl` 因此在本仓库里降级为**只截图**的工具，不再承担业务操作职责。

## evidence/ 目录约定

- 默认 evidence 落到 [tool/ai/smoke/evidence/](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/ai/smoke/evidence)`<yyyymmdd_hhmm>/`，
  已通过根 [.gitignore](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/.gitignore) 里的
  `tool/ai/smoke/evidence/` 忽略，不入 git。
- 建议按任务号建子目录（例：`evidence/c1/`、`evidence/d1_selftest/`），
  在完成汇报里把子目录**绝对路径**贴出来，reviewer 就能定位到当次证据。

## 反例（禁止）

- ❌ **新增 `adb shell input tap/swipe` 坐标脚本**：本次全面清理的历史包袱，
  reviewer 见到直接打回。**Flutter 项目触发操作走 `vm_service eval`，不基于像素点**。
- ❌ **把"人肉在 Simulator 上点"当默认路径**：默认路径永远是 `mcp_dart` `vm_service eval`。
  只有 eval 走不通 + 降级 A（debug-only 顶层函数）也走不通，才允许降级 B（人肉点），
  且必须在完成汇报里说明"这一步为什么无法自动化"。
- ❌ **只截图不连 DTD**：截图只是"人眼层面补充"，不是业务证据；必须配 `widget_inspector` 命中和 `get_runtime_errors` 结果。
- ❌ **用 `flutter install` 装机**：见"装机命令"章节。
- ❌ **让用户手动操作 UI 代替自己自测**：author 必须自己走完路径。
- ❌ **拿"日志里没 Exception"当行为正确的证据**：必须命中 `widget_inspector`。

## 不做什么

- 本目录 md **不做断言**（要不要过看的是 `widget_inspector` 命中 + 截图 + `get_runtime_errors`）。
- 本目录 md **不 mock 数据**（要覆盖稀有事件分支请写单测 + JSON fixture）。
- 本目录 md **不依赖 `flutter_driver`**（本仓库未引入相关依赖）。
