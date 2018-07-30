import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCommonOptionWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYSelectItemWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/widget/ReleaseItem.dart';

/**
 * 版本页
 * Created by guoshuyu
 * Date: 2018-07-30
 */

class ReleasePage extends StatefulWidget {
  final String userName;

  final String reposName;

  ReleasePage(this.userName, this.reposName);

  @override
  _ReleasePageState createState() => _ReleasePageState(this.userName, this.reposName);
}

// ignore: mixin_inherits_from_not_object
class _ReleasePageState extends GSYListState<ReleasePage> {
  final String userName;

  final String reposName;

  int selectIndex;

  _ReleasePageState(this.userName, this.reposName);

  _renderEventItem(index) {
    ReleaseItemViewModel releaseItemViewModel = pullLoadWidgetControl.dataList[index];
    return new ReleaseItem(
      releaseItemViewModel,
      onPressed: () {},
      onLongPress: () {},
    );
  }

  _resolveSelectIndex() {
    clearData();
    showRefreshLoading();
  }

  _getDataLogic() async {
    return await ReposDao.getRepositoryReleaseDao(userName, reposName, page, needHtml: false, release: selectIndex == 0);
  }

  @override
  bool get wantKeepAlive => false;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => true;

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    String url = Address.hostWeb + userName + "/" + reposName + "/releases";
    return new Scaffold(
      backgroundColor: Color(GSYColors.mainBackgroundColor),
      appBar: new AppBar(
        title: GSYTitleBar(
          reposName,
          rightWidget: new GSYCommonOptionWidget(url),
        ),
        bottom: new GSYSelectItemWidget(
          [
            GSYStrings.release_tab_release,
            GSYStrings.release_tab_tag,
          ],
          (selectIndex) {
            this.selectIndex = selectIndex;
            _resolveSelectIndex();
          },
          height: 30.0,
          margin: const EdgeInsets.all(0.0),
          elevation: 0.0,
        ),
        elevation: 4.0,
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderEventItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
