import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/search_history_repository.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_drawer.dart';

/// 2026-10 FPR-112: one submitted request, including pagination, must never read
/// a later edit/tab/filter while it is in flight or loading its next page.
@immutable
class SearchRequest {
  const new({
    required this.query,
    required this.selectIndex,
    required this.type,
    required this.sort,
    required this.language,
    required this.page,
  });

  final String query;
  final int selectIndex;
  final String? type;
  final String? sort;
  final String? language;
  final int page;

  String? get apiType => switch (selectIndex) {
    1 => 'user',
    2 => 'issue',
    3 => 'code',
    _ => null,
  };

  // Keep the existing API contract: language applies to repos/code only.
  String? get effectiveLanguage =>
      selectIndex == 0 || selectIndex == 3 ? language : null;

  SearchRequest forPage(int page) => SearchRequest(
    query: query,
    selectIndex: selectIndex,
    type: type,
    sort: sort,
    language: language,
    page: page,
  );
}

class SearchBLoC {
  int selectIndex = 0;
  String? get searchText => textEditingController.text;
  String? type = searchFilterType[0].value;
  String? sort = sortType[0].value;
  String? language = searchLanguageType[0].value;
  final TextEditingController textEditingController = TextEditingController();

  SearchRequest snapshot(int page) => SearchRequest(
    query: textEditingController.text,
    selectIndex: selectIndex,
    type: type,
    sort: sort,
    language: language,
    page: page,
  );

  Future<DataResult?> getDataLogic(SearchRequest request) async {
    if (request.query.trim().isEmpty) return null;
    final DataResult? res = await ReposRepository.searchRepositoryRequest(
      request.query,
      request.effectiveLanguage,
      request.type,
      request.sort,
      request.apiType,
      request.page,
      Config.PAGE_SIZE,
    );
    if (request.page == 1 && res != null && res.result) {
      unawaited(SearchHistoryRepository.add(request.query));
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
