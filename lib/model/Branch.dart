import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'Branch.g.dart';

abstract class Branch implements Built<Branch, BranchBuilder> {
  static Serializer<Branch> get serializer => _$branchSerializer;


  String? get name;


  @BuiltValueField(wireName: 'tarball_url')
  String? get tarballUrl;


  @BuiltValueField(wireName: 'zipball_url')
  String? get zipballUrl;


  Branch._();
  factory Branch([void Function(BranchBuilder)? updates]) = _$Branch;
}