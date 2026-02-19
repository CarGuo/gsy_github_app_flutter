// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppVibrationState)
const appVibrationStateProvider = AppVibrationStateProvider._();

final class AppVibrationStateProvider
    extends $NotifierProvider<AppVibrationState, bool> {
  const AppVibrationStateProvider._()
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

String _$appVibrationStateHash() => r'85e7e422a4e3b34dfe1e67f7aa562cf40340fa69';

abstract class _$AppVibrationState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 控制 App 灰度效果

@ProviderFor(AppGrepState)
const appGrepStateProvider = AppGrepStateProvider._();

/// 控制 App 灰度效果
final class AppGrepStateProvider extends $NotifierProvider<AppGrepState, bool> {
  /// 控制 App 灰度效果
  const AppGrepStateProvider._()
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
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 控制 App 语言

@ProviderFor(AppLocalState)
const appLocalStateProvider = AppLocalStateProvider._();

/// 控制 App 语言
final class AppLocalStateProvider
    extends $NotifierProvider<AppLocalState, Locale> {
  /// 控制 App 语言
  const AppLocalStateProvider._()
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
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 控制 App 主题

@ProviderFor(AppThemeState)
const appThemeStateProvider = AppThemeStateProvider._();

/// 控制 App 主题
final class AppThemeStateProvider
    extends $NotifierProvider<AppThemeState, ThemeData> {
  /// 控制 App 主题
  const AppThemeStateProvider._()
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
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ThemeData, ThemeData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeData, ThemeData>,
              ThemeData,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
