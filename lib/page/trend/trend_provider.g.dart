// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trendFirst)
const trendFirstProvider = TrendFirstFamily._();

final class TrendFirstProvider
    extends
        $FunctionalProvider<
          AsyncValue<DataResult?>,
          DataResult?,
          FutureOr<DataResult?>
        >
    with $FutureModifier<DataResult?>, $FutureProvider<DataResult?> {
  const TrendFirstProvider._({
    required TrendFirstFamily super.from,
    required (String?, String?) super.argument,
  }) : super(
         retry: null,
         name: r'trendFirstProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendFirstHash();

  @override
  String toString() {
    return r'trendFirstProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DataResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DataResult?> create(Ref ref) {
    final argument = this.argument as (String?, String?);
    return trendFirst(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendFirstProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendFirstHash() => r'3e6901281c2b4209f6a6af2bd8d224bed08ec011';

final class TrendFirstFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DataResult?>, (String?, String?)> {
  const TrendFirstFamily._()
    : super(
        retry: null,
        name: r'trendFirstProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrendFirstProvider call(String? since, String? selectType) =>
      TrendFirstProvider._(argument: (since, selectType), from: this);

  @override
  String toString() => r'trendFirstProvider';
}

@ProviderFor(trendSecond)
const trendSecondProvider = TrendSecondFamily._();

final class TrendSecondProvider
    extends
        $FunctionalProvider<
          AsyncValue<DataResult?>,
          DataResult?,
          FutureOr<DataResult?>
        >
    with $FutureModifier<DataResult?>, $FutureProvider<DataResult?> {
  const TrendSecondProvider._({
    required TrendSecondFamily super.from,
    required (String?, String?) super.argument,
  }) : super(
         retry: null,
         name: r'trendSecondProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendSecondHash();

  @override
  String toString() {
    return r'trendSecondProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DataResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DataResult?> create(Ref ref) {
    final argument = this.argument as (String?, String?);
    return trendSecond(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendSecondProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendSecondHash() => r'99470661772032da2b765be93e555eb936aa5383';

final class TrendSecondFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DataResult?>, (String?, String?)> {
  const TrendSecondFamily._()
    : super(
        retry: null,
        name: r'trendSecondProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrendSecondProvider call(String? since, String? selectType) =>
      TrendSecondProvider._(argument: (since, selectType), from: this);

  @override
  String toString() => r'trendSecondProvider';
}
