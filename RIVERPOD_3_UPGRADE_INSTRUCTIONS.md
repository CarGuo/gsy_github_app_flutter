# Riverpod 3.0 升级说明 / Riverpod 3.0 Upgrade Instructions

## 🇨🇳 中文说明

### 已完成的更改
1. **更新了 pubspec.yaml 中的依赖版本:**
   - `flutter_riverpod: ^3.0.0` (从 2.6.1 升级)
   - `riverpod_annotation: ^3.0.0` (从 2.6.1 升级) 
   - `riverpod_generator: ^3.0.0` (从 2.6.1 升级)

### 必须执行的下一步

拉取这些更改后，**必须**运行以下命令来重新生成 `.g.dart` 文件：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 兼容性确认

✅ **无需修改源代码！** 项目已经遵循了 Riverpod 3.0 最佳实践：
- 使用正确的 `Ref` 接口（而非已弃用的 mixin）
- 使用 `Consumer`/`ConsumerStatefulWidget`（仍受支持）
- 使用 `WidgetRef`（仍受支持）
- 正确使用 `@riverpod` 注解
- UncontrolledProviderScope 配置兼容

---

## 🇺🇸 English Instructions

### Changes Completed
1. **Updated pubspec.yaml dependencies:**
   - `flutter_riverpod: ^3.0.0` (from 2.6.1)
   - `riverpod_annotation: ^3.0.0` (from 2.6.1) 
   - `riverpod_generator: ^3.0.0` (from 2.6.1)

### Required Next Steps

After pulling these changes, you **MUST** run the following command to regenerate the `.g.dart` files:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Compatibility Verified

✅ **No source code changes needed!** The project was already following Riverpod 3.0 best practices:
- Using `Ref` interface (not deprecated mixins)
- Using `Consumer`/`ConsumerStatefulWidget` (still supported)
- Using `WidgetRef` in builders (still supported)  
- Using `@riverpod` annotations correctly
- UncontrolledProviderScope setup is compatible

### Verification Steps

After running build_runner, verify the app still works:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Riverpod 3.0 主要变化 / Key Changes

- 弃用的 mixin 接口如 `SearchTrendUserRequestRef` 被统一的 `Ref` 替代
- 生成的代码已更新以移除弃用的模式  
- Consumer 组件和 WidgetRef 使用无破坏性更改

### 删除此文件 / Remove This File

升级完成并验证无误后，可以删除此说明文件。
After upgrade completion and verification, this instruction file can be deleted.