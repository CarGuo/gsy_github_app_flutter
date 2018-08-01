import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/ReposItem.dart';

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
  TrendTypeModel selectTime = TrendTime[0];
  TrendTypeModel selectType = TrendType[0];

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
            _renderHeaderPopItem(selectTime.name, TrendTime, (TrendTypeModel result) {
              setState(() {
                selectTime = result;
              });
              showRefreshLoading();
            }),
            new Container(height: 10.0, width: 0.5, color: Colors.white),
            _renderHeaderPopItem(selectType.name, TrendType, (TrendTypeModel result) {
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
  requestRefresh() async {
    return await ReposDao.getTrendDao(since: selectTime.value, languageType: selectType.value);
  }

  @override
  requestLoadMore() async {
    return null;
  }

  @override
  bool get isRefreshFirst => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    clearData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
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
  }
}

class TrendTypeModel {
  final String name;
  final String value;

  TrendTypeModel(this.name, this.value);
}

var TrendTime = [
  TrendTypeModel(GSYStrings.trend_day, "daily"),
  TrendTypeModel(GSYStrings.trend_week, "weekly"),
  TrendTypeModel(GSYStrings.trend_month, "monthly"),
];

var TrendType = [
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
