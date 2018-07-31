import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-31
 */

part 'DownloadSource.g.dart';

@JsonSerializable()
class DownloadSource extends Object with _$DownloadSourceSerializerMixin {
  String url;
  bool isSourceCode;
  String name;
  int size;

  DownloadSource(
    this.url,
    this.isSourceCode,
    this.name,
    this.size,
  );

  factory DownloadSource.fromJson(Map<String, dynamic> json) => _$DownloadSourceFromJson(json);
}
