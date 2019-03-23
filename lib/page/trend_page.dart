import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/bloc/base/base_bloc.dart';
import 'package:gsy_github_app_flutter/bloc/trend_bloc.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_bloc_list_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_pull_new_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/repos_item.dart';
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

class _TrendPageState extends State<TrendPage> with AutomaticKeepAliveClientMixin<TrendPage>, GSYListState<TrendPage> {
  static TrendTypeModel selectTime = null;

  static TrendTypeModel selectType = null;

  final TrendBloc trendBloc = new TrendBloc();

  _renderItem(e) {
    ReposViewModel reposViewModel = ReposViewModel.fromTrendMap(e);
    return new ReposItem(reposViewModel, onPressed: () {
      NavigatorUtils.goReposDetail(context, reposViewModel.ownerName, reposViewModel.repositoryName);
    });
  }

  _renderHeader(Store<GSYState> store) {
    if (selectType == null && selectType == null) {
      return Container();
    }
    return new GSYCardItem(
      color: store.state.themeData.primaryColor,
      margin: EdgeInsets.all(10.0),
      shape: new RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: new Padding(
        padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 5.0),
        child: new Row(
          children: <Widget>[
            _renderHeaderPopItem(selectTime.name, trendTime(context), (TrendTypeModel result) {
              if (isLoading) {
                Fluttertoast.showToast(msg: CommonUtils.getLocale(context).loading_text);
                return;
              }
              setState(() {
                selectTime = result;
              });
              showRefreshLoading();
            }),
            new Container(height: 10.0, width: 0.5, color: Color(GSYColors.white)),
            _renderHeaderPopItem(selectType.name, trendType(context), (TrendTypeModel result) {
              if (isLoading) {
                Fluttertoast.showToast(msg: CommonUtils.getLocale(context).loading_text);
                return;
              }
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
    return await trendBloc.requestRefresh(selectTime, selectType);
  }

  @override
  requestLoadMore() async {
    return null;
  }

  @override
  BlocListBase get bloc => trendBloc;

  @override
  bool get isRefreshFirst => false;

  @override
  void didChangeDependencies() {
    if (bloc.getDataLength() == 0) {
      setState(() {
        selectTime = trendTime(context)[0];
        selectType = trendType(context)[0];
      });
      showRefreshLoading();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    clearData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        bloc.changeNeedHeaderStatus(needHeader);
        return new Scaffold(
          backgroundColor: Color(GSYColors.mainBackgroundColor),
          appBar: new AppBar(
            flexibleSpace: _renderHeader(store),
            backgroundColor: Color(GSYColors.mainBackgroundColor),
            leading: new Container(),
            elevation: 0.0,
          ),
          body: BlocProvider<TrendBloc>(
            bloc: trendBloc,
            child: GSYPullLoadWidget(
              bloc.pullLoadWidgetControl,
              (BuildContext context, int index) => _renderItem(bloc.dataList[index]),
              handleRefresh,
              onLoadMore,
              refreshKey: refreshIndicatorKey,
            ),
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

trendTime(BuildContext context) {
  return [
    new TrendTypeModel(CommonUtils.getLocale(context).trend_day, "daily"),
    new TrendTypeModel(CommonUtils.getLocale(context).trend_week, "weekly"),
    new TrendTypeModel(CommonUtils.getLocale(context).trend_month, "monthly"),
  ];
}

trendType(BuildContext context) {
  return [
    TrendTypeModel(CommonUtils.getLocale(context).trend_all, null),
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
    TrendTypeModel("Python", "Python"),
    TrendTypeModel("C#", "c%23"),
  ];
}
