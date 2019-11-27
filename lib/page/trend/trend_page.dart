import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_bloc.dart';
import 'package:gsy_github_app_flutter/model/TrendingRepoModel.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_item.dart';
import 'package:redux/redux.dart';

/**
 * 主页趋势tab页
 * 目前采用纯 bloc 的 rxdart(stream) + streamBuilder
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class TrendPage extends StatefulWidget {
  TrendPage({Key key}) : super(key: key);

  @override
  TrendPageState createState() => TrendPageState();
}

class TrendPageState extends State<TrendPage>
    with
        AutomaticKeepAliveClientMixin<TrendPage>,
        SingleTickerProviderStateMixin {
  ///显示数据时间
  TrendTypeModel selectTime = null;

  ///显示过滤语言
  TrendTypeModel selectType = null;

  /// NestedScrollView 的刷新状态 GlobalKey ，方便主动刷新使用
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIndicatorKey =
      new GlobalKey<NestedScrollViewRefreshIndicatorState>();

  ///滚动控制与监听
  final ScrollController scrollController = new ScrollController();

  ///bloc
  final TrendBloc trendBloc = new TrendBloc();

  ///显示刷新
  _showRefreshLoading() {
    new Future.delayed(const Duration(seconds: 0), () {
      refreshIndicatorKey.currentState.show().then((e) {});
      return true;
    });
  }

  scrollToTop() {
    if (scrollController.offset <= 0) {
      scrollController
          .animateTo(0,
              duration: Duration(milliseconds: 600), curve: Curves.linear)
          .then((_) {
        _showRefreshLoading();
      });
    } else {
      scrollController.animateTo(0,
          duration: Duration(milliseconds: 600), curve: Curves.linear);
    }
  }

  ///绘制tiem
  _renderItem(e) {
    ReposViewModel reposViewModel = ReposViewModel.fromTrendMap(e);
    return new ReposItem(reposViewModel, onPressed: () {
      NavigatorUtils.goReposDetail(
          context, reposViewModel.ownerName, reposViewModel.repositoryName);
    });
  }

  ///绘制头部可选item
  _renderHeader(Store<GSYState> store, Radius radius) {
    if (selectTime == null && selectType == null) {
      return Container();
    }
    return new GSYCardItem(
      color: store.state.themeData.primaryColor,
      margin: EdgeInsets.all(0.0),
      shape: new RoundedRectangleBorder(
        borderRadius: BorderRadius.all(radius),
      ),
      child: new Padding(
        padding:
            new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 5.0),
        child: new Row(
          children: <Widget>[
            _renderHeaderPopItem(selectTime.name, trendTime(context),
                (TrendTypeModel result) {
              if (trendBloc.isLoading) {
                Fluttertoast.showToast(
                    msg: GSYLocalizations.i18n(context).loading_text);
                return;
              }
              scrollController
                  .animateTo(0,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.bounceInOut)
                  .then((_) {
                setState(() {
                  selectTime = result;
                });
                _showRefreshLoading();
              });
            }),
            new Container(height: 10.0, width: 0.5, color: GSYColors.white),
            _renderHeaderPopItem(selectType.name, trendType(context),
                (TrendTypeModel result) {
              if (trendBloc.isLoading) {
                Fluttertoast.showToast(
                    msg: GSYLocalizations.i18n(context).loading_text);
                return;
              }
              scrollController
                  .animateTo(0,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.bounceInOut)
                  .then((_) {
                setState(() {
                  selectType = result;
                });
                _showRefreshLoading();
              });
            }),
          ],
        ),
      ),
    );
  }

  ///或者头部可选弹出item容器
  _renderHeaderPopItem(String data, List<TrendTypeModel> list,
      PopupMenuItemSelected<TrendTypeModel> onSelected) {
    return new Expanded(
      child: new PopupMenuButton<TrendTypeModel>(
        child: new Center(
            child: new Text(data, style: GSYConstant.middleTextWhite)),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return _renderHeaderPopItemChild(list);
        },
      ),
    );
  }

  ///或者头部可选弹出item
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

  Future<void> requestRefresh() async {
    return trendBloc.requestRefresh(selectTime, selectType);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    if (!trendBloc.requested) {
      setState(() {
        selectTime = trendTime(context)[0];
        selectType = trendType(context)[0];
      });
      _showRefreshLoading();
    }
    super.didChangeDependencies();
  }

  ///空页面
  Widget _buildEmpty() {
    var statusBar =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.top;
    var bottomArea = MediaQueryData.fromWindow(WidgetsBinding.instance.window)
        .padding
        .bottom;
    var height = MediaQuery.of(context).size.height -
        statusBar -
        bottomArea -
        kBottomNavigationBarHeight -
        kToolbarHeight;
    return SingleChildScrollView(
      child: new Container(
        height: height,
        width: MediaQuery.of(context).size.width,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              onPressed: () {},
              child: new Image(
                  image: new AssetImage(GSYICons.DEFAULT_USER_ICON),
                  width: 70.0,
                  height: 70.0),
            ),
            Container(
              child: Text(GSYLocalizations.i18n(context).app_empty,
                  style: GSYConstant.normalText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return new Scaffold(
          backgroundColor: GSYColors.mainBackgroundColor,

          ///采用目前采用纯 bloc 的 rxdart(stream) + streamBuilder
          body: StreamBuilder<List<TrendingRepoModel>>(
              stream: trendBloc.stream,
              builder: (context, snapShot) {
                ///下拉刷新
                return new NestedScrollViewRefreshIndicator(
                  key: refreshIndicatorKey,

                  ///嵌套滚动
                  child: NestedScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return _sliverBuilder(context, innerBoxIsScrolled, store);
                    },
                    body: (snapShot.data == null || snapShot.data.length == 0)
                        ? _buildEmpty()
                        : new ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return _renderItem(snapShot.data[index]);
                            },
                            itemCount: snapShot.data.length,
                          ),
                  ),
                  onRefresh: requestRefresh,
                );
              }),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              NavigatorUtils.goTrendUserPage(context);
            },
            child: Icon(
              Icons.person,
              size: 30,
            ),
          ),
        );
      },
    );
  }

  ///嵌套可滚动头部
  List<Widget> _sliverBuilder(
      BuildContext context, bool innerBoxIsScrolled, Store store) {
    return <Widget>[
      ///动态头部
      SliverPersistentHeader(
        pinned: true,

        ///SliverPersistentHeaderDelegate 实现
        delegate: GSYSliverHeaderDelegate(
            maxHeight: 65,
            minHeight: 65,
            changeSize: true,
            snapConfig: FloatingHeaderSnapConfiguration(
              vsync: this,
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              ///根据数值计算偏差
              var lr = 10 - shrinkOffset / 65 * 10;
              var radius = Radius.circular(4 - shrinkOffset / 65 * 4);
              return SizedBox.expand(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: lr, bottom: 15, left: lr, right: lr),
                  child: _renderHeader(store, radius),
                ),
              );
            }),
      ),
    ];
  }
}

///趋势数据过滤显示item
class TrendTypeModel {
  final String name;
  final String value;

  TrendTypeModel(this.name, this.value);
}

///趋势数据时间过滤
trendTime(BuildContext context) {
  return [
    new TrendTypeModel(GSYLocalizations.i18n(context).trend_day, "daily"),
    new TrendTypeModel(GSYLocalizations.i18n(context).trend_week, "weekly"),
    new TrendTypeModel(GSYLocalizations.i18n(context).trend_month, "monthly"),
  ];
}

///趋势数据语言过滤
trendType(BuildContext context) {
  return [
    TrendTypeModel(GSYLocalizations.i18n(context).trend_all, null),
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
