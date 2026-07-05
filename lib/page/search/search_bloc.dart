import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/search_history_repository.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_drawer.dart';

class SearchBLoC {

  ///搜索仓库还是人
  int selectIndex = 0;

  ///搜索文件
  String? get searchText {
    return textEditingController.text;
  }

  ///排序类型
  String? type = searchFilterType[0].value;

  ///排序
  String? sort = sortType[0].value;

  ///过滤语言
  String? language = searchLanguageType[0].value;

  final TextEditingController textEditingController  = TextEditingController();

  ///获取搜索数据
  ///
  /// 搜索成功后异步写入搜索历史；写入失败不影响主流程。
  getDataLogic(int page) async {
    final query = searchText;
    final res = await ReposRepository.searchRepositoryRequest(query, language, type, sort,
        selectIndex == 0 ? null : 'user', page, Config.PAGE_SIZE);
    if (page == 1 && res != null && res.result == true) {
      unawaited(SearchHistoryRepository.add(query ?? ''));
    }
    return res;
  }

  void resetFilters() {
    resetSearchDrawerFilters();
    type = searchFilterType[0].value;
    sort = sortType[0].value;
    language = searchLanguageType[0].value;
    selectIndex = 0;
  }

  void dispose() {
    resetFilters();
    textEditingController.dispose();
  }
}

