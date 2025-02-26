// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appGrepStateHash() => r'2d597c1ee2158b81668c77d0c4c4773dae175e41';

/// 控制 App 灰度效果
///
/// Copied from [AppGrepState].
@ProviderFor(AppGrepState)
final appGrepStateProvider =
    AutoDisposeNotifierProvider<AppGrepState, bool>.internal(
  AppGrepState.new,
  name: r'appGrepStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appGrepStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppGrepState = AutoDisposeNotifier<bool>;
String _$appLocalStateHash() => r'ec1b33dd1dd98ea2501abeb46e8c36b38e0801e4';

/// 控制 App 语言
///
/// Copied from [AppLocalState].
@ProviderFor(AppLocalState)
final appLocalStateProvider =
    AutoDisposeNotifierProvider<AppLocalState, Locale>.internal(
  AppLocalState.new,
  name: r'appLocalStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appLocalStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppLocalState = AutoDisposeNotifier<Locale>;
String _$appThemeStateHash() => r'fcb0530ded04fc2815b542312964d16558fe9cc9';

/// 控制 App 主题
///
/// Copied from [AppThemeState].
@ProviderFor(AppThemeState)
final appThemeStateProvider =
    AutoDisposeNotifierProvider<AppThemeState, ThemeData>.internal(
  AppThemeState.new,
  name: r'appThemeStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appThemeStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppThemeState = AutoDisposeNotifier<ThemeData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
