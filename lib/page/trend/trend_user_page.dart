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
    // 空状态兜底：数据加载完成（_hasLoadedOnce = true）但 provider 仍为空，
    // 说明本次拉取 GraphQL 返回空（rate-limit / query 语义变化 / 网络挂），
    // 展示占位文案 + 下拉刷新提示，避免用户看到"纯白页面"以为 app 挂了。
    // 具体 root cause 通过 [UserRepository.searchTrendUserRequest] 里
    // 的 talker.warning 分支日志定位。
    final Widget body = dataList.isEmpty && _hasLoadedOnce
        ? ListView(
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
          )
        : ListView.builder(
            itemBuilder: (_, int index) => _renderItem(dataList[index], index),
            itemCount: dataList.length,
          );
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
