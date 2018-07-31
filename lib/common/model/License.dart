/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'License.g.dart';

@JsonSerializable()
class License extends Object with _$LicenseSerializerMixin {

  String name;

  License(this.name);

  factory License.fromJson(Map<String, dynamic> json) => _$LicenseFromJson(json);
}
