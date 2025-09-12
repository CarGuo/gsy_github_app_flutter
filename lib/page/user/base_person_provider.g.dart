// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_person_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立

@ProviderFor(fetchHonorData)
const fetchHonorDataProvider = FetchHonorDataFamily._();

///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立

final class FetchHonorDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<HonorModel?>,
          HonorModel?,
          FutureOr<HonorModel?>
        >
    with $FutureModifier<HonorModel?>, $FutureProvider<HonorModel?> {
  ///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
  const FetchHonorDataProvider._({
    required FetchHonorDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchHonorDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchHonorDataHash();

  @override
  String toString() {
    return r'fetchHonorDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<HonorModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HonorModel?> create(Ref ref) {
    final argument = this.argument as String;
    return fetchHonorData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchHonorDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchHonorDataHash() => r'7f84f6895bdda593859d93add87021d7c91dce4d';

///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立

final class FetchHonorDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<HonorModel?>, String> {
  const FetchHonorDataFamily._()
    : super(
        retry: null,
        name: r'fetchHonorDataProvider',
        dependencies: const <ProviderOrFamily>[],
        $allTransitiveDependencies: const <ProviderOrFamily>[],
        isAutoDispose: true,
      );

  ///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立

  FetchHonorDataProvider call(String userName) =>
      FetchHonorDataProvider._(argument: userName, from: this);

  @override
  String toString() => r'fetchHonorDataProvider';
}
