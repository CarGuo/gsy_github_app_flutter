import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/model/SearchUserQL.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

///展示 riverpod ，并且支持翻页场景

part 'trend_user_provider.g.dart';

@riverpod
class TrendCNUserList extends _$TrendCNUserList {
  List<SearchUserQL> data = [];

  @override
  List<SearchUserQL> build() => data;

  void setList(List<SearchUserQL> list) {
    data = list;
    state = data;
  }

  void addList(List<SearchUserQL> list) {
    data.addAll(list);

    ///需要 toList 为新的列表，不然不会触发更新
    state = data.toList();
  }

  void clear() {
    data.clear();
    state = [];
  }
}

@riverpod
Future<(List<SearchUserQL>, String)?> searchTrendUserRequest(
    Ref ref, String location, bool isRefresh,
    {String? cursor}) async {
  var result =
      await UserRepository.searchTrendUserRequest("China", cursor: cursor);
  if (result.data != null) {
    var value = result.data;
    var trendRef = ref.read(trendCNUserListProvider.notifier);
    if (isRefresh) {
      trendRef.setList(value.$1);
    } else {
      trendRef.addList(value.$1);
    }
    var _ = ref.refresh(trendCNUserListProvider.notifier);
    return result.value;
  }
  return null;
}
