import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/logger.dart';
import 'package:gsy_github_app_flutter/page/dynamic/dynamic_bloc.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_group_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_new_load_widget.dart';
import 'package:redux/redux.dart';

/// 主页动态tab页
/// Created by guoshuyu
/// Date: 2018-07-16
class DynamicPage extends StatefulWidget {
  const DynamicPage({super.key});

  @override
  DynamicPageState createState() => DynamicPageState();
}

class DynamicPageState extends State<DynamicPage>
    with AutomaticKeepAliveClientMixin<DynamicPage>, WidgetsBindingObserver {
  final DynamicBloc dynamicBloc = DynamicBloc();

  ///控制列表滚动和监听
  final ScrollController scrollController = ScrollController();

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _ignoring = true;

  /// 模拟IOS下拉显示刷新
  showRefreshLoading() {
    ///直接触发下拉
    Future.delayed(const Duration(milliseconds: 500), () {
      scrollController
          .animateTo(-141,
              duration: const Duration(milliseconds: 600), curve: Curves.linear)
          .then((_) {
        /*setState(() {
          _ignoring = false;
        });*/
      });
      return true;
    });
  }

  scrollToTop() {
    if (scrollController.offset <= 0) {
      scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 600), curve: Curves.linear)
          .then((_) {
        showRefreshLoading();
      });
    } else {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 600), curve: Curves.linear);
    }
  }

  ///下拉刷新数据
  Future<void> requestRefresh() async {
    await dynamicBloc
        .requestRefresh(_getStore().state.userInfo?.login)
        .catchError((e) {
      printLog(e);
    });
    setState(() {
      _ignoring = false;
    });
  }

  ///上拉更多请求数据
  Future<void> requestLoadMore() async {
    return await dynamicBloc.requestLoadMore(_getStore().state.userInfo?.login);
  }

  _renderEventItem(Event e) {
    EventViewModel eventViewModel = EventViewModel.fromEventMap(context, e);
    return GSYEventItem(
      eventViewModel,
      onPressed: () {
        EventUtils.ActionUtils(context, e, "");
      },
    );
  }

  /// 按连续同一 actor 折叠事件后的列表渲染。
  /// - 每次 build 都基于当前 dataList 重新计算 spans；ChangeNotifier 触发 rebuild
  ///   时（下拉刷新 / load more）会自然对齐分组结果。
  /// - group.length >= 2 时 headIndex 渲染 [GSYEventGroupItem]，被吞掉的后续 index
  ///   返回 [SizedBox.shrink]，避免动 [_getListCount] 的语义。
  Widget _renderItemWithGroup(
      int index, Map<int, EventGroupSpan> spans, List<dynamic> dataList) {
    if (spans.containsKey(index)) {
      final span = spans[index]!;
      return GSYEventGroupItem(
        span,
        key: ValueKey<String>('group_${span.stableKey}'),
      );
    }
    if (isConsumedGroupIndex(index, spans)) {
      return const SizedBox.shrink();
    }
    return _renderEventItem(dataList[index] as Event);
  }

  Store<GSYState> _getStore() {
    return StoreProvider.of(context);
  }

  @override
  void initState() {
    super.initState();

    ///监听生命周期，主要判断页面 resumed 的时候触发刷新
    WidgetsBinding.instance.addObserver(this);

    ///获取网络端新版信息
    ReposRepository.getNewsVersion(context, false);
  }

  @override
  void didChangeDependencies() {
    ///请求更新
    if (dynamicBloc.getDataLength() == 0) {
      dynamicBloc.changeNeedHeaderStatus(false);

      ///先读数据库
      dynamicBloc
          .requestRefresh(_getStore().state.userInfo?.login, doNextFlag: false)
          .then((_) {
        showRefreshLoading();
      });
    }
    super.didChangeDependencies();
  }

  ///监听生命周期，主要判断页面 resumed 的时候触发刷新
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (dynamicBloc.getDataLength() != 0) {
        showRefreshLoading();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    dynamicBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    var content = GSYPullLoadWidget(
      dynamicBloc.pullLoadWidgetControl,
      (BuildContext context, int index) {
        /// 每次 itemBuilder 调用重新扫描一次 spans。分页大小 30，
        /// 扫描是 O(n)，反查 [isConsumedGroupIndex] 最坏 O(spans)，
        /// 单次列表滚动整体仍是 O(n)，可接受。
        /// 这里没有把 spans 提到父级 build，是为了不额外挂
        /// [GSYPullLoadWidgetControl] 的 listener——加载更多 / 刷新已经
        /// 会让 [GSYPullLoadWidget] 内部 rebuild，itemBuilder 会重跑，
        /// 从而拿到最新的 dataList。
        final List data = dynamicBloc.dataList;
        final spans = buildEventGroupSpans(data);
        return _renderItemWithGroup(index, spans, data);
      },
      requestRefresh,
      requestLoadMore,
      refreshKey: refreshIndicatorKey,
      scrollController: scrollController,

      ///使用ios模式的下拉刷新
      userIos: true,
    );
    return IgnorePointer(
      ignoring: _ignoring,
      child: content,
    );
  }
}
