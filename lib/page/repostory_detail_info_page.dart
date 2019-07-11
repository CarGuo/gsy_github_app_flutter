import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/model/RepoCommit.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/repository_detail_page.dart';
import 'package:gsy_github_app_flutter/widget/event_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/widget/repos_header_item.dart';
import 'package:scoped_model/scoped_model.dart';

/**
 * 仓库详情动态信息页面
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class ReposDetailInfoPage extends StatefulWidget {
  final String userName;

  final String reposName;

  final OptionControl titleOptionControl;

  ReposDetailInfoPage(this.userName, this.reposName, this.titleOptionControl,
      {Key key})
      : super(key: key);

  @override
  ReposDetailInfoPageState createState() => ReposDetailInfoPageState();
}

///页面 KeepAlive ，同时支持 动画Ticker
class ReposDetailInfoPageState extends State<ReposDetailInfoPage>
    with
        AutomaticKeepAliveClientMixin<ReposDetailInfoPage>,
        GSYListState<ReposDetailInfoPage>,
        TickerProviderStateMixin {

  ///滑动监听
  final ScrollController scrollController = new ScrollController();

  ///当前显示tab
  int selectIndex = 0;

  ///初始化 header 默认大小，后面动态调整
  double headerSize = 270;

  /// NestedScrollView 的刷新状态 GlobalKey ，方便主动刷新使用
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIKey =
      new GlobalKey<NestedScrollViewRefreshIndicatorState>();

  ///动画控制器
  AnimationController animationController;


  @override
  showRefreshLoading() {
    new Future.delayed(const Duration(seconds: 0), () {
      refreshIKey.currentState.show().then((e) {});
      return true;
    });
  }

  ///渲染时间Item或者提交Item
  _renderEventItem(index) {
    if (selectIndex == 1) {
      ///提交
      return new EventItem(
        EventViewModel.fromCommitMap(pullLoadWidgetControl.dataList[index]),
        onPressed: () {
          RepoCommit model = pullLoadWidgetControl.dataList[index];
          NavigatorUtils.goPushDetailPage(
              context, widget.userName, widget.reposName, model.sha, false);
        },
        needImage: false,
      );
    }
    return new EventItem(
      EventViewModel.fromEventMap(pullLoadWidgetControl.dataList[index]),
      onPressed: () {
        EventUtils.ActionUtils(context, pullLoadWidgetControl.dataList[index],
            widget.userName + "/" + widget.reposName);
      },
    );
  }

  ///获取列表
  _getDataLogic() async {
    if (selectIndex == 1) {
      return await ReposDao.getReposCommitsDao(
        widget.userName,
        widget.reposName,
        page: page,
        branch: ReposDetailModel.of(context).currentBranch,
        needDb: page <= 1,
      );
    }
    return await ReposDao.getRepositoryEventDao(
      widget.userName,
      widget.reposName,
      page: page,
      branch: ReposDetailModel.of(context).currentBranch,
      needDb: page <= 1,
    );
  }

  ///获取详情
  _getReposDetail() {
    ReposDao.getRepositoryDetailDao(widget.userName, widget.reposName,
            ReposDetailModel.of(context).currentBranch)
        .then((result) {
      if (result != null && result.result) {
        setState(() {
          widget.titleOptionControl.url = result.data.htmlUrl;
        });
        ReposDetailModel.of(context).repository = result.data;
        return result.next();
      }
      return new Future.value(null);
    }).then((result) {
      if (result != null && result.result) {
        if (!isShow) {
          return;
        }
        setState(() {
          widget.titleOptionControl.url = result.data.htmlUrl;
        });
        ReposDetailModel.of(context).repository = result.data;
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    _getReposDetail();
    return await _getDataLogic();
  }

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  @override
  void initState() {
    super.initState();
    animationController = new AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScopedModelDescendant<ReposDetailModel>(
      builder: (context, child, model) {
        return GSYNestedPullLoadWidget(
          pullLoadWidgetControl,
          (BuildContext context, int index) => _renderEventItem(index),
          handleRefresh,
          onLoadMore,
          refreshKey: refreshIKey,
          scrollController: scrollController,
          headerSliverBuilder: (context, _) {
            return _sliverBuilder(context, _);
          },
        );
      },
    );
  }

  ///绘制内置Header，支持部分停靠支持
  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    return <Widget>[
      ///头部信息
      SliverPersistentHeader(
        delegate: GSYSliverHeaderDelegate(
          maxHeight: headerSize,
          minHeight: headerSize,
          snapConfig: FloatingHeaderSnapConfiguration(
            vsync: this,
            curve: Curves.bounceInOut,
            duration: const Duration(milliseconds: 10),
          ),
          child: new ReposHeaderItem(
            ReposHeaderViewModel.fromHttpMap(widget.userName, widget.reposName,
                ReposDetailModel.of(context).repository),
            layoutListener: (size) {
              setState(() {
                headerSize = size.height;
              });
            },
          ),
        ),
      ),

      ///动态放大缩小的tab控件
      SliverPersistentHeader(
        pinned: true,
        /// SliverPersistentHeaderDelegate 的实现
        delegate: GSYSliverHeaderDelegate(
            maxHeight: 60,
            minHeight: 60,
            changeSize: true,
            snapConfig: FloatingHeaderSnapConfiguration(
              vsync: this,
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              ///根据数值计算偏差
              var lr = 10 - shrinkOffset / 60 * 10;
              var radius = Radius.circular(4 - shrinkOffset / 60 * 4);
              return SizedBox.expand(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10, left: lr, right: lr),
                  child: new GSYSelectItemWidget(
                    [
                      CommonUtils.getLocale(context).repos_tab_activity,
                      CommonUtils.getLocale(context).repos_tab_commits,
                    ],
                    (index) {
                      ///切换时先滑动
                      scrollController
                          .animateTo(0,
                              duration: Duration(milliseconds: 200),
                              curve: Curves.bounceInOut)
                          .then((_) {
                        selectIndex = index;
                        clearData();
                        showRefreshLoading();
                      });
                    },
                    margin: EdgeInsets.zero,
                    shape: new RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(radius),
                    ),
                  ),
                ),
              );
            }),
      ),
    ];
  }
}
