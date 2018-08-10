import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/ReposItem.dart';
import 'package:redux/redux.dart';

/**
 * 主页趋势tab页
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class TrendPage extends StatefulWidget {
  @override
  _TrendPageState createState() => _TrendPageState();
}

class _TrendPageState extends GSYListState<TrendPage> {
  TrendTypeModel selectTime = trendTime[0];
  TrendTypeModel selectType = trendType[0];

  _renderItem(e) {
    ReposViewModel reposViewModel = ReposViewModel.fromTrendMap(e);
    return new ReposItem(reposViewModel, onPressed: () {
      NavigatorUtils.goReposDetail(context, reposViewModel.ownerName, reposViewModel.repositoryName);
    });
  }

  _renderHeader() {
    return new GSYCardItem(
      color: Color(GSYColors.primaryValue),
      margin: EdgeInsets.all(10.0),
      shape: new RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: new Padding(
        padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 5.0),
        child: new Row(
          children: <Widget>[
            _renderHeaderPopItem(selectTime.name, trendTime, (TrendTypeModel result) {
              setState(() {
                selectTime = result;
              });
              showRefreshLoading();
            }),
            new Container(height: 10.0, width: 0.5, color: Color(GSYColors.white)),
            _renderHeaderPopItem(selectType.name, trendType, (TrendTypeModel result) {
              setState(() {
                selectType = result;
              });
              showRefreshLoading();
            }),
          ],
        ),
      ),
    );
  }

  _renderHeaderPopItem(String data, List<TrendTypeModel> list, PopupMenuItemSelected<TrendTypeModel> onSelected) {
    return new Expanded(
      child: new PopupMenuButton<TrendTypeModel>(
        child: new Center(child: new Text(data, style: GSYConstant.middleTextWhite)),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return _renderHeaderPopItemChild(list);
        },
      ),
    );
  }

  _renderHeaderPopItemChild(List<TrendTypeModel> data) {
    List<PopupMenuEntry<TrendTypeModel>> list = new List();
    for (TrendTypeModel item in data) {
      list.add(PopupMenuItem<TrendTypeModel>(
        value: item,
        child: new Text(item.name),
      ));
    }
    return list;
  }

  @override
  Future<Null> handleRefresh() async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    page = 1;
    await ReposDao.getTrendDao(_getStore(), since: selectTime.value, languageType: selectType.value);
    setState(() {
      pullLoadWidgetControl.needLoadMore = false;
    });
    isLoading = false;
    return null;
  }

  @override
  requestRefresh() async {
    return null;
  }

  @override
  requestLoadMore() async {
    return null;
  }

  @override
  bool get isRefreshFirst => false;

  @override
  void didChangeDependencies() {
    pullLoadWidgetControl.dataList = _getStore().state.trendList;
    if (pullLoadWidgetControl.dataList.length == 0) {
      showRefreshLoading();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    clearData();
  }

  Store<GSYState> _getStore() {
    return StoreProvider.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return new Scaffold(
          backgroundColor: Color(GSYColors.mainBackgroundColor),
          appBar: new AppBar(
            flexibleSpace: _renderHeader(),
            backgroundColor: Color(GSYColors.mainBackgroundColor),
            leading: new Container(),
            elevation: 0.0,
          ),
          body: GSYPullLoadWidget(
            pullLoadWidgetControl,
                (BuildContext context, int index) => _renderItem(pullLoadWidgetControl.dataList[index]),
            handleRefresh,
            onLoadMore,
            refreshKey: refreshIndicatorKey,
          ),
        );
      },
    );
  }
}

class TrendTypeModel {
  final String name;
  final String value;

  TrendTypeModel(this.name, this.value);
}

var trendTime = [
  TrendTypeModel(GSYStrings.trend_day, "daily"),
  TrendTypeModel(GSYStrings.trend_week, "weekly"),
  TrendTypeModel(GSYStrings.trend_month, "monthly"),
];

var trendType = [
  TrendTypeModel(GSYStrings.trend_all, null),
  TrendTypeModel("Java", "Java"),
  TrendTypeModel("Kotlin", "Kotlin"),
  TrendTypeModel("Dart", "Dart"),
  TrendTypeModel("Objective-C", "Objective-C"),
  TrendTypeModel("Swift", "Swift"),
  TrendTypeModel("JavaScript", "JavaScript"),
  TrendTypeModel("PHP", "PHP"),
  TrendTypeModel("Go", "Go"),
  TrendTypeModel("C++", "C++"),
  TrendTypeModel("C", "C"),
  TrendTypeModel("HTML", "HTML"),
  TrendTypeModel("CSS", "CSS"),
];
