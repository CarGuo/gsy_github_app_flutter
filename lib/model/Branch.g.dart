// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Branch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Branch> _$branchSerializer = new _$BranchSerializer();

class _$BranchSerializer implements StructuredSerializer<Branch> {
  @override
  final Iterable<Type> types = const [Branch, _$Branch];
  @override
  final String wireName = 'Branch';

  @override
  Iterable<Object?> serialize(Serializers serializers, Branch object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
    value = object.name;
    if (value != null) {
      result
        ..add('name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.tarballUrl;
    if (value != null) {
      result
        ..add('tarball_url')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.zipballUrl;
    if (value != null) {
      result
        ..add('zipball_url')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  Branch deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BranchBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'tarball_url':
          result.tarballUrl = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'zipball_url':
          result.zipballUrl = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$Branch extends Branch {
  @override
  final String? name;
  @override
  final String? tarballUrl;
  @override
  final String? zipballUrl;

  factory _$Branch([void Function(BranchBuilder)? updates]) =>
      (new BranchBuilder()..update(updates))._build();

  _$Branch._({this.name, this.tarballUrl, this.zipballUrl}) : super._();

  @override
  Branch rebuild(void Function(BranchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BranchBuilder toBuilder() => new BranchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Branch &&
        name == other.name &&
        tarballUrl == other.tarballUrl &&
        zipballUrl == other.zipballUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, tarballUrl.hashCode);
    _$hash = $jc(_$hash, zipballUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Branch')
          ..add('name', name)
          ..add('tarballUrl', tarballUrl)
          ..add('zipballUrl', zipballUrl))
        .toString();
  }
}

class BranchBuilder implements Builder<Branch, BranchBuilder> {
  _$Branch? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _tarballUrl;
  String? get tarballUrl => _$this._tarballUrl;
  set tarballUrl(String? tarballUrl) => _$this._tarballUrl = tarballUrl;

  String? _zipballUrl;
  String? get zipballUrl => _$this._zipballUrl;
  set zipballUrl(String? zipballUrl) => _$this._zipballUrl = zipballUrl;

  BranchBuilder();

  BranchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _tarballUrl = $v.tarballUrl;
      _zipballUrl = $v.zipballUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Branch other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Branch;
  }

  @override
  void update(void Function(BranchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Branch build() => _build();

  _$Branch _build() {
    final _$result = _$v ??
        new _$Branch._(
            name: name, tarballUrl: tarballUrl, zipballUrl: zipballUrl);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
