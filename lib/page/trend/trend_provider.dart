import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trend_provider.g.dart';

///展示非注解 riverpod ，并且针对处理数据库 & 服务器数据请求,两个 provider 先后顺序

bool trendLoadingState = false;
bool trendRequestedState = false;

@riverpod
Future<DataResult?> trendFirst(Ref ref, String? since, String? selectType) async {
  trendLoadingState = true;
  var res = await ReposRepository.getTrendRequest(
      since: since, languageType: selectType);
  trendLoadingState = false;
  trendRequestedState = true;
  if (res != null && res.result) {
    return res;
  }
  return null;
}

@riverpod
Future<DataResult?> trendSecond(Ref ref, String? since, String? selectType) async {
  trendLoadingState = true;
  final res = await ref.watch(trendFirstProvider(since, selectType).future);
  trendLoadingState = false;
  trendRequestedState = true;
  if (res != null && res.next != null) {
    var resNext = await res.next?.call();
    if (resNext != null && resNext.result) {
      return res;
    }
  }
  return null;
}
