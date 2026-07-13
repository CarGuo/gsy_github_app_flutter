// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sponsors_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 拉取指定用户 / 组织的 sponsors
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] 同构：plain `@riverpod` +
///   family + autoDispose，不加 `dependencies: []` scoped，因为 sponsors 只在
///   [PersonPage] 消费一次
/// - 失败或未启用 Sponsors 都返回 `UserSponsorsViewModel()` 空态（totalCount=0）；
///   UI 侧按整块 [SizedBox.shrink] 处理
/// - 不做 organization 短路：GraphQL 的 `user(login:)` 命中 Org 也能拿 sponsors
///   字段（Sponsors 面向 Org 开放），若 login 无效兜底成空态

@ProviderFor(fetchUserSponsors)
final fetchUserSponsorsProvider = FetchUserSponsorsFamily._();

/// 拉取指定用户 / 组织的 sponsors
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] 同构：plain `@riverpod` +
///   family + autoDispose，不加 `dependencies: []` scoped，因为 sponsors 只在
///   [PersonPage] 消费一次
/// - 失败或未启用 Sponsors 都返回 `UserSponsorsViewModel()` 空态（totalCount=0）；
///   UI 侧按整块 [SizedBox.shrink] 处理
/// - 不做 organization 短路：GraphQL 的 `user(login:)` 命中 Org 也能拿 sponsors
///   字段（Sponsors 面向 Org 开放），若 login 无效兜底成空态

final class FetchUserSponsorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserSponsorsViewModel>,
          UserSponsorsViewModel,
          FutureOr<UserSponsorsViewModel>
        >
    with
        $FutureModifier<UserSponsorsViewModel>,
        $FutureProvider<UserSponsorsViewModel> {
  /// 拉取指定用户 / 组织的 sponsors
  ///
  /// - 与 [fetchUserPinnedItems] / [fetchUserStatus] 同构：plain `@riverpod` +
  ///   family + autoDispose，不加 `dependencies: []` scoped，因为 sponsors 只在
  ///   [PersonPage] 消费一次
  /// - 失败或未启用 Sponsors 都返回 `UserSponsorsViewModel()` 空态（totalCount=0）；
  ///   UI 侧按整块 [SizedBox.shrink] 处理
  /// - 不做 organization 短路：GraphQL 的 `user(login:)` 命中 Org 也能拿 sponsors
  ///   字段（Sponsors 面向 Org 开放），若 login 无效兜底成空态
  FetchUserSponsorsProvider._({
    required FetchUserSponsorsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserSponsorsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserSponsorsHash();

  @override
  String toString() {
    return r'fetchUserSponsorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserSponsorsViewModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserSponsorsViewModel> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserSponsors(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserSponsorsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserSponsorsHash() => r'52d851cb56c5039bde42dd4123a5d0f583bddefc';

/// 拉取指定用户 / 组织的 sponsors
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] 同构：plain `@riverpod` +
///   family + autoDispose，不加 `dependencies: []` scoped，因为 sponsors 只在
///   [PersonPage] 消费一次
/// - 失败或未启用 Sponsors 都返回 `UserSponsorsViewModel()` 空态（totalCount=0）；
///   UI 侧按整块 [SizedBox.shrink] 处理
/// - 不做 organization 短路：GraphQL 的 `user(login:)` 命中 Org 也能拿 sponsors
///   字段（Sponsors 面向 Org 开放），若 login 无效兜底成空态

final class FetchUserSponsorsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserSponsorsViewModel>, String> {
  FetchUserSponsorsFamily._()
    : super(
        retry: null,
        name: r'fetchUserSponsorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 拉取指定用户 / 组织的 sponsors
  ///
  /// - 与 [fetchUserPinnedItems] / [fetchUserStatus] 同构：plain `@riverpod` +
  ///   family + autoDispose，不加 `dependencies: []` scoped，因为 sponsors 只在
  ///   [PersonPage] 消费一次
  /// - 失败或未启用 Sponsors 都返回 `UserSponsorsViewModel()` 空态（totalCount=0）；
  ///   UI 侧按整块 [SizedBox.shrink] 处理
  /// - 不做 organization 短路：GraphQL 的 `user(login:)` 命中 Org 也能拿 sponsors
  ///   字段（Sponsors 面向 Org 开放），若 login 无效兜底成空态

  FetchUserSponsorsProvider call(String userName) =>
      FetchUserSponsorsProvider._(argument: userName, from: this);

  @override
  String toString() => r'fetchUserSponsorsProvider';
}
