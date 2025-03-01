import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/SearchUserQL.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_user_provider.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';

class TrendUserPage extends ConsumerStatefulWidget {
  const TrendUserPage({super.key});

  @override
  _TrendUserPageState createState() => _TrendUserPageState();
}

class _TrendUserPageState extends ConsumerState<TrendUserPage> {
  String? endCursor;

  _renderItem(SearchUserQL data, int index) {
    return UserItem(UserItemViewModel.fromQL(data, index + 1), onPressed: () {
      NavigatorUtils.goPerson(context, data.login);
    });
  }

  Future<void> loadData(WidgetRef ref, {bool isRefresh = false}) async {
    /// getTrendUserProvider 这里只有一处地方使用，所以不需要做局部单实例共享
    final result = await ref.read(
        searchTrendUserRequestProvider("China", isRefresh, cursor: endCursor)
            .future);
    if (result != null) {
      var (dataList, cursor) = result;
      endCursor = cursor;
    }
  }

  requestRefresh() async {
    endCursor = null;
    await loadData(ref, isRefresh: true);
  }

  requestLoadMore() async {
    await loadData(ref);
  }

  @override
  Widget build(BuildContext context) {
    var dataList = ref.watch(trendCNUserListProvider);
    return Scaffold(
        appBar: AppBar(
            title: Text(
          GSYLocalizations.i18n(context)!.trend_user_title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        body: EasyRefresh(
          header: const MaterialHeader(),
          footer: const BezierFooter(),
          refreshOnStart: true,
          onRefresh: requestRefresh,
          onLoad: requestLoadMore,
          child: ListView.builder(
            itemBuilder: (_, int index) => _renderItem(dataList[index], index),
            itemCount: dataList.length,
          ),
        ));
  }
}
