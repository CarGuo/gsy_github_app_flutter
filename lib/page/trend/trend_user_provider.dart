import 'package:flutter/material.dart';
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
    Ref ref, String location,
    {String? cursor}) async {
  var result =
      await UserRepository.searchTrendUserRequest("China", cursor: cursor);
  return result.data;
}
