import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
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
  int page = 1;

  _renderItem(ReposViewModel e) {
    return new ReposItem(e, onPressed: () {
      NavigatorUtils.goReposDetail(context, e.ownerName, e.repositoryName);
    });
  }

  @override
  requestRefresh() async {
    return await ReposDao.getTrendDao(since: 'daily');
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
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return GSYPullLoadWidget(
      pullLoadWidgetControl,
      (BuildContext context, int index) => _renderItem(pullLoadWidgetControl.dataList[index]),
      handleRefresh,
      onLoadMore,
      refreshKey: refreshIndicatorKey,
    );
  }
}
