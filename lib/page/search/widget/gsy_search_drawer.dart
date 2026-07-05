import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/// 搜索drawer
/// Created by guoshuyu
/// Date: 2018-07-18

typedef SearchSelectItemChanged<String> = void Function(String value);

class GSYSearchDrawer extends StatefulWidget {
  final SearchSelectItemChanged<String?> typeCallback;
  final SearchSelectItemChanged<String?> sortCallback;
  final SearchSelectItemChanged<String?> languageCallback;

  const GSYSearchDrawer(this.typeCallback, this.sortCallback, this.languageCallback, {super.key});

  @override
  _GSYSearchDrawerState createState() => _GSYSearchDrawerState();
}

class _GSYSearchDrawerState extends State<GSYSearchDrawer> {

  final double itemWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Theme.of(context).primaryColor,
        child: Container(
          color: GSYColors.white,
          child: SingleChildScrollView(
            child: Column(
              children: _renderList(),
            ),
          ),
        ),
      ),
    );
  }

  _renderList() {
    List<Widget> list = [];
    list.add(Container(
      width: itemWidth,
    ));
    list.add(_renderTitle(context.l10n.search_type));
    for (int i = 0; i < searchFilterType.length; i++) {
      FilterModel model = searchFilterType[i];
      list.add(_renderItem(model, searchFilterType, i, widget.typeCallback));
      list.add(_renderDivider());
    }
    list.add(_renderTitle(context.l10n.search_sort));

    for (int i = 0; i < sortType.length; i++) {
      FilterModel model = sortType[i];
      list.add(_renderItem(model, sortType, i, widget.sortCallback));
      list.add(_renderDivider());
    }
    list.add(_renderTitle(context.l10n.search_language));
    for (int i = 0; i < searchLanguageType.length; i++) {
      FilterModel model = searchLanguageType[i];
      list.add(
          _renderItem(model, searchLanguageType, i, widget.languageCallback));
      list.add(_renderDivider());
    }
    return list;
  }

  _renderTitle(String title) {
    return Container(
      color: Theme.of(context).primaryColor,
      width: itemWidth + 50,
      height: 50.0,
      child: Center(
        child: Text(
          title,
          style: GSYConstant.middleTextWhite,
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  _renderDivider() {
    return Container(
      color: GSYColors.subTextColor,
      width: itemWidth,
      height: 0.3,
    );
  }

  _renderItem(FilterModel model, List<FilterModel> list, int index,
      SearchSelectItemChanged<String?>? select) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: 50.0,
          child: SizedBox(
            width: itemWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                    child: Checkbox(
                        value: model.select, onChanged: (value) {})),
                Center(child: Text(model.displayName(context))),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              for (FilterModel model in list) {
                model.select = false;
              }
              list[index].select = true;
            });
            select?.call(model.value);
          },
          child: Container(
            width: itemWidth,
          ),
        )
      ],
    );
  }
}

/// FilterModel
///
/// 之前 name 同时兼任「UI 显示文案」+「唯一标识」，
/// 结果一堆纯代码 raw 值（`best_match` / `trendAll` / `Objective_C` / `C__`）
/// 直接被拿去当中文界面文案，用户看不懂。
///
/// 现在拆成：
/// - [labelBuilder]：接受 [AppLocalizations] 返回本地化显示文案（走 arb）；
///   对固定不需要翻译的名字（比如 `Java` / `Kotlin` / `Objective-C`），
///   labelBuilder 可以直接返回字面量。
/// - [value]：送去 GitHub API 的原始值，**保持不动**（含 URL 编码，例如
///   `best%20match` 和 `c%23`）。
/// - [select]：是否选中，UI 状态。
class FilterModel {
  final String Function(AppLocalizations l10n) labelBuilder;
  final String? value;
  bool? select;

  FilterModel({
    required this.labelBuilder,
    required this.value,
    this.select,
  });

  /// 便捷方法，读取 context 里的 AppLocalizations 生成文案。
  String displayName(BuildContext context) => labelBuilder(context.l10n);
}

var sortType = [
  FilterModel(labelBuilder: (l) => l.search_sort_desc, value: 'desc', select: true),
  FilterModel(labelBuilder: (l) => l.search_sort_asc, value: 'asc', select: false),
];
var searchFilterType = [
  FilterModel(labelBuilder: (l) => l.search_filter_type_best_match, value: 'best%20match', select: true),
  FilterModel(labelBuilder: (l) => l.search_filter_type_stars, value: 'stars', select: false),
  FilterModel(labelBuilder: (l) => l.search_filter_type_forks, value: 'forks', select: false),
  FilterModel(labelBuilder: (l) => l.search_filter_type_updated, value: 'updated', select: false),
];

/// 语言列表：与 [trendType] 保持齐平（Kotlin / Go / Python / C# 都补齐），
/// 首项复用已有的 trend_all_languages（"所有语言"）避免歧义。
/// 编程语言名本身是专有名词，不做翻译，直接返回字面量。
var searchLanguageType = [
  FilterModel(labelBuilder: (l) => l.trend_all_languages, value: null, select: true),
  FilterModel(labelBuilder: (_) => 'Java', value: 'Java', select: false),
  FilterModel(labelBuilder: (_) => 'Kotlin', value: 'Kotlin', select: false),
  FilterModel(labelBuilder: (_) => 'Dart', value: 'Dart', select: false),
  FilterModel(labelBuilder: (_) => 'Objective-C', value: 'Objective-C', select: false),
  FilterModel(labelBuilder: (_) => 'Swift', value: 'Swift', select: false),
  FilterModel(labelBuilder: (_) => 'JavaScript', value: 'JavaScript', select: false),
  FilterModel(labelBuilder: (_) => 'PHP', value: 'PHP', select: false),
  FilterModel(labelBuilder: (_) => 'Go', value: 'Go', select: false),
  FilterModel(labelBuilder: (_) => 'C++', value: 'C++', select: false),
  FilterModel(labelBuilder: (_) => 'C', value: 'C', select: false),
  FilterModel(labelBuilder: (_) => 'HTML', value: 'HTML', select: false),
  FilterModel(labelBuilder: (_) => 'CSS', value: 'CSS', select: false),
  FilterModel(labelBuilder: (_) => 'Python', value: 'Python', select: false),
  FilterModel(labelBuilder: (_) => 'C#', value: 'c%23', select: false),
];

void resetSearchDrawerFilters() {
  _resetFilterList(sortType);
  _resetFilterList(searchFilterType);
  _resetFilterList(searchLanguageType);
}

void _resetFilterList(List<FilterModel> list) {
  for (int i = 0; i < list.length; i++) {
    list[i].select = i == 0;
  }
}
