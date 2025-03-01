// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchTrendUserRequestHash() =>
    r'ac778f5a6b971be10cac54dba88243725747e346';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [searchTrendUserRequest].
@ProviderFor(searchTrendUserRequest)
const searchTrendUserRequestProvider = SearchTrendUserRequestFamily();

/// See also [searchTrendUserRequest].
class SearchTrendUserRequestFamily
    extends Family<AsyncValue<(List<SearchUserQL>, String)?>> {
  /// See also [searchTrendUserRequest].
  const SearchTrendUserRequestFamily();

  /// See also [searchTrendUserRequest].
  SearchTrendUserRequestProvider call(
    String location,
    bool isRefresh, {
    String? cursor,
  }) {
    return SearchTrendUserRequestProvider(
      location,
      isRefresh,
      cursor: cursor,
    );
  }

  @override
  SearchTrendUserRequestProvider getProviderOverride(
    covariant SearchTrendUserRequestProvider provider,
  ) {
    return call(
      provider.location,
      provider.isRefresh,
      cursor: provider.cursor,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchTrendUserRequestProvider';
}

/// See also [searchTrendUserRequest].
class SearchTrendUserRequestProvider
    extends AutoDisposeFutureProvider<(List<SearchUserQL>, String)?> {
  /// See also [searchTrendUserRequest].
  SearchTrendUserRequestProvider(
    String location,
    bool isRefresh, {
    String? cursor,
  }) : this._internal(
          (ref) => searchTrendUserRequest(
            ref as SearchTrendUserRequestRef,
            location,
            isRefresh,
            cursor: cursor,
          ),
          from: searchTrendUserRequestProvider,
          name: r'searchTrendUserRequestProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchTrendUserRequestHash,
          dependencies: SearchTrendUserRequestFamily._dependencies,
          allTransitiveDependencies:
              SearchTrendUserRequestFamily._allTransitiveDependencies,
          location: location,
          isRefresh: isRefresh,
          cursor: cursor,
        );

  SearchTrendUserRequestProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.location,
    required this.isRefresh,
    required this.cursor,
  }) : super.internal();

  final String location;
  final bool isRefresh;
  final String? cursor;

  @override
  Override overrideWith(
    FutureOr<(List<SearchUserQL>, String)?> Function(
            SearchTrendUserRequestRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchTrendUserRequestProvider._internal(
        (ref) => create(ref as SearchTrendUserRequestRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        location: location,
        isRefresh: isRefresh,
        cursor: cursor,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<(List<SearchUserQL>, String)?>
      createElement() {
    return _SearchTrendUserRequestProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchTrendUserRequestProvider &&
        other.location == location &&
        other.isRefresh == isRefresh &&
        other.cursor == cursor;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, location.hashCode);
    hash = _SystemHash.combine(hash, isRefresh.hashCode);
    hash = _SystemHash.combine(hash, cursor.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchTrendUserRequestRef
    on AutoDisposeFutureProviderRef<(List<SearchUserQL>, String)?> {
  /// The parameter `location` of this provider.
  String get location;

  /// The parameter `isRefresh` of this provider.
  bool get isRefresh;

  /// The parameter `cursor` of this provider.
  String? get cursor;
}

class _SearchTrendUserRequestProviderElement
    extends AutoDisposeFutureProviderElement<(List<SearchUserQL>, String)?>
    with SearchTrendUserRequestRef {
  _SearchTrendUserRequestProviderElement(super.provider);

  @override
  String get location => (origin as SearchTrendUserRequestProvider).location;
  @override
  bool get isRefresh => (origin as SearchTrendUserRequestProvider).isRefresh;
  @override
  String? get cursor => (origin as SearchTrendUserRequestProvider).cursor;
}

String _$trendCNUserListHash() => r'aea06336b92d3cc570f969d63fda016132cdf064';

///无需释放，这样内存里就会保存着列表，下次进来不会空数据
///
/// Copied from [TrendCNUserList].
@ProviderFor(TrendCNUserList)
final trendCNUserListProvider =
    NotifierProvider<TrendCNUserList, List<SearchUserQL>>.internal(
  TrendCNUserList.new,
  name: r'trendCNUserListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendCNUserListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrendCNUserList = Notifier<List<SearchUserQL>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
