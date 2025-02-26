import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

///展示非注解 riverpod ，并且针对处理数据库 & 服务器数据请求,两个 provider 先后顺序

bool trendLoadingState = false;
bool trendRequestedState = false;

final trendFirstProvider =
    FutureProvider.family<DataResult?, (String?, String?)>((ref, query) async {
  var (since, selectType) = query;
  trendLoadingState = true;
  var res = await ReposRepository.getTrendRequest(
      since: since, languageType: selectType);
  trendLoadingState = false;
  trendRequestedState = true;
  if (res != null && res.result) {
    return res;
  }
  return null;
});

final trendSecondProvider =
    FutureProvider.family<DataResult?, (String?, String?)>((ref, query) async {
  trendLoadingState = true;
  final res = await ref.watch(trendFirstProvider(query).future);
  trendLoadingState = false;
  trendRequestedState = true;
  if (res != null && res.next != null) {
    var resNext = await res.next?.call();
    if (resNext != null && resNext.result) {
      return res;
    }
  }
  return null;
});
