import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/model/User.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/common/redux/UserRedux.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

///通用下上刷新控件
class GSYPullLoadWidget extends StatefulWidget {
  ///item渲染
  final IndexedWidgetBuilder itemBuilder;

  ///加载更多回调
  final RefreshCallback onLoadMore;

  ///下拉刷新回调
  final RefreshCallback onRefresh;

  ///控制器，比如数据和一些配置
  final GSYPullLoadWidgetControl control;

  final Key refreshKey;

  GSYPullLoadWidget(this.control, this.itemBuilder, this.onRefresh, this.onLoadMore, {this.refreshKey});

  @override
  _GSYPullLoadWidgetState createState() => _GSYPullLoadWidgetState(this.control, this.itemBuilder, this.onRefresh, this.onLoadMore, this.refreshKey);
}

class _GSYPullLoadWidgetState extends State<GSYPullLoadWidget> {
  final IndexedWidgetBuilder itemBuilder;

  final RefreshCallback onLoadMore;

  final RefreshCallback onRefresh;

  final Key refreshKey;

  GSYPullLoadWidgetControl control;

  _GSYPullLoadWidgetState(this.control, this.itemBuilder, this.onRefresh, this.onLoadMore, this.refreshKey);

  final ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (this.onLoadMore != null && this.control.needLoadMore) {
          this.onLoadMore();
        }
      }
    });
    super.initState();
  }

  _getListCount() {
    if (control.needHeader) {
      return (control.dataList.length > 0) ? control.dataList.length + 2 : control.dataList.length + 1;
    } else {
      return (control.dataList.length > 0) ? control.dataList.length + 1 : control.dataList.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new RefreshIndicator(
      key: refreshKey,
      onRefresh: onRefresh,
      child: new ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (!control.needHeader && index == control.dataList.length && control.dataList.length != 0) {
            return _buildProgressIndicator();
          } else if (control.needHeader && index == _getListCount() - 1 && control.dataList.length != 0) {
            return _buildProgressIndicator();
          } else {
            return itemBuilder(context, index);
          }
        },
        itemCount: _getListCount(),
        controller: _scrollController,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    Widget bottomWidget = (control.needLoadMore) ? new CircularProgressIndicator() : new Text(GSYStrings.load_more_not);
    print(bottomWidget);
    return new Padding(
      padding: const EdgeInsets.all(20.0),
      child: new Center(
        child: bottomWidget,
      ),
    );
  }
}

class GSYPullLoadWidgetControl {
  ///数据，对齐增减，不能替换
  List dataList = new List();

  ///是否需要加载更多
  bool needLoadMore = true;

  ///是否需要头部
  bool needHeader = false;
}
