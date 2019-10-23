import 'package:json_annotation/json_annotation.dart';

/**
 * Created by guoshuyu
 * Date: 2018-08-07
 */
part 'TrendingRepoModel.g.dart';

@JsonSerializable()
class TrendingRepoModel {
  String fullName;
  String url;

  String description;
  String language;
  String meta;
  List<String> contributors;
  String contributorsUrl;

  String starCount;
  String forkCount;
  String name;

  String reposName;

  TrendingRepoModel(
    this.fullName,
    this.url,
    this.description,
    this.language,
    this.meta,
    this.contributors,
    this.contributorsUrl,
    this.starCount,
    this.name,
    this.reposName,
    this.forkCount,
  );

  TrendingRepoModel.empty();

  factory TrendingRepoModel.fromJson(Map<String, dynamic> json) => _$TrendingRepoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrendingRepoModelToJson(this);
}
