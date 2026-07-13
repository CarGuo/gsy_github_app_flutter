// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_pinned_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 拉取指定用户/组织的 Pinned Repositories 视图模型列表
///
/// - 不加 `dependencies: []` scoped：pinned 数据只在 [PersonPage] 的一个 sliver
///   位置消费，没有必要像 [fetchHonorData] 那样通过 [OnlyShareInstanceWidget]
///   跨节点共享
/// - 用 family 承载 userName：切换到不同用户 profile 时自然生成不同 provider 实例
/// - 失败或空列表都返回空 `[]`，让 UI 侧统一按"无 pinned 隐藏整块"处理，避免
///   为组织类型或未设置 pinned 的用户显示空白标题

@ProviderFor(fetchUserPinnedItems)
final fetchUserPinnedItemsProvider = FetchUserPinnedItemsFamily._();

/// 拉取指定用户/组织的 Pinned Repositories 视图模型列表
///
/// - 不加 `dependencies: []` scoped：pinned 数据只在 [PersonPage] 的一个 sliver
///   位置消费，没有必要像 [fetchHonorData] 那样通过 [OnlyShareInstanceWidget]
///   跨节点共享
/// - 用 family 承载 userName：切换到不同用户 profile 时自然生成不同 provider 实例
/// - 失败或空列表都返回空 `[]`，让 UI 侧统一按"无 pinned 隐藏整块"处理，避免
///   为组织类型或未设置 pinned 的用户显示空白标题

final class FetchUserPinnedItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserPinnedItemViewModel>>,
          List<UserPinnedItemViewModel>,
          FutureOr<List<UserPinnedItemViewModel>>
        >
    with
        $FutureModifier<List<UserPinnedItemViewModel>>,
        $FutureProvider<List<UserPinnedItemViewModel>> {
  /// 拉取指定用户/组织的 Pinned Repositories 视图模型列表
  ///
  /// - 不加 `dependencies: []` scoped：pinned 数据只在 [PersonPage] 的一个 sliver
  ///   位置消费，没有必要像 [fetchHonorData] 那样通过 [OnlyShareInstanceWidget]
  ///   跨节点共享
  /// - 用 family 承载 userName：切换到不同用户 profile 时自然生成不同 provider 实例
  /// - 失败或空列表都返回空 `[]`，让 UI 侧统一按"无 pinned 隐藏整块"处理，避免
  ///   为组织类型或未设置 pinned 的用户显示空白标题
  FetchUserPinnedItemsProvider._({
    required FetchUserPinnedItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserPinnedItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserPinnedItemsHash();

  @override
  String toString() {
    return r'fetchUserPinnedItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UserPinnedItemViewModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserPinnedItemViewModel>> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserPinnedItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserPinnedItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserPinnedItemsHash() =>
    r'027919b9e0d11a577aad9cf23910ed9c03b9ec51';

/// 拉取指定用户/组织的 Pinned Repositories 视图模型列表
///
/// - 不加 `dependencies: []` scoped：pinned 数据只在 [PersonPage] 的一个 sliver
///   位置消费，没有必要像 [fetchHonorData] 那样通过 [OnlyShareInstanceWidget]
///   跨节点共享
/// - 用 family 承载 userName：切换到不同用户 profile 时自然生成不同 provider 实例
/// - 失败或空列表都返回空 `[]`，让 UI 侧统一按"无 pinned 隐藏整块"处理，避免
///   为组织类型或未设置 pinned 的用户显示空白标题

final class FetchUserPinnedItemsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<UserPinnedItemViewModel>>,
          String
        > {
  FetchUserPinnedItemsFamily._()
    : super(
        retry: null,
        name: r'fetchUserPinnedItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 拉取指定用户/组织的 Pinned Repositories 视图模型列表
  ///
  /// - 不加 `dependencies: []` scoped：pinned 数据只在 [PersonPage] 的一个 sliver
  ///   位置消费，没有必要像 [fetchHonorData] 那样通过 [OnlyShareInstanceWidget]
  ///   跨节点共享
  /// - 用 family 承载 userName：切换到不同用户 profile 时自然生成不同 provider 实例
  /// - 失败或空列表都返回空 `[]`，让 UI 侧统一按"无 pinned 隐藏整块"处理，避免
  ///   为组织类型或未设置 pinned 的用户显示空白标题

  FetchUserPinnedItemsProvider call(String userName) =>
      FetchUserPinnedItemsProvider._(argument: userName, from: this);

  @override
  String toString() => r'fetchUserPinnedItemsProvider';
}
