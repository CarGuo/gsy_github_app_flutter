import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gsy_github_app_flutter/common/dao/issue_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/scoped_model/scoped_model.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/repos/scope/repos_detail_model.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_input_widget.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';


/**
 * 仓库详情issue列表
 * Created by guoshuyu
 * Date: 2018-07-19
 */
class RepositoryDetailIssuePage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  RepositoryDetailIssuePage(this.userName, this.reposName, {Key? super.key});

  @override
  RepositoryDetailIssuePageState createState() =>
      RepositoryDetailIssuePageState();
}

///页面 KeepAlive ，同时支持 动画Ticker
class RepositoryDetailIssuePageState extends State<RepositoryDetailIssuePage>
    with
        AutomaticKeepAliveClientMixin<RepositoryDetailIssuePage>,
        GSYListState<RepositoryDetailIssuePage>,
        SingleTickerProviderStateMixin {
  /// NestedScrollView 的刷新状态 GlobalKey ，方便主动刷新使用
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIKey =
      new GlobalKey<NestedScrollViewRefreshIndicatorState>();

  ///搜索 issue 文本
  String? searchText;

  ///过滤 issue 状态
  String? issueState;

  ///显示 issue 状态 tag index
  int? selectIndex;

  ///滑动控制器
  final ScrollController scrollController = new ScrollController();

  @override
  showRefreshLoading() {
    new Future.delayed(const Duration(seconds: 0), () {
      refreshIKey.currentState?.show().then((e) {});
      return true;
    });
  }

  ///绘制issue item
  _renderIssueItem(index) {
    IssueItemViewModel issueItemViewModel =
        IssueItemViewModel.fromMap(pullLoadWidgetControl.dataList[index]);
    return new IssueItem(
      issueItemViewModel,
      onPressed: () {
        NavigatorUtils.goIssueDetail(context, widget.userName, widget.reposName,
            issueItemViewModel.number);
      },
    );
  }

  ///切换显示状态
  _resolveSelectIndex() {
    clearData();
    switch (selectIndex) {
      case 0:
        issueState = null;
        break;
      case 1:
        issueState = 'open';
        break;
      case 2:
        issueState = "closed";
        break;
    }

    ///回滚到最初位置
    scrollController
        .animateTo(0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn)
        .then((_) {
      showRefreshLoading();
    });
  }

  ///获取数据
  _getDataLogic(String? searchString) async {
    if (searchString == null || searchString.trim().length == 0) {
      return await IssueDao.getRepositoryIssueDao(
          widget.userName, widget.reposName, issueState,
          page: page, needDb: page <= 1);
    }
    return await IssueDao.searchRepositoryIssue(
        searchString, widget.userName, widget.reposName, this.issueState,
        page: this.page);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => true;

  @override
  requestLoadMore() async {
    return await _getDataLogic(this.searchText);
  }

  @override
  requestRefresh() async {
    return await _getDataLogic(this.searchText);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return ScopedModelDescendant<ReposDetailModel>(
      builder: (context, child, model) {
        return new Scaffold(
          backgroundColor: GSYColors.mainBackgroundColor,
          appBar: new AppBar(
            leading: new Container(),
            flexibleSpace: (model?.repository?.hasIssuesEnabled == false)
                ? new Container()
                : GSYSearchInputWidget(onSubmitted: (value) {
                    this.searchText = value;
                    _resolveSelectIndex();
                  }, onSubmitPressed: () {
                    _resolveSelectIndex();
                  }),
            elevation: 0.0,
            backgroundColor: GSYColors.mainBackgroundColor,
          ),
          body: (model?.repository?.hasIssuesEnabled == false)
              ? new Container(
                  alignment: Alignment.center,
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () {},
                        child: new Image(
                            image: new AssetImage(GSYICons.DEFAULT_USER_ICON),
                            width: 70.0,
                            height: 70.0),
                      ),
                      Container(
                        child: Text(
                            GSYLocalizations.i18n(context)!
                                .repos_no_support_issue,
                            style: GSYConstant.normalText),
                      ),
                    ],
                  ),
                )

              ///支持嵌套滚动
              : GSYNestedPullLoadWidget(
                  pullLoadWidgetControl,
                  (BuildContext context, int index) => _renderIssueItem(index),
                  handleRefresh,
                  onLoadMore,
                  refreshKey: refreshIKey,
                  scrollController: scrollController,
                  headerSliverBuilder: (context, _) {
                    return _sliverBuilder(context, _);
                  },
                ),
        );
      },
    );
  }

  ///绘制内置Header，支持部分停靠支持
  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    double height = 60;
    return <Widget>[
      ///头部信息显示
      SliverPersistentHeader(
        pinned: true,

        /// SliverPersistentHeaderDelegate 的实现
        delegate: GSYSliverHeaderDelegate(
            maxHeight: height,
            minHeight: height,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              ///根据数值计算偏差
              var lr = 10 - shrinkOffset / height * 10;
              var radius = Radius.circular(4 - shrinkOffset / height * 4);
              return SizedBox.expand(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: lr, bottom: 10, left: lr, right: lr),
                  child: new GSYSelectItemWidget(
                    [
                      GSYLocalizations.i18n(context)!.repos_tab_issue_all,
                      GSYLocalizations.i18n(context)!.repos_tab_issue_open,
                      GSYLocalizations.i18n(context)!.repos_tab_issue_closed,
                    ],
                    (selectIndex) {
                      this.selectIndex = selectIndex;
                      _resolveSelectIndex();
                    },
                    margin: EdgeInsets.all(0.0),
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
