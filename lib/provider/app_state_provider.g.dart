// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppVibrationState)
final appVibrationStateProvider = AppVibrationStateProvider._();

final class AppVibrationStateProvider
    extends $NotifierProvider<AppVibrationState, bool> {
  AppVibrationStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVibrationStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVibrationStateHash();

  @$internal
  @override
  AppVibrationState create() => AppVibrationState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appVibrationStateHash() => r'6f7aef6fcacc6947610cf9a8f50d0c3a3449c7e2';

abstract class _$AppVibrationState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 大屏用户偏好：强制走全屏 detail（关闭 Master-Detail 双栏）。
///
/// - 存储：[Config.FORCE_FULL_SCREEN_DETAIL] 走 [LocalStorage]（SharedPreferences）
///   以 "true" / "false" 字符串保存，模式与 [AppVibrationState] 一致。
/// - 启动回填：`UserRepository.initUserInfo` 里读一次 SharedPreferences 并
///   调用 `change(..., save: false)` 塞到 provider；
/// - 镜像到 delegate：每次 `change()` 都同步调用
///   `GSYAdaptiveNavigation.instance.setForceFullScreenDetail(...)`，让
///   非 Riverpod 消费点（`event_utils.dart` / delegate 内部 canShowTwoPane）
///   也能读到最新值 —— 而不是让 delegate 反向依赖 Riverpod ref。

@ProviderFor(AppForceFullScreenDetailState)
final appForceFullScreenDetailStateProvider =
    AppForceFullScreenDetailStateProvider._();

/// 大屏用户偏好：强制走全屏 detail（关闭 Master-Detail 双栏）。
///
/// - 存储：[Config.FORCE_FULL_SCREEN_DETAIL] 走 [LocalStorage]（SharedPreferences）
///   以 "true" / "false" 字符串保存，模式与 [AppVibrationState] 一致。
/// - 启动回填：`UserRepository.initUserInfo` 里读一次 SharedPreferences 并
///   调用 `change(..., save: false)` 塞到 provider；
/// - 镜像到 delegate：每次 `change()` 都同步调用
///   `GSYAdaptiveNavigation.instance.setForceFullScreenDetail(...)`，让
///   非 Riverpod 消费点（`event_utils.dart` / delegate 内部 canShowTwoPane）
///   也能读到最新值 —— 而不是让 delegate 反向依赖 Riverpod ref。
final class AppForceFullScreenDetailStateProvider
    extends $NotifierProvider<AppForceFullScreenDetailState, bool> {
  /// 大屏用户偏好：强制走全屏 detail（关闭 Master-Detail 双栏）。
  ///
  /// - 存储：[Config.FORCE_FULL_SCREEN_DETAIL] 走 [LocalStorage]（SharedPreferences）
  ///   以 "true" / "false" 字符串保存，模式与 [AppVibrationState] 一致。
  /// - 启动回填：`UserRepository.initUserInfo` 里读一次 SharedPreferences 并
  ///   调用 `change(..., save: false)` 塞到 provider；
  /// - 镜像到 delegate：每次 `change()` 都同步调用
  ///   `GSYAdaptiveNavigation.instance.setForceFullScreenDetail(...)`，让
  ///   非 Riverpod 消费点（`event_utils.dart` / delegate 内部 canShowTwoPane）
  ///   也能读到最新值 —— 而不是让 delegate 反向依赖 Riverpod ref。
  AppForceFullScreenDetailStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appForceFullScreenDetailStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appForceFullScreenDetailStateHash();

  @$internal
  @override
  AppForceFullScreenDetailState create() => AppForceFullScreenDetailState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appForceFullScreenDetailStateHash() =>
    r'c954809de914b1588fbf498a73721e894cfa8bf4';

/// 大屏用户偏好：强制走全屏 detail（关闭 Master-Detail 双栏）。
///
/// - 存储：[Config.FORCE_FULL_SCREEN_DETAIL] 走 [LocalStorage]（SharedPreferences）
///   以 "true" / "false" 字符串保存，模式与 [AppVibrationState] 一致。
/// - 启动回填：`UserRepository.initUserInfo` 里读一次 SharedPreferences 并
///   调用 `change(..., save: false)` 塞到 provider；
/// - 镜像到 delegate：每次 `change()` 都同步调用
///   `GSYAdaptiveNavigation.instance.setForceFullScreenDetail(...)`，让
///   非 Riverpod 消费点（`event_utils.dart` / delegate 内部 canShowTwoPane）
///   也能读到最新值 —— 而不是让 delegate 反向依赖 Riverpod ref。

abstract class _$AppForceFullScreenDetailState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 控制 App 灰度效果

@ProviderFor(AppGrepState)
final appGrepStateProvider = AppGrepStateProvider._();

/// 控制 App 灰度效果
final class AppGrepStateProvider extends $NotifierProvider<AppGrepState, bool> {
  /// 控制 App 灰度效果
  AppGrepStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appGrepStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appGrepStateHash();

  @$internal
  @override
  AppGrepState create() => AppGrepState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appGrepStateHash() => r'2d597c1ee2158b81668c77d0c4c4773dae175e41';

/// 控制 App 灰度效果

abstract class _$AppGrepState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 控制 App 语言

@ProviderFor(AppLocalState)
final appLocalStateProvider = AppLocalStateProvider._();

/// 控制 App 语言
final class AppLocalStateProvider
    extends $NotifierProvider<AppLocalState, Locale> {
  /// 控制 App 语言
  AppLocalStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocalStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocalStateHash();

  @$internal
  @override
  AppLocalState create() => AppLocalState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocalStateHash() => r'094022d96deb55273c2bc53466ad2bf5ee8bdce0';

/// 控制 App 语言

abstract class _$AppLocalState extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 控制 App 主题

@ProviderFor(AppThemeState)
final appThemeStateProvider = AppThemeStateProvider._();

/// 控制 App 主题
final class AppThemeStateProvider
    extends $NotifierProvider<AppThemeState, ThemeData> {
  /// 控制 App 主题
  AppThemeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeStateHash();

  @$internal
  @override
  AppThemeState create() => AppThemeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeData>(value),
    );
  }
}

String _$appThemeStateHash() => r'a02ca99fb2b47827f007b77c8d1d371cb171b17e';

/// 控制 App 主题

abstract class _$AppThemeState extends $Notifier<ThemeData> {
  ThemeData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeData, ThemeData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeData, ThemeData>,
              ThemeData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
