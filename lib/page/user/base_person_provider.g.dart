// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_person_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchHonorDataHash() => r'7f84f6895bdda593859d93add87021d7c91dce4d';

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

///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
///
/// Copied from [fetchHonorData].
@ProviderFor(fetchHonorData)
const fetchHonorDataProvider = FetchHonorDataFamily();

///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
///
/// Copied from [fetchHonorData].
class FetchHonorDataFamily extends Family<AsyncValue<HonorModel?>> {
  ///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
  ///
  /// Copied from [fetchHonorData].
  const FetchHonorDataFamily();

  ///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
  ///
  /// Copied from [fetchHonorData].
  FetchHonorDataProvider call(
    String userName,
  ) {
    return FetchHonorDataProvider(
      userName,
    );
  }

  @override
  FetchHonorDataProvider getProviderOverride(
    covariant FetchHonorDataProvider provider,
  ) {
    return call(
      provider.userName,
    );
  }

  static final Iterable<ProviderOrFamily> _dependencies =
      const <ProviderOrFamily>[];

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static final Iterable<ProviderOrFamily> _allTransitiveDependencies =
      const <ProviderOrFamily>{};

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchHonorDataProvider';
}

///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
///
/// Copied from [fetchHonorData].
class FetchHonorDataProvider extends AutoDisposeFutureProvider<HonorModel?> {
  ///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
  ///
  /// Copied from [fetchHonorData].
  FetchHonorDataProvider(
    String userName,
  ) : this._internal(
          (ref) => fetchHonorData(
            ref as FetchHonorDataRef,
            userName,
          ),
          from: fetchHonorDataProvider,
          name: r'fetchHonorDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchHonorDataHash,
          dependencies: FetchHonorDataFamily._dependencies,
          allTransitiveDependencies:
              FetchHonorDataFamily._allTransitiveDependencies,
          userName: userName,
        );

  FetchHonorDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userName,
  }) : super.internal();

  final String userName;

  @override
  Override overrideWith(
    FutureOr<HonorModel?> Function(FetchHonorDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchHonorDataProvider._internal(
        (ref) => create(ref as FetchHonorDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userName: userName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<HonorModel?> createElement() {
    return _FetchHonorDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchHonorDataProvider && other.userName == userName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchHonorDataRef on AutoDisposeFutureProviderRef<HonorModel?> {
  /// The parameter `userName` of this provider.
  String get userName;
}

class _FetchHonorDataProviderElement
    extends AutoDisposeFutureProviderElement<HonorModel?>
    with FetchHonorDataRef {
  _FetchHonorDataProviderElement(super.provider);

  @override
  String get userName => (origin as FetchHonorDataProvider).userName;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
