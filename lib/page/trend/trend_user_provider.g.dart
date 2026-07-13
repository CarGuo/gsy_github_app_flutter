// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
///无需释放，这样内存里就会保存着列表，下次进来不会空数据

@ProviderFor(TrendCNUserList)
final trendCNUserListProvider = TrendCNUserListProvider._();

///无需释放，这样内存里就会保存着列表，下次进来不会空数据
final class TrendCNUserListProvider
    extends $NotifierProvider<TrendCNUserList, List<SearchUserQL>> {
  ///无需释放，这样内存里就会保存着列表，下次进来不会空数据
  TrendCNUserListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendCNUserListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendCNUserListHash();

  @$internal
  @override
  TrendCNUserList create() => TrendCNUserList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchUserQL> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchUserQL>>(value),
    );
  }
}

String _$trendCNUserListHash() => r'f3f61ac76d1af77a78ec640f430d3666c416021d';

///无需释放，这样内存里就会保存着列表，下次进来不会空数据

abstract class _$TrendCNUserList extends $Notifier<List<SearchUserQL>> {
  List<SearchUserQL> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<SearchUserQL>, List<SearchUserQL>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SearchUserQL>, List<SearchUserQL>>,
              List<SearchUserQL>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(searchTrendUserRequest)
final searchTrendUserRequestProvider = SearchTrendUserRequestFamily._();

final class SearchTrendUserRequestProvider
    extends
        $FunctionalProvider<
          AsyncValue<(List<SearchUserQL>, String)?>,
          (List<SearchUserQL>, String)?,
          FutureOr<(List<SearchUserQL>, String)?>
        >
    with
        $FutureModifier<(List<SearchUserQL>, String)?>,
        $FutureProvider<(List<SearchUserQL>, String)?> {
  SearchTrendUserRequestProvider._({
    required SearchTrendUserRequestFamily super.from,
    required (String, bool, {String? cursor}) super.argument,
  }) : super(
         retry: null,
         name: r'searchTrendUserRequestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchTrendUserRequestHash();

  @override
  String toString() {
    return r'searchTrendUserRequestProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<(List<SearchUserQL>, String)?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<(List<SearchUserQL>, String)?> create(Ref ref) {
    final argument = this.argument as (String, bool, {String? cursor});
    return searchTrendUserRequest(
      ref,
      argument.$1,
      argument.$2,
      cursor: argument.cursor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchTrendUserRequestProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchTrendUserRequestHash() =>
    r'c2d75a6b62f4a7111b7da60d4ba239da7fbe5406';

final class SearchTrendUserRequestFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<(List<SearchUserQL>, String)?>,
          (String, bool, {String? cursor})
        > {
  SearchTrendUserRequestFamily._()
    : super(
        retry: null,
        name: r'searchTrendUserRequestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchTrendUserRequestProvider call(
    String location,
    bool isRefresh, {
    String? cursor,
  }) => SearchTrendUserRequestProvider._(
    argument: (location, isRefresh, cursor: cursor),
    from: this,
  );

  @override
  String toString() => r'searchTrendUserRequestProvider';
}
