import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'Branch.g.dart';

abstract class Branch implements Built<Branch, BranchBuilder> {
  static Serializer<Branch> get serializer => _$branchSerializer;

  @nullable
  String get name;

  @nullable
  @BuiltValueField(wireName: 'tarball_url')
  String get tarballUrl;

  @nullable
  @BuiltValueField(wireName: 'zipball_url')
  String get zipballUrl;


  Branch._();
  factory Branch([void Function(BranchBuilder) updates]) = _$Branch;
}