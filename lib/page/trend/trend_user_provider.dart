import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/model/search_user_ql.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

///展示 riverpod ，并且支持翻页场景

part 'trend_user_provider.g.dart';

///无需释放，这样内存里就会保存着列表，下次进来不会空数据
@Riverpod(keepAlive: true)
class TrendCNUserList extends _$TrendCNUserList {

  ///如果调用 ref.refresh ，数据会被重置
  @override
  List<SearchUserQL> build() {
    return [];
  }

  void setList(List<SearchUserQL> list) {
    state = list;
  }

  void addList(List<SearchUserQL> list) {
    ///需要为新的列表，不然不会触发更新
    state = [...state, ...list];
  }

  void clear() {
    state = [];
  }
}

@riverpod
Future<(List<SearchUserQL>, String)?> searchTrendUserRequest(
    Ref ref, String location, bool isRefresh,
    {String? cursor}) async {
  var trendRef = ref.read(trendCNUserListProvider.notifier);
  var result =
      await UserRepository.searchTrendUserRequest("China", cursor: cursor);
  if (result.data != null) {
    var value = result.data;
    if (isRefresh) {
      trendRef.setList(value.$1);
    } else {
      trendRef.addList(value.$1);
    }
    // 这里 refresh 会导致数据在更新后又被清空
    //var _ = ref.refresh(trendCNUserListProvider.notifier);
    //如果是 ref.invalidate ，则是标记过时，下次读取时触发，延迟更新
    return result.value;
  }
  return null;
}
