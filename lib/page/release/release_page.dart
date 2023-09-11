import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/page/release/widget/release_item.dart';
import 'package:url_launcher/url_launcher.dart';

/**
 * 版本页
 * Created by guoshuyu
 * Date: 2018-07-30
 */

class ReleasePage extends StatefulWidget {
  final String? userName;

  final String? reposName;
  final String releaseUrl;
  final String tagUrl;

  ReleasePage(this.userName, this.reposName, this.releaseUrl, this.tagUrl);

  @override
  _ReleasePageState createState() => _ReleasePageState();
}

class _ReleasePageState extends State<ReleasePage>
    with AutomaticKeepAliveClientMixin<ReleasePage>, GSYListState<ReleasePage> {
  ///显示tag还是relase
  int selectIndex = 0;

  ///绘制item
  _renderEventItem(index) {
    ReleaseItemViewModel releaseItemViewModel =
        ReleaseItemViewModel.fromMap(pullLoadWidgetControl.dataList[index]);
    return new ReleaseItem(
      releaseItemViewModel,
      onPressed: () {
        ///没有 release 提示就不要了
        if (selectIndex == 0 &&
            releaseItemViewModel.actionTargetHtml != null &&
            releaseItemViewModel.actionTargetHtml!.length > 0) {
          String html = HtmlUtils.generateHtml(
              releaseItemViewModel.actionTargetHtml,
              backgroundColor: GSYColors.miWhiteString,
              userBR: false);
          CommonUtils.launchWebView(
              context, releaseItemViewModel.actionTitle, html);
        }
      },
      onLongPress: () {
        _launchURL();
      },
    );
  }

  ///打开外部url
  _launchURL() async {
    String url = _getUrl();
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Fluttertoast.showToast(
          msg: GSYLocalizations.i18n(context)!.option_web_launcher_error +
              ": " +
              url);
    }
  }

  String _getUrl() {
    return selectIndex == 0 ? widget.releaseUrl : widget.tagUrl;
  }

  _resolveSelectIndex() {
    clearData();
    showRefreshLoading();
  }

  _getDataLogic() async {
    return await ReposDao.getRepositoryReleaseDao(
        widget.userName, widget.reposName, page,
        needHtml: true, release: selectIndex == 0);
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
    return new Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      appBar: new AppBar(
        title: GSYTitleBar(
          widget.reposName,
          rightWidget: new GSYCommonOptionWidget(
            url: _getUrl(),
          ),
        ),
        bottom: new GSYSelectItemWidget(
          [
            GSYLocalizations.i18n(context)!.release_tab_release,
            GSYLocalizations.i18n(context)!.release_tab_tag,
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
