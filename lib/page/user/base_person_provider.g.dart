// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_person_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchHonorDataHash() => r'297fc6d470a18eec56cb77bf38c7be96803cf291';

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

/// See also [fetchHonorData].
@ProviderFor(fetchHonorData)
const fetchHonorDataProvider = FetchHonorDataFamily();

/// See also [fetchHonorData].
class FetchHonorDataFamily extends Family<AsyncValue<HonorModel?>> {
  /// See also [fetchHonorData].
  const FetchHonorDataFamily();

  /// See also [fetchHonorData].
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

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchHonorDataProvider';
}

/// See also [fetchHonorData].
class FetchHonorDataProvider extends AutoDisposeFutureProvider<HonorModel?> {
  /// See also [fetchHonorData].
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
