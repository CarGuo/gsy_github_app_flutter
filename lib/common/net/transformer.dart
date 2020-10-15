import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:gsy_github_app_flutter/model/Branch.dart';


part 'transformer.g.dart';

@SerializersFor(const [
  Branch,
])
final Serializers serializers = (_$serializers.toBuilder()
  ..addPlugin(new StandardJsonPlugin())
  ..add(new Iso8601DateTimeSerializer())
).build();
