# iOS Swift Package Manager 迁移操作手册

本文档记录本仓库从 CocoaPods 主路径切换到 Swift Package Manager（SPM）主路径的完整过程、
关键决策、验证锚点和已知缺口，方便未来任何 contributor（人或 agent）复核或推动下一步。

- 最后一次操作时间：2026-09-01（下午：iOS Token Login + 主页 Dynamic 冒烟证据补齐；晚间：sqflite 2.4.3 + patrol ^4.7.0 升级后 pod-only 从 5 降到 4；深夜：Plus 三兄弟 + share_plus + fluttertoast + talker_flutter + path_provider 联合大扫除，pod-only 从 4 降到 1；**凌晨追加：`rive 0.13.13 → 0.14.11`（`rive_common` 被 `rive_native` 完全取代且 rive_native 原生 SPM）+ `path_provider_foundation 2.5.1 → 2.6.0`（FFI 化，从 SPM 名单退出但不再需要 pod），pod-only 从 1 降到 0，第三方插件 100% 走 SPM，`Podfile.lock` 只剩 Flutter framework**）
- 操作时 Flutter 版本：3.48.0-0.3.pre master（Dart 3.14.0）
- 官方参考：<https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers>

## 为什么现在必须做

- **CocoaPods registry 于 2026-12-02 变只读**（官方公告，见上述文档顶部 Note），未来不迁走的项目会拉不到新版本 pod
- Flutter 3.44+ 默认启用 SPM；官方明确 "disabling SwiftPM won't be allowed in the future"
- 本仓库 iOS 部署目标本轮已同步升到 15.0（Flutter 3.47 硬要求），刚好一起把 SPM 主路径落地

## 本轮做了什么（可复核）

### 1. 项目级开关（`pubspec.yaml`）

在 `flutter:` 段开头加：

```yaml
flutter:
  config:
    enable-swift-package-manager: true
```

这是 **官方推荐位置**，好处是所有 contributor 拉下代码就自动生效，
不依赖每台机器都 `flutter config --enable-swift-package-manager`。

### 2. 机器全局开关（双保险）

```bash
fvm flutter config --enable-swift-package-manager
```

用于本机和 CI runner；`flutter config --list` 里应能看到
`enable-swift-package-manager: true`。

### 3. 重新 build 触发官方自动迁移

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build ios --simulator --no-codesign
```

Flutter 会自动往 iOS 工程写入这些改动（不需要手工进 Xcode）：

- `ios/Podfile`：iOS 部署目标 13.0 → 15.0
- `ios/Podfile.lock`：把已经支持 SPM 的插件（`flutter_inappwebview_ios / fluttertoast /
  patrol / CocoaAsyncSocket / OrderedSet / Toast`）从 CocoaPods 里移除
- `ios/Runner.xcodeproj/project.pbxproj`：删掉上述插件对应的 embed_frameworks 项
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`：**新增**，SPM 依赖锁
- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`：**新增**，同上，workspace 侧
- `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift`：
  由 flutter tool 每次 build 自动重生成（gitignore 不入库）

## 三个官方验证锚点（务必逐条对上）

参考官方文档 "How to turn on Swift Package Manager" 一节：

### 锚点 A：`FlutterGeneratedPluginSwiftPackage` 是 Runner target 的依赖

```bash
grep -c "FlutterGeneratedPluginSwiftPackage" ios/Runner.xcodeproj/project.pbxproj
# 期望：>= 8（本仓库当前 10 处引用）
```

### 锚点 B：`Run Prepare Flutter Framework Script` 作为 pre-action 挂在 Runner.xcscheme

```bash
grep -c "Prepare Flutter Framework" ios/Runner.xcodeproj/xcshareddata/xcschemes/*.xcscheme
# 期望：>= 1（本仓库当前 1 处）
```

### 锚点 C：ephemeral 里 `Package.swift` 存在且挂了所有 SPM 兼容插件

```bash
cat ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
```

本轮验证时 `Package.swift` 里挂到了这 13 个插件（2026-09-01 凌晨追加 rive 0.14 + path_provider_foundation FFI 化，SPM 名单组成质变但总数持平）：

- `connectivity_plus` @ 7.3.1（**2026-09-01 深夜新增 SPM**：从 6.0.5 升，跨主版本 6→7，dart 侧 `Connectivity()` API 未变）
- `device_info_plus` @ 13.2.0（**2026-09-01 深夜新增 SPM**：从 10.1.2 升，跨 3 个主版本，dart 侧 `IosDeviceInfo` / `AndroidDeviceInfo` API 未变）
- `flutter_inappwebview_ios` @ 1.2.0-beta.3
- `fluttertoast` @ 10.0.0（**2026-09-01 深夜升级**：从 9.1.0 升，dart 侧 `Fluttertoast.showToast` API 未变）
- `package_info_plus` @ 10.2.1（**2026-09-01 深夜新增 SPM**：从 8.0.2 升，跨 2 个主版本，dart 侧 `PackageInfo.fromPlatform` API 未变）
- ~~`path_provider_foundation` @ 2.5.1~~ **2026-09-01 凌晨从 SPM 名单退出**：升到 2.6.0 后改走纯 FFI（`objective_c: ^9.2.1`），podspec + Package.swift 双双移除；`path_provider_foundation` 不再是 plugin，从 SPM 名单退出是**正确行为**，不是回退。用 `dependency_overrides` 显式钉到 2.6.0（因 pub 求解不会主动挑）
- `patrol` @ 4.9.0
- `permission_handler_apple` @ 9.6.1
- `rive_native` @ 0.1.11（**2026-09-01 凌晨新增 SPM**：本轮把 `rive 0.13.13 → 0.14.11`，rive 0.14 起 dart 层全部走 `rive_native`，`rive_common` 从依赖树里彻底移除；`rive_native` 原生带 Package.swift + podspec，Flutter 自动选 SPM）
- `share_plus` @ 13.3.0（**2026-09-01 深夜升级**：从 12.0.1 升，跨主版本 12→13，dart 侧已经用的是 `SharePlus.instance.share(ShareParams(...))` 新 API）
- `shared_preferences_foundation` @ 2.5.7
- `sqflite_darwin` @ 2.4.3+1（2026-09-01 晚间新增：sqflite 2.4.0 起改成 federated plugin）
- `url_launcher_ios` @ 6.4.2
- `webview_flutter_wkwebview` @ 3.26.1
- 加 `FlutterFramework` 本体

## 已知未迁移插件（Pod-only，Flutter 会自动 fallback）

**2026-09-01 凌晨追加大扫除后，Pod-only 插件数：0**。`flutter build ios` 提示：

```
All plugins found for ios are Swift Packages, but your project still has CocoaPods integration.
```

即 **所有第三方插件都是 SPM**。`ios/Podfile.lock` 里只剩 `Flutter` framework 本身：

```
PODS:
  - Flutter (1.0.0)
DEPENDENCIES:
  - Flutter (from `Flutter`)
```

**这就是 2026-12-02 CocoaPods 变只读后依然能编译的完美状态**。Flutter tool 提示的下一步是可选的 `pod deintegrate` + 删除 xcconfig 里的 Pods include，把 CocoaPods 集成层完全清出工程。这一步暂时不做，理由：Flutter framework 本身仍走 Pod、`Podfile` 是 Flutter iOS 项目模板的一部分，保留它更接近官方模板不会让后续 Flutter 升级出岔子。等 Flutter 官方全面转 SPM Flutter framework 后再一并清。

**卡点分类（2026-09-01 凌晨大扫除后更新）**：

| 插件（升级后）  | 状态 | 说明 |
|---|---|---|
| `connectivity_plus 7.3.1` | ✅ 已进 SPM | 从 6.0.5 跨主版本升，dart API 全稳定，本轮验证零回归 |
| `device_info_plus 13.2.0` | ✅ 已进 SPM | 从 10.1.2 跨 3 主版本升，dart API 全稳定，`debug_label.dart` iOS 分支已实测显示 "iPhone 26.2" |
| `package_info_plus 10.2.1` | ✅ 已进 SPM | 从 8.0.2 跨 2 主版本升（win32 5→6 是主要 breaking），dart API 全稳定，`debug_label.dart` 显示 "en 8.0.0" |
| ~~`rive_common 0.4.15`~~ | ✅ **已消灭** | 2026-09-01 凌晨把 `rive: 0.13.13 → 0.14.11`，rive 0.14 起完全迁到 `rive_native`（原生带 SPM），`rive_common` 从依赖树彻底移除。这是唯一走"升级主包换实现"路线，而不是 fork 上游 |
| `rive_native 0.1.11` | ✅ 已进 SPM | 上游 `rive-app/rive-flutter` 官方新架构，同时提供 Package.swift + podspec，Flutter 自动选 SPM |

**上一轮教训（已固化）**：
- 曾以为 `connectivity_plus / device_info_plus / package_info_plus` 是"等上游发新版"，实测上游 SPM 早已就位（`connectivity_plus 6.1.0` 就加了，`device_info_plus 11.1.0` 就加了，`package_info_plus 8.1.0` 就加了）。真实卡点是**跨主版本升级引发的依赖大扫除**（win32 5→6 触发 3 个 Plus 联动 + share_plus 联动 + talker_flutter 联动），必须一次性同步。教训：**版本策略要去 pub 包体解压看 `Package.swift`，不能拿 `flutter pub outdated` 的 "Upgradable" 列糊弄**。
- 曾把 `rive_common` 记成 "上游放弃、pub 已 unlisted，必须 fork 才能上 SPM"，且一度混淆成"要 fork [gitee.com/CarGuo/Flare-Flutter](https://gitee.com/CarGuo/Flare-Flutter.git)"。真实情况：**Flare Flutter 和 rive_common 是两个不同的包**——`flare_flutter` 是 Rive 前身（2020 年 rebrand 前叫 Flare），来自 gitee CarGuo fork；`rive_common` 是 Rive 新架构里的共享层，来自 [rive-app/rive-flutter](https://github.com/rive-app/rive-flutter)，不属于 CarGuo。而且 rive 官方 2025-07 已经用 `rive_native` 替代 `rive_common`（`rive 0.14+` 依赖 `rive_native` 而非 `rive_common`），所以**升 `rive: ^0.14` 是零 fork 成本的干净出路**，只需要迁 dart 层 API。教训：**"上游放弃"的假设要用 pub API 拿 latest 版本 changelog 反证，不能靠记忆**。


## SPM 已迁 13 个插件的版本策略（2026-09-01 深夜大扫除后）

[Package.swift](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift)
里挂着 13 个 SPM 插件。这些插件的版本升级要看**两个约束**同时满足：

1. **SPM 支持起始版本**（有的插件是 beta 才引入 SPM，回 stable 就退回 CocoaPods）
2. **本仓库其他 dart 依赖的版本兼容性**（例如 webview_flutter 4.10 和 flutter_inappwebview 6.2 有兼容坑）

**当前锁定情况**：

| Package.swift 里的包 | 当前版本 | 最新可升 | 决策 | 理由 |
|---|---|---|---|---|
| `connectivity_plus` | 7.3.1 | 已 latest | **本轮新升** | 从 6.0.5 升，dart 侧 `Connectivity()` API 未变；随 win32 5→6 主升级链一并同步 |
| `device_info_plus` | 13.2.0 | 已 latest | **本轮新升** | 从 10.1.2 升，dart 侧 `IosDeviceInfo`/`AndroidDeviceInfo` API 未变 |
| `flutter_inappwebview_ios` | 1.2.0-beta.3 | 1.2.0-beta.3（stable 只有 1.1.2 无 SPM） | **锁死** | stable 版本无 SPM 支持，降级即退回 CocoaPods |
| `fluttertoast` | 10.0.0 | 已 latest | **本轮升级** | 从 9.1.0 升，dart 侧 `Fluttertoast.showToast` API 未变；10.0.0 主要是提升 Flutter 3.44+ / Dart 3.12+ 最低要求，本机满足 |
| `package_info_plus` | 10.2.1 | 已 latest | **本轮新升** | 从 8.0.2 升，dart 侧 `PackageInfo.fromPlatform` API 未变；跨 win32 5→6 主升级 |
| `path_provider_foundation` | 2.6.0（**overridden**）| 已 latest | **本轮凌晨升级到 FFI 化版本** | 2.6.0 官方明说 "replaces plugin-based impl with direct FFI"；主包 `path_provider 2.1.6` 允许 `^2.3.2` 但 pub 求解不会主动挑 2.6.0，用 `dependency_overrides` 显式钉。副作用：`path_provider_foundation` 从 SPM 名单退出（因为它不再是 plugin），需要 `pub_semver 2.1.4 → 2.2.1` 联动升（新版 objective_c 走 hooks 2.0.0，要求 pub_semver ^2.2.0）|
| `patrol` | 4.9.0 | 4.9.0 | **下限已收紧到 ^4.7.0** | dev-only；`patrol 4.6.1` 无 SPM，`4.7.0` 起才有 |
| `permission_handler_apple` | 9.6.1 | 已 latest | 保持 | 主插件 `permission_handler 11.3.1 → 13.0.1` 跨两个主版本，风险大 |
| `rive_native` | 0.1.11 | 已 latest | **本轮凌晨新增** | 由 `rive 0.14.11` 拉入，替代原 `rive_common 0.4.11`；上游 `rive-app/rive-flutter` 提供 Package.swift + podspec，Flutter 自动选 SPM |
| `share_plus` | 13.3.0 | 已 latest | **本轮升级** | 从 12.0.1 升，本仓库 dart 侧已经用的是 `SharePlus.instance.share(ShareParams(...))` 新 API（11.0.0 引入）；13.0.0 breaking 只影响 win32/min-iOS 13/min-Dart 3.11，全部满足 |
| `shared_preferences_foundation` | 2.5.7 | 已 latest | 保持 | dart 侧 shared_preferences 上一轮 2.5.4→2.5.5 打通验证 |
| `sqflite_darwin` | 2.4.3+1 | 已 latest | 2026-09-01 晚间升 | sqflite 2.4.0 起改成 federated plugin |
| `url_launcher_ios` | 6.4.2 | 已 latest | 保持 | 主插件 `url_launcher 6.3.2` 也是当前 latest |
| `webview_flutter_wkwebview` | 3.26.1 | 已 latest | 保持 | `webview_flutter 4.10.0` 和 `flutter_inappwebview 6.2` 有兼容坑（pubspec 注释明示） |

**本轮实际推进**（2026-09-01 深夜）：

1. `connectivity_plus: 6.0.5 → 7.3.1`——首个带 SPM 的版本其实是 6.1.0，本仓库直接跳到最新 7.3.1；win32 5→6 主升级链的一环
2. `device_info_plus: 10.1.2 → 13.2.0`——首个带 SPM 的版本是 11.1.0，直接跳最新
3. `package_info_plus: 8.0.2 → 10.2.1`——首个带 SPM 的版本是 8.1.0，直接跳最新
4. `share_plus: 12.0.1 → 13.3.0`——13.0.0 因 win32 6.0.0 需要主升级；dart 侧无改动
5. `fluttertoast: 9.1.0 → 10.0.0`——只提升 SDK 最低要求
6. `path_provider: 2.1.4 → 2.1.6`——被 `talker_flutter 5.1.19+` 拉动；`path_provider_foundation` 仍锁 2.5.1（SPM 主路径）
7. `talker_flutter: 5.1.9 → 5.1.20` + `talker_dio_logger: 5.1.9 → 5.1.20`——被 `share_plus 13.3.0` 拉动（`talker_flutter 5.1.20` 允许 `share_plus ^13.2.0`）

**本轮凌晨追加推进**（2026-09-01 凌晨，把 pod-only 从 1 打到 0）：

8. `rive: 0.13.13 → 0.14.11`——**核心一击**。rive 0.14 起完全废弃 `rive_common`，把渲染层迁到 `rive_native`（原生带 Package.swift + podspec）。dart API 有 breaking：`RiveAnimation.asset(...)` 被 `RiveWidgetBuilder(fileLoader: FileLoader.fromAsset(...), stateMachineSelector: StateMachineNamed(...), builder: (context, state) => switch(state) { RiveLoading()/RiveFailed()/RiveLoaded(controller: c) => RiveWidget(controller: c) })` 取代；`StateMachineController.fromArtboard(arb, "birb")` 被 `StateMachineSelector` 声明式取代。本仓库唯一使用点在 [welcome_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/welcome_page.dart) 已完成迁移。另外 `main.dart` 必须在 `runApp` 前 `await rive.RiveNative.init()`（否则 native 初始化竞态）
9. `path_provider_foundation: 2.5.1 → 2.6.0`——**FFI 化**。2.6.0 移除了 podspec 和 Package.swift，改用 `objective_c: ^9.2.1` 通过 FFI 直连 Foundation 库，从"iOS plugin"降格成"纯 Dart 包"。pub 求解不会主动挑（因为 `path_provider 2.1.6` 的约束 `^2.3.2` 覆盖 2.6.0 但 solver 保守），用 `dependency_overrides: path_provider_foundation: 2.6.0` 显式钉
10. `pub_semver: 2.1.4 → 2.2.1`——被 #9 拉动。新版 `objective_c 9.4.1` 走 hooks 2.0.0，hooks 2.0.0 要求 `pub_semver ^2.2.0`。API 稳定
11. `main.dart` 加 `WidgetsFlutterBinding.ensureInitialized()` + `await rive.RiveNative.init()`；`welcome_page.dart` 迁移到 `RiveWidgetBuilder` + `StateMachineNamed("birb")` 新 API

**验证证据**（2026-09-01 深夜）：

- `flutter pub get` 干净拉起，14 个依赖变更（另含 `win32 5.15.0 → 6.4.0` / `win32_registry 1.1.5 → 3.0.3` 等 transitive）
- `flutter analyze` 稳定 2 条历史 issue，**零新增**
- `flutter build ios --simulator --no-codesign` 成功（Xcode 45.8s），pod-only warning 从 4 → **1**（**只剩 rive_common**）
- `Package.swift` 从 10 个包扩到 **13 个包**：新增 `connectivity_plus / device_info_plus / package_info_plus`
- iOS 模拟器（iPhone 17 Pro / iOS 26.2）冷启动截图 [/tmp/gsy_spm_smoke_after_3plus.png](file:///tmp/gsy_spm_smoke_after_3plus.png)：启动页正常渲染 GSYGithubApp Logo + "iPhone 26.2 en 8.0.0"（正是 `debug_label.dart` 通过 `DeviceInfoPlugin().iosInfo` + `PackageInfo.fromPlatform()` 拼的字符串），app 未 crash、`log show --last 40s` 无 error/exception/assert/fatal/crash 关键字（排除 UIFocus 已有 warning）

**验证证据**（2026-09-01 凌晨追加）：

- `flutter pub get` 5 个依赖变更：`+ rive_native 0.1.11` / `- rive_common 0.4.11`（"no longer being depended on"）/ `> rive 0.14.11` / `! path_provider_foundation 2.6.0 (overridden)` / `> pub_semver 2.2.1`
- `flutter analyze` 前一版有 2 条 rive API undefined 错误，迁移完 API 后 **回到 2 条历史 issue 稳态，零新增**
- `pod install` 输出："**1 dependency from the Podfile and 1 total pod installed**"；[ios/Podfile.lock](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/ios/Podfile.lock) 只剩 `Flutter (1.0.0)`——**第三方 pod 全清零**
- `flutter build ios --simulator --no-codesign` 成功（Xcode 47.3s），控制台输出 **"All plugins found for ios are Swift Packages"**——这是 Flutter tool 的官方"零 pod plugin"信号
- `Package.swift` 组成质变：`path_provider_foundation` 消失（FFI 化）+ `rive_common` 消失（已废弃）+ `rive_native` 新增，总数 13 保持
- iOS 模拟器（iPhone 17 Pro / iOS 26.2）冷启动 → 欢迎页截图 [/tmp/gsy_rive_014_welcome.png](file:///tmp/gsy_rive_014_welcome.png)：**Rive 蓝色小鸟动画在新 API 下正常渲染**（launch.riv 里 `birb` state machine）；跳转后主页截图 [/tmp/gsy_rive_014_home.png](file:///tmp/gsy_rive_014_home.png)：登录态活着，Dynamic 时间线渲染 CarGuo 真实推送数据；`log show --last 90s --predicate 'process == "Runner"'` 零 error/fatal/crash/rive 关键字（只 UIFocus 已知无害 warning）


## 迁移证据（本轮）

- **build 日志**：`/tmp/gsy_spm_migration.log`
  - 关键行 1：`Xcode is fetching Swift Package Manager dependencies. This may take several minutes...`
  - 关键行 2：`Fetching from https://github.com/apple/swift-collections.git (cached)...`
  - 关键行 3：`Fetching from https://github.com/robbiehanson/CocoaAsyncSocket (cached)...`
  - 关键行 4：`✓ Built build/ios/iphonesimulator/Runner.app`
- **冷启动截图**：`/tmp/gsy_spm_migration_home.png`（iPhone 17 Pro / iOS 26.2 冷启动到登录页，
  无红屏 / crash / assertion；本轮由于 uninstall 时误抹了模拟器本地登录态，
  只到登录页截图为止；主页交互留作已知缺口，见下一节）
- **UIScene 生命周期证据**（同一次 launch 抓的）：
  `xcrun simctl spawn <UDID> log show --last 30s --predicate 'process == "Runner"'`
  能看到大量 `Realizing settings extension ... on FBSSceneSettings`，
  表明 UIScene 主 event loop 完整启动，SPM 引入没有破坏 iOS 生命周期

## 已知缺口

1. ~~**登录后主页 iOS 端未截图**~~ ✅ 2026-09-01 补齐：CarSmallGuo 走 Token Login
   （Personal Access Token 手输）成功进入首页 Dynamic tab，
   证据 [tool/dbg/spm/ios_home_after_token_login.png](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/tool/dbg/spm/ios_home_after_token_login.png)：
   顶部 title `GSYGithubApp` + 右上放大镜、Feed 卡片全部渲染（Push / CreateBranch /
   opened PR / 多条 activities 折叠）、时间戳按 zh locale 走"3 小时前 / 2 小时前"、
   底部 tab `Dynamic / Trend / My`、右下角 `iPhone 26.2 en 8.0.0`。
   Dart 侧 [probe2] 探针 `https://api.github.com/user` 返 200 + 完整 CarSmallGuo JSON，
   Authorization header 正确注入。"主页 → 详情 → 返回"链路 iOS 端仍缺，Android
   端 AGP 9 那轮已覆盖，等下次真机手工点进详情页补即可
2. ~~**4 个 Pod-only 插件**~~ ✅ 2026-09-01 深夜大扫除后降到 **1 个**；**凌晨追加把 rive 升到 0.14.11 + path_provider_foundation FFI 化后降到 0 个**。
   3 个 Plus 系列全部升级到 SPM 版本（`connectivity_plus 6.0.5→7.3.1` / `device_info_plus 10.1.2→13.2.0` / `package_info_plus 8.0.2→10.2.1`），
   顺带 `share_plus 12.0.1→13.3.0` + `fluttertoast 9.1.0→10.0.0` + `talker_flutter 5.1.9→5.1.20` + `path_provider 2.1.4→2.1.6`。
   `rive_common` 通过升 `rive: 0.13.13 → 0.14.11` 从依赖树彻底移除（rive 0.14 走 `rive_native`，原生 SPM），welcome_page 迁移到 `RiveWidgetBuilder` 新 API。
   `path_provider_foundation` 升到 2.6.0 后走 FFI，不再是 plugin，SPM 名单退出。**这一项永久 close**
3. ~~**macOS 端**未验证~~ ✅ 2026-09-01 复核：本仓库根目录**没有 `macos/`**，
   Flutter 只启用 `ios/` 和 `android/`（见仓库根 `LS` 结果）。
   macOS 不是本项目投放平台，SPM 在 macOS 上生效与否无业务意义；此项永久 close
4. ~~**CI 环境的 SPM 缓存策略**未确认~~ ✅ 2026-09-01 复核后 close：
   仓库 CI（[.github/workflows/ci.yml](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/.github/workflows/ci.yml)）
   只跑 `ubuntu-latest` 上的 `flutter build apk`，**根本不跑 iOS build，不触发 SwiftPM 拉包**。
   因此"SPM 缓存优化"这个话题在本仓库 CI 上**不成立**。iOS SPM 主路径的持续验证靠
   本地 author + reviewer 手工 `flutter build ios --simulator --no-codesign`。
   如果未来要在 CI 加 macOS runner 跑 iOS build，再讨论缓存策略也不迟

## 万一要回滚（一般不建议）

官方明确不推荐关掉 SPM。若真的必须临时关：

```bash
# 方式 A（推荐，只影响本地）
fvm flutter config --no-enable-swift-package-manager
# 方式 B（项目级，会影响所有 contributor，慎用）
# 在 pubspec.yaml 里把 flutter.config.enable-swift-package-manager 改成 false
```

Xcode 工程里已经写入的 SwiftPM 引用不会自动清除，
完整回滚步骤见官方文档 "How to remove Swift Package Manager integration"。
