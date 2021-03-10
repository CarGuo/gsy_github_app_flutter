import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/**
 * 搜索drawer
 * Created by guoshuyu
 * Date: 2018-07-18
 */

typedef void SearchSelectItemChanged<String>(String value);

class GSYSearchDrawer extends StatefulWidget {
  final SearchSelectItemChanged<String?> typeCallback;
  final SearchSelectItemChanged<String?> sortCallback;
  final SearchSelectItemChanged<String?> languageCallback;

  GSYSearchDrawer(this.typeCallback, this.sortCallback, this.languageCallback);

  @override
  _GSYSearchDrawerState createState() => _GSYSearchDrawerState();
}

class _GSYSearchDrawerState extends State<GSYSearchDrawer> {

  final double itemWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      child: new Container(
        color: Theme.of(context).primaryColor,
        child: Container(
          color: GSYColors.white,
          child: new SingleChildScrollView(
            child: new Column(
              children: _renderList(),
            ),
          ),
        ),
      ),
    );
  }

  _renderList() {
    List<Widget> list = [];
    list.add(new Container(
      width: itemWidth,
    ));
    list.add(_renderTitle(GSYLocalizations.i18n(context)!.search_type));
    for (int i = 0; i < searchFilterType.length; i++) {
      FilterModel model = searchFilterType[i];
      list.add(_renderItem(model, searchFilterType, i, widget.typeCallback));
      list.add(_renderDivider());
    }
    list.add(_renderTitle(GSYLocalizations.i18n(context)!.search_sort));

    for (int i = 0; i < sortType.length; i++) {
      FilterModel model = sortType[i];
      list.add(_renderItem(model, sortType, i, widget.sortCallback));
      list.add(_renderDivider());
    }
    list.add(_renderTitle(GSYLocalizations.i18n(context)!.search_language));
    for (int i = 0; i < searchLanguageType.length; i++) {
      FilterModel model = searchLanguageType[i];
      list.add(
          _renderItem(model, searchLanguageType, i, widget.languageCallback));
      list.add(_renderDivider());
    }
    return list;
  }

  _renderTitle(String title) {
    return new Container(
      color: Theme.of(context).primaryColor,
      width: itemWidth + 50,
      height: 50.0,
      child: new Center(
        child: new Text(
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
    return new Stack(
      children: <Widget>[
        new Container(
          height: 50.0,
          child: new Container(
            width: itemWidth,
            child: new Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Center(
                    child: new Checkbox(
                        value: model.select, onChanged: (value) {})),
                new Center(child: Text(model.name!)),
              ],
            ),
          ),
        ),
        new TextButton(
          onPressed: () {
            setState(() {
              for (FilterModel model in list) {
                model.select = false;
              }
              list[index].select = true;
            });
            select?.call(model.value);
          },
          child: new Container(
            width: itemWidth,
          ),
        )
      ],
    );
  }
}

class FilterModel {
  String? name;
  String? value;
  bool? select;

  FilterModel({this.name, this.value, this.select});
}

var sortType = [
  FilterModel(name: 'desc', value: 'desc', select: true),
  FilterModel(name: 'asc', value: 'asc', select: false),
];
var searchFilterType = [
  FilterModel(name: "best_match", value: 'best%20match', select: true),
  FilterModel(name: "stars", value: 'stars', select: false),
  FilterModel(name: "forks", value: 'forks', select: false),
  FilterModel(name: "updated", value: 'updated', select: false),
];
var searchLanguageType = [
  FilterModel(name: "trendAll", value: null, select: true),
  FilterModel(name: "Java", value: 'Java', select: false),
  FilterModel(name: "Dart", value: 'Dart', select: false),
  FilterModel(name: "Objective_C", value: 'Objective-C', select: false),
  FilterModel(name: "Swift", value: 'Swift', select: false),
  FilterModel(name: "JavaScript", value: 'JavaScript', select: false),
  FilterModel(name: "PHP", value: 'PHP', select: false),
  FilterModel(name: "C__", value: 'C++', select: false),
  FilterModel(name: "C", value: 'C', select: false),
  FilterModel(name: "HTML", value: 'HTML', select: false),
  FilterModel(name: "CSS", value: 'CSS', select: false),
];
