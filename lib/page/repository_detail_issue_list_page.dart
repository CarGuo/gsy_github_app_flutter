import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/issue_dao.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_search_input_widget.dart';
import 'package:gsy_github_app_flutter/widget/issue_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/widget/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/nested/nested_refresh.dart';

/**
 * 仓库详情issue列表
 * Created by guoshuyu
 * Date: 2018-07-19
 */
class RepositoryDetailIssuePage extends StatefulWidget {
  final String userName;

  final String reposName;

  RepositoryDetailIssuePage(this.userName, this.reposName);

  @override
  _RepositoryDetailIssuePageState createState() =>
      _RepositoryDetailIssuePageState();
}

class _RepositoryDetailIssuePageState extends State<RepositoryDetailIssuePage>
    with
        AutomaticKeepAliveClientMixin<RepositoryDetailIssuePage>,
        GSYListState<RepositoryDetailIssuePage>,
        SingleTickerProviderStateMixin {
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIKey =
      new GlobalKey<NestedScrollViewRefreshIndicatorState>();

  String searchText;
  String issueState;
  int selectIndex;

  final ScrollController scrollController = new ScrollController();

  @override
  showRefreshLoading() {
    new Future.delayed(const Duration(seconds: 0), () {
      refreshIKey.currentState.show().then((e) {});
      return true;
    });
  }

  _renderEventItem(index) {
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
    scrollController
        .animateTo(0,
            duration: Duration(milliseconds: 100), curve: Curves.bounceIn)
        .then((_) {
      showRefreshLoading();
    });
  }

  _getDataLogic(String searchString) async {
    if (searchString == null || searchString.trim().length == 0) {
      return await IssueDao.getRepositoryIssueDao(
          widget.userName, widget.reposName, issueState,
          page: page, needDb: page <= 1);
    }
    return await IssueDao.searchRepositoryIssue(
        searchString, widget.userName, widget.reposName, this.issueState,
        page: this.page);
  }

  _createIssue() {
    String title = "";
    String content = "";
    CommonUtils.showEditDialog(
        context, CommonUtils.getLocale(context).issue_edit_issue, (titleValue) {
      title = titleValue;
    }, (contentValue) {
      content = contentValue;
    }, () {
      if (title == null || title.trim().length == 0) {
        Fluttertoast.showToast(
            msg: CommonUtils.getLocale(context)
                .issue_edit_issue_title_not_be_null);
        return;
      }
      if (content == null || content.trim().length == 0) {
        Fluttertoast.showToast(
            msg: CommonUtils.getLocale(context)
                .issue_edit_issue_content_not_be_null);
        return;
      }
      CommonUtils.showLoadingDialog(context);
      //提交修改
      IssueDao.createIssueDao(widget.userName, widget.reposName,
          {"title": title, "body": content}).then((result) {
        showRefreshLoading();
        Navigator.pop(context);
        Navigator.pop(context);
      });
    },
        needTitle: true,
        titleController: new TextEditingController(),
        valueController: new TextEditingController());
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
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      floatingActionButton: new Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  offset: Offset(0, 1),
                  color: Theme.of(context).primaryColorDark,
                  blurRadius: 1.0)
            ],
            color: Color(GSYColors.primaryValue),
            borderRadius: BorderRadius.all(Radius.circular(25))),
        child: InkWell(
          onTap: () {
            _createIssue();
          },
          child: new Icon(
            GSYICons.ISSUE_ITEM_ADD,
            size: 50.0,
            color: Color(GSYColors.textWhite),
          ),
        ),
      ),
      backgroundColor: Color(GSYColors.mainBackgroundColor),
      appBar: new AppBar(
        leading: new Container(),
        flexibleSpace: GSYSearchInputWidget((value) {
          this.searchText = value;
        }, (value) {
          _resolveSelectIndex();
        }, () {
          _resolveSelectIndex();
        }),
        elevation: 0.0,
        backgroundColor: Color(GSYColors.mainBackgroundColor),
      ),
      body: GSYNestedPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderEventItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIKey,
        scrollController: scrollController,
        headerSliverBuilder: (context, _) {
          return _sliverBuilder(context, _);
        },
      ),
    );
  }

  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    double height = 60;
    return <Widget>[
      ///动态放大缩小的选择案件
      SliverPersistentHeader(
        pinned: true,
        delegate: GSYSliverHeaderDelegate(
            maxHeight: height,
            minHeight: height,
            changeSize: true,
            snapConfig: FloatingHeaderSnapConfiguration(
              vsync: this,
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
                      CommonUtils.getLocale(context).repos_tab_issue_all,
                      CommonUtils.getLocale(context).repos_tab_issue_open,
                      CommonUtils.getLocale(context).repos_tab_issue_closed,
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
