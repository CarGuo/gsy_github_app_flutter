/// Created by guoshuyu
/// Date: 2018-07-31
library;
import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'license.g.dart';

@JsonSerializable()
class License {

  String? name;

  new(this.name);

  factory fromJson(Map<String, dynamic> json) => _$LicenseFromJson(json);

  Map<String, dynamic> toJson() => _$LicenseToJson(this);
}
