# 本地开发环境

## 基线要求

- Flutter SDK：**3.44.1 stable**（仓库根 [`.fvmrc`](file:///d:/workspace/project/gsy_github_app_flutter/.fvmrc) 已锁定；CI 的 `subosito/flutter-action@v2` 通过 `flutter-version-file: .fvmrc` 读同一份契约，避免本地 / CI 版本漂移）
- 推荐使用 [FVM](https://fvm.app/) 管理版本：`fvm install 3.44.1 && fvm use 3.44.1`
- Java：Android 构建需要
- Android 工具链：生成 APK 需要

## 首次启动

1. 安装 Flutter（或 `fvm install 3.44.1`），并确认 `flutter doctor`
2. 运行 `flutter pub get`
3. 创建 `lib/common/config/ignoreConfig.dart`
4. 填入 GitHub OAuth 所需的 `CLIENT_ID` 和 `CLIENT_SECRET`

示例：

```dart
class NetConfig {
  static const CLIENT_ID = "xxxx";
  static const CLIENT_SECRET = "xxxx";
}
```

## 常用命令

```bash
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release --target-platform=android-arm64 --no-shrink
```

## 什么时候需要重新生成

- 改模型、序列化、Riverpod 注解或 env 源文件时，跑 `build_runner`
- 改 ARB 多语言文件时，重新生成本地化输出

## 常见失败原因

- 缺少 `ignoreConfig.dart`
- Flutter 版本不匹配（本地未按 [`.fvmrc`](file:///d:/workspace/project/gsy_github_app_flutter/.fvmrc) 切到 3.44.1，可能撞到 `SizeTransition.alignment` 之类 3.41 之后引入的新 API）
- 拉包时网络或代理异常
- 手改生成文件但没同步源文件

## 当前本地验证策略

仓库目前没有提交进来的自动化测试目录，因此本地验证以静态检查、构建和手工冒烟为主：

- 跑 `flutter analyze`
- 对构建相关改动跑 APK 构建
- 在模拟器或真机上手工验证改动功能
