import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';

class TrendUserPage extends StatefulWidget {
  const TrendUserPage({super.key});

  @override
  _TrendUserPageState createState() => _TrendUserPageState();
}

class _TrendUserPageState extends State<TrendUserPage>
    with
        AutomaticKeepAliveClientMixin<TrendUserPage>,
        GSYListState<TrendUserPage> {
  String? endCursor;

  _renderItem(index) {
    if (pullLoadWidgetControl.dataList.isEmpty) {
      return null;
    }
    var data = pullLoadWidgetControl.dataList[index];
    return UserItem(UserItemViewModel.fromQL(data, index + 1), onPressed: () {
      NavigatorUtils.goPerson(context, data.login);
    });
  }

  _getDataLogic() async {
    return await UserRepository.searchTrendUserRequest("China", cursor: endCursor,
        valueChanged: (endCursor) {
      this.endCursor = endCursor;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
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
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(
        GSYLocalizations.i18n(context)!.trend_user_title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
