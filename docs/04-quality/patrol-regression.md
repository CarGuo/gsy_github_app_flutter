# Patrol 回归测试

## 目标

Patrol 回归测试把 `docs/04-quality/smoke-matrix.md` 中最稳定、最适合自动化的主链路固化下来。
当前优先覆盖：

- 未登录冷启动到登录页
- 登录页基础输入区域
- OAuth WebView 入口
- 已登录壳层首页
- 首页 Dynamic / Trend Tab
- Drawer 中主题、语言、灰度、退出登录

## 本地准备

```bash
flutter pub get
flutter pub global activate patrol_cli
patrol doctor
```

Android 优先。iOS 真机执行需要 `ideviceinstaller`，可按 `patrol doctor` 的提示安装。

如需覆盖真实登录态网络路径，可在本地忽略文件 `env.local` 中放一行 GitHub token。
测试不会提交该文件，运行时通过 `PATROL_GITHUB_TOKEN` 注入。
注意：`--dart-define` 会写入本地 Flutter/Xcode 生成配置，相关生成目录已被忽略；运行后不要提交 `ios/Flutter/Generated.xcconfig`、`ios/Flutter/ephemeral/` 或 `build/`。

```bash
TOKEN="$(tr -d '\r\n' < env.local)"
patrol test \
  -t patrol_test/app_regression_test.dart \
  --dart-define PATROL_GITHUB_TOKEN="$TOKEN" \
  --show-flutter-logs
```

## 运行

```bash
patrol test -t patrol_test/app_regression_test.dart --show-flutter-logs
```

如果同时连了多个设备，请显式指定设备：

```bash
patrol test -d <device-id> -t patrol_test/app_regression_test.dart --show-flutter-logs
```

在内存压力较高的 macOS 环境下，Patrol CLI 默认触发的 Xcode 并发构建可能会在 CocoaPods 资源或 framework 拷贝阶段被系统 `Killed: 9`。
这种情况下可先让 Patrol/Flutter 生成测试 bundle 与 iOS 配置，再用 `xcodebuild -jobs 1` 低并发构建并执行：

```bash
if [ -f env.local ]; then
  TOKEN="$(tr -d '\r\n' < env.local)"
  TOKEN_DEFINE=(--dart-define PATROL_GITHUB_TOKEN="$TOKEN")
else
  TOKEN_DEFINE=()
fi
PATROL_DEFINES=(
  --dart-define PATROL_APP_PACKAGE_NAME=com.shuyu.gsygithub.gsygithubappflutter
  --dart-define PATROL_APP_BUNDLE_ID=com.shuyu.GSYGithubAppBundle
  --dart-define PATROL_ANDROID_APP_NAME=GSYGithubApp
  --dart-define PATROL_IOS_APP_NAME=GSYGithubApp
  --dart-define PATROL_MACOS_APP_NAME=GSYGithubApp
  --dart-define INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false
  --dart-define PATROL_TEST_LABEL_ENABLED=true
  --dart-define PATROL_TEST_DIRECTORY=patrol_test
  --dart-define PATROL_TEST_SERVER_PORT=8081
  --dart-define PATROL_APP_SERVER_PORT=8082
  --dart-define COVERAGE_ENABLED=false
)

flutter build ios \
  --config-only \
  --no-codesign \
  --debug \
  --simulator \
  --target patrol_test/test_bundle.dart \
  "${PATROL_DEFINES[@]}" \
  "${TOKEN_DEFINE[@]}"

cd ios
FLUTTER_ROOT="$(flutter --version --machine | ruby -rjson -e 'print JSON.parse(STDIN.read)["flutterRoot"]')" \
xcodebuild build-for-testing \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ../build/ios_integ \
  -jobs 1 \
  'OTHER_SWIFT_FLAGS=$(inherited) -D PATROL_ENABLED' \
  'OTHER_CFLAGS=$(inherited) -D FULL_ISOLATION=0 -D CLEAR_PERMISSIONS=0'
cd ..

xcodebuild test-without-building \
  -xctestrun build/ios_integ/Build/Products/Runner_iphonesimulator*.xctestrun \
  -destination 'id=<simulator-device-id>' \
  -resultBundlePath build/ios_results_manual.xcresult
```

## 说明

测试不会把真实 GitHub token 写入仓库，也不会依赖本地 `ignoreConfig.dart` 里的密钥完成 OAuth。
未提供 `PATROL_GITHUB_TOKEN` 时，已登录壳层会用本地 SharedPreferences fixture 进入首页，用来验证导航、Tab、Drawer 和全局设置类交互。

通知、私有仓库、真实 OAuth 完整闭环需要人工提供测试账号或临时 token 后再扩展专用用例。
