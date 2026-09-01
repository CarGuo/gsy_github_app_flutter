# iOS Swift Package Manager 迁移操作手册

本文档记录本仓库从 CocoaPods 主路径切换到 Swift Package Manager（SPM）主路径的完整过程、
关键决策、验证锚点和已知缺口，方便未来任何 contributor（人或 agent）复核或推动下一步。

- 最后一次操作时间：2026-09-01
- 操作时 Flutter 版本：3.47.2 stable（Dart 3.13.2）
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

本轮验证时 `Package.swift` 里挂到了这 9 个插件：

- `flutter_inappwebview_ios` @ 1.2.0-beta.3
- `fluttertoast` @ 9.1.0
- `path_provider_foundation` @ 2.5.1
- `patrol` @ 4.9.0
- `permission_handler_apple` @ 9.6.1
- `share_plus` @ 12.0.1
- `shared_preferences_foundation` @ 2.5.7
- `url_launcher_ios` @ 6.4.2
- `webview_flutter_wkwebview` @ 3.26.1
- 加 `FlutterFramework` 本体

## 已知未迁移插件（Pod-only，Flutter 会自动 fallback）

以下 5 个插件目前仍走 CocoaPods，`flutter build ios` 会输出提示：

```
The following plugins do not support Swift Package Manager for ios:
  - connectivity_plus
  - device_info_plus
  - package_info_plus
  - rive_common
  - sqflite
```

处理原则：

- **不主动 fork 这些插件去改**——属于上游作者的迁移进度，
  强行 fork 会引入长期维护负担，跟 AGENTS.md "改动限制在当前功能域" 相冲突
- 每季度用 `flutter pub outdated` 复查一次，一旦上游发新版就顺手升
- CocoaPods registry 2026-12 变只读那天之前必须清零；如果到 2026-11 上游还没跟上，
  再评估临时策略（依赖 override 到已 fork 版本 / 换等价插件）

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

1. **登录后主页 iOS 端未截图**：uninstall 时抹了本地登录，未能覆盖"主页 → 详情 → 返回"链路。
   Android 端 CarSmallGuo 已完成 AGP 9 迁移那一轮的主页冒烟；iOS 端等下次真机登录后补
2. **5 个 Pod-only 插件**（见上）跟随上游发新版
3. **macOS 端**未验证；本仓库主投放平台是 iOS + Android，macOS 属于附带能力
4. **CI 环境的 SPM 缓存策略**未确认——CI runner 每次拉 swift-collections 会拖慢冷 build，
   后续用 `~/Library/Caches/org.swift.swiftpm` 或 `~/Library/Developer/Xcode/DerivedData`
   加入 GitHub Actions cache 有优化空间

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
