// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 拉取指定用户的 status
///
/// - 与 [fetchUserPinnedItems] 同构：plain `@riverpod` + family + autoDispose，
///   不加 `dependencies: []` scoped，因为 status 只在 [PersonPage] 消费一次
/// - 失败或空 status 都返回 `null`；UI 侧统一按"隐藏整块"处理，避免为组织类型
///   或未设置 status 的用户显示空白 chip
/// - **不加 organization 短路**：调用侧 [BasePersonState] 已按 `userInfo.login`
///   非空条件挂载，若真是 organization 请求返回 null 会由本 provider 兜底成
///   `null`，UI 隐藏，无副作用

@ProviderFor(fetchUserStatus)
final fetchUserStatusProvider = FetchUserStatusFamily._();

/// 拉取指定用户的 status
///
/// - 与 [fetchUserPinnedItems] 同构：plain `@riverpod` + family + autoDispose，
///   不加 `dependencies: []` scoped，因为 status 只在 [PersonPage] 消费一次
/// - 失败或空 status 都返回 `null`；UI 侧统一按"隐藏整块"处理，避免为组织类型
///   或未设置 status 的用户显示空白 chip
/// - **不加 organization 短路**：调用侧 [BasePersonState] 已按 `userInfo.login`
///   非空条件挂载，若真是 organization 请求返回 null 会由本 provider 兜底成
///   `null`，UI 隐藏，无副作用

final class FetchUserStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserStatusViewModel?>,
          UserStatusViewModel?,
          FutureOr<UserStatusViewModel?>
        >
    with
        $FutureModifier<UserStatusViewModel?>,
        $FutureProvider<UserStatusViewModel?> {
  /// 拉取指定用户的 status
  ///
  /// - 与 [fetchUserPinnedItems] 同构：plain `@riverpod` + family + autoDispose，
  ///   不加 `dependencies: []` scoped，因为 status 只在 [PersonPage] 消费一次
  /// - 失败或空 status 都返回 `null`；UI 侧统一按"隐藏整块"处理，避免为组织类型
  ///   或未设置 status 的用户显示空白 chip
  /// - **不加 organization 短路**：调用侧 [BasePersonState] 已按 `userInfo.login`
  ///   非空条件挂载，若真是 organization 请求返回 null 会由本 provider 兜底成
  ///   `null`，UI 隐藏，无副作用
  FetchUserStatusProvider._({
    required FetchUserStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserStatusHash();

  @override
  String toString() {
    return r'fetchUserStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserStatusViewModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserStatusViewModel?> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserStatusHash() => r'e3559be6ade8a735a5c46ce086ba2878f25bf476';

/// 拉取指定用户的 status
///
/// - 与 [fetchUserPinnedItems] 同构：plain `@riverpod` + family + autoDispose，
///   不加 `dependencies: []` scoped，因为 status 只在 [PersonPage] 消费一次
/// - 失败或空 status 都返回 `null`；UI 侧统一按"隐藏整块"处理，避免为组织类型
///   或未设置 status 的用户显示空白 chip
/// - **不加 organization 短路**：调用侧 [BasePersonState] 已按 `userInfo.login`
///   非空条件挂载，若真是 organization 请求返回 null 会由本 provider 兜底成
///   `null`，UI 隐藏，无副作用

final class FetchUserStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserStatusViewModel?>, String> {
  FetchUserStatusFamily._()
    : super(
        retry: null,
        name: r'fetchUserStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 拉取指定用户的 status
  ///
  /// - 与 [fetchUserPinnedItems] 同构：plain `@riverpod` + family + autoDispose，
  ///   不加 `dependencies: []` scoped，因为 status 只在 [PersonPage] 消费一次
  /// - 失败或空 status 都返回 `null`；UI 侧统一按"隐藏整块"处理，避免为组织类型
  ///   或未设置 status 的用户显示空白 chip
  /// - **不加 organization 短路**：调用侧 [BasePersonState] 已按 `userInfo.login`
  ///   非空条件挂载，若真是 organization 请求返回 null 会由本 provider 兜底成
  ///   `null`，UI 隐藏，无副作用

  FetchUserStatusProvider call(String userName) =>
      FetchUserStatusProvider._(argument: userName, from: this);

  @override
  String toString() => r'fetchUserStatusProvider';
}
