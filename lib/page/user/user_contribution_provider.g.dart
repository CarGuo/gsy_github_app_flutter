// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_contribution_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 拉取指定用户的贡献日历（近 12 个月）
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] / [fetchUserSponsors]
///   同构：plain `@riverpod` + family + autoDispose，只在 [PersonPage]
///   消费一次
/// - 失败 / 空态都返回 [UserContributionCalendarViewModel] 空态；
///   UI 侧按占位 SizedBox 处理
/// - Organization 已在页面层短路，不会走到这里；若未来短路被拿掉，
///   repository 兜底会返回空 weeks，行为仍安全

@ProviderFor(fetchUserContributionCalendar)
final fetchUserContributionCalendarProvider =
    FetchUserContributionCalendarFamily._();

/// 拉取指定用户的贡献日历（近 12 个月）
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] / [fetchUserSponsors]
///   同构：plain `@riverpod` + family + autoDispose，只在 [PersonPage]
///   消费一次
/// - 失败 / 空态都返回 [UserContributionCalendarViewModel] 空态；
///   UI 侧按占位 SizedBox 处理
/// - Organization 已在页面层短路，不会走到这里；若未来短路被拿掉，
///   repository 兜底会返回空 weeks，行为仍安全

final class FetchUserContributionCalendarProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserContributionCalendarViewModel>,
          UserContributionCalendarViewModel,
          FutureOr<UserContributionCalendarViewModel>
        >
    with
        $FutureModifier<UserContributionCalendarViewModel>,
        $FutureProvider<UserContributionCalendarViewModel> {
  /// 拉取指定用户的贡献日历（近 12 个月）
  ///
  /// - 与 [fetchUserPinnedItems] / [fetchUserStatus] / [fetchUserSponsors]
  ///   同构：plain `@riverpod` + family + autoDispose，只在 [PersonPage]
  ///   消费一次
  /// - 失败 / 空态都返回 [UserContributionCalendarViewModel] 空态；
  ///   UI 侧按占位 SizedBox 处理
  /// - Organization 已在页面层短路，不会走到这里；若未来短路被拿掉，
  ///   repository 兜底会返回空 weeks，行为仍安全
  FetchUserContributionCalendarProvider._({
    required FetchUserContributionCalendarFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserContributionCalendarProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserContributionCalendarHash();

  @override
  String toString() {
    return r'fetchUserContributionCalendarProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserContributionCalendarViewModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserContributionCalendarViewModel> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserContributionCalendar(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserContributionCalendarProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserContributionCalendarHash() =>
    r'6c9106de4d7fa681f934cc84eabd83e26f3a988d';

/// 拉取指定用户的贡献日历（近 12 个月）
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] / [fetchUserSponsors]
///   同构：plain `@riverpod` + family + autoDispose，只在 [PersonPage]
///   消费一次
/// - 失败 / 空态都返回 [UserContributionCalendarViewModel] 空态；
///   UI 侧按占位 SizedBox 处理
/// - Organization 已在页面层短路，不会走到这里；若未来短路被拿掉，
///   repository 兜底会返回空 weeks，行为仍安全

final class FetchUserContributionCalendarFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<UserContributionCalendarViewModel>,
          String
        > {
  FetchUserContributionCalendarFamily._()
    : super(
        retry: null,
        name: r'fetchUserContributionCalendarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 拉取指定用户的贡献日历（近 12 个月）
  ///
  /// - 与 [fetchUserPinnedItems] / [fetchUserStatus] / [fetchUserSponsors]
  ///   同构：plain `@riverpod` + family + autoDispose，只在 [PersonPage]
  ///   消费一次
  /// - 失败 / 空态都返回 [UserContributionCalendarViewModel] 空态；
  ///   UI 侧按占位 SizedBox 处理
  /// - Organization 已在页面层短路，不会走到这里；若未来短路被拿掉，
  ///   repository 兜底会返回空 weeks，行为仍安全

  FetchUserContributionCalendarProvider call(String userName) =>
      FetchUserContributionCalendarProvider._(argument: userName, from: this);

  @override
  String toString() => r'fetchUserContributionCalendarProvider';
}
