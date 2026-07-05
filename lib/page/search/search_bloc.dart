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

  /// tab 索引到 GitHub search API 的 type 参数
  ///
  /// 0 = repositories（type=null）
  /// 1 = users（type='user'）
  /// 2 = issues + pull requests（type='issue'）
  /// 3 = code（type='code'，要求 token 有 repo scope）
  String? get _apiType {
    switch (selectIndex) {
      case 1:
        return 'user';
      case 2:
        return 'issue';
      case 3:
        return 'code';
      default:
        return null;
    }
  }

  ///获取搜索数据
  ///
  /// 搜索成功后异步写入搜索历史；写入失败不影响主流程。
  getDataLogic(int page) async {
    final query = searchText;
    // 空查询直接短路，避免拿 "q=" 打 GitHub search API。
    // 触发链路：抽屉里选 language / sort 会调 _resolveSelectIndex → 强制 refresh，
    // 这里如果不拦，就会以空 q 触发 400/422，被 UI 弹成"请确保 ClientId 正确"，
    // 迷惑用户以为登录挂了。核心问题是"没输入词也不该发请求"，从这里根治。
    if (query == null || query.trim().isEmpty) {
      return null;
    }
    // language 过滤器：
    // - repositories 搜索通过拼 `+language:xxx` 修饰符生效，
    // - /search/code 支持相同的 `language:` 修饰符（GitHub 官方语法），
    // - /search/users 与 /search/issues 语义不同，为了避免歧义关掉。
    final effectiveLanguage =
        (selectIndex == 0 || selectIndex == 3) ? language : null;
    final res = await ReposRepository.searchRepositoryRequest(
        query, effectiveLanguage, type, sort, _apiType, page, Config.PAGE_SIZE);
    if (page == 1 && res != null && res.result == true) {
      unawaited(SearchHistoryRepository.add(query));
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

