import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'base_person_provider.g.dart';


///指定作用域，让该 provider as scoped ，[]表示不依赖其他，让其每次使用都在上下文独立
@Riverpod(dependencies: [])
Future<HonorModel?> fetchHonorData(Ref ref, String userName) async {
  var res = await ReposRepository.getUserRepository100StatusRequest(userName);
  if (res != null && res.result) {
    return HonorModel.fromJson(res.data);
  }
  return null;
}

class HonorModel {
  int? beStaredCount;
  List? honorList;

  HonorModel.fromJson(Map<String, dynamic> map) {
    beStaredCount = map["stared"];
    honorList = map["list"];
  }
}
