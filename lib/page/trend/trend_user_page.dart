import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/search_user_ql.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_user_provider.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';

class TrendUserPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  _TrendUserPageState createState() => _TrendUserPageState();
}

class _TrendUserPageState extends ConsumerState<TrendUserPage> {
  String? endCursor;

  ///记录一次 refresh 是否真的拿到了数据，配合 dataList 判空区分"还没请求过"
  ///与"请求完但空返回"两种态：前者显示 loading 占位交给 EasyRefresh 头本身；
  ///后者用 empty placeholder 兜底，避免用户看到纯白页面误以为 app 卡死。
  bool _hasLoadedOnce = false;

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
    if (mounted) {
      setState(() {
        _hasLoadedOnce = true;
      });
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
    // 页面 body 三档：
    // 1. 首次 refresh 还没结束（_hasLoadedOnce = false 且 dataList 空）：
    //    显示居中 CircularProgressIndicator。EasyRefresh 的
    //    refreshOnStart 触发时 MaterialHeader 并不会露头，如果 body 只放
    //    itemCount=0 的 ListView.builder，用户看到的就是**纯白页**——
    //    这正是 "页面转完页面空白" 的观感 root cause。
    // 2. 拉取完成但 provider 仍空（_hasLoadedOnce = true 且 dataList 空）：
    //    显示 app_empty 文案，告诉用户是"真的没数据"而不是 app 卡死；
    //    具体 GraphQL root cause 通过
    //    [UserRepository.searchTrendUserRequest] 的 talker.warning 分支
    //    日志在真机 stdout 定位（rate-limit / query 语义 / 网络挂三选一）。
    // 3. 拉到数据：正常 ListView.builder。
    final Widget body;
    if (dataList.isEmpty && !_hasLoadedOnce) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    } else if (dataList.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Center(
              child: Text(
                context.l10n.app_empty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      );
    } else {
      body = ListView.builder(
        itemBuilder: (_, int index) => _renderItem(dataList[index], index),
        itemCount: dataList.length,
      );
    }
    return Scaffold(
        appBar: AppBar(
            title: Text(
          context.l10n.trend_user_title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        body: EasyRefresh(
          header: const MaterialHeader(),
          footer: const BezierFooter(),
          refreshOnStart: true,
          onRefresh: requestRefresh,
          onLoad: requestLoadMore,
          child: body,
        ));
  }
}
