import 'dart:async';

import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_refresh_sliver.dart'
    as IOS;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

import 'custom_bouncing_scroll_physics.dart';
import 'gsy_rive_pull_animation.dart';

const double iosRefreshHeight = 140;
const double iosRefreshIndicatorExtent = 100;

///通用下上刷新控件
class GSYPullLoadWidget extends StatefulWidget {
  ///item渲染
  final IndexedWidgetBuilder itemBuilder;

  ///加载更多回调
  final RefreshCallback? onLoadMore;

  ///下拉刷新回调
  final RefreshCallback? onRefresh;

  ///控制器，比如数据和一些配置
  final GSYPullLoadWidgetControl control;

  final ScrollController? scrollController;

  final bool userIos;

  ///刷新key
  final Key? refreshKey;

  const new(
      this.control, this.itemBuilder, this.onRefresh, this.onLoadMore,
      {super.key,
      this.refreshKey,
      this.scrollController,
      this.userIos = false});

  @override
  _GSYPullLoadWidgetState createState() => _GSYPullLoadWidgetState();
}

class _GSYPullLoadWidgetState extends State<GSYPullLoadWidget> {
  final GlobalKey<IOS.CupertinoSliverRefreshControlState> sliverRefreshKey =
      GlobalKey<IOS.CupertinoSliverRefreshControlState>();

  late ScrollController _scrollController;
  late bool _ownsScrollController;
  late GSYPullLoadWidgetControl _control;
  final Set<Timer> _pendingLoadChecks = {};
  final Map<Timer, Completer<bool>> _loadWaiters = {};
  int _controlGeneration = 0;

  bool isRefreshing = false;

  bool isLoadMoring = false;

  // 由外层 LayoutBuilder 记录的当前可用高度，供空态铺满整屏；
  // 旋转 / 分屏 / 折叠屏 posture 切换时 LayoutBuilder 会重建，自动跟着更新。
  double _availableHeight = 0;

  @override
  void initState() {
    super.initState();
    _bindScrollController();
    _control = widget.control;
    _control.addListener(_onControlChanged);
  }

  @override
  void didUpdateWidget(covariant GSYPullLoadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _cancelLoadChecks();
      _releaseScrollController();
      _bindScrollController();
    }
    if (_control != widget.control) {
      _cancelLoadChecks();
      _endControlBinding();
      _control.removeListener(_onControlChanged);
      _control = widget.control;
      _control.addListener(_onControlChanged);
    }
  }

  void _bindScrollController() {
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_checkLoadMore);
  }

  void _releaseScrollController() {
    _scrollController.removeListener(_checkLoadMore);
    // 2026-10-24 / FPR-105: a parent-supplied controller is borrowed, not
    // transferred. Only the fallback created by this State is ours to dispose.
    if (_ownsScrollController) _scrollController.dispose();
  }

  void _onControlChanged() {
    setState(() {});
    // Keep each existing two-second recheck, but cancel it when its list ends.
    late final Timer check;
    check = Timer(const Duration(seconds: 2), () {
      _pendingLoadChecks.remove(check);
      _checkLoadMore();
    });
    _pendingLoadChecks.add(check);
  }

  void _checkLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.hasContentDimensions &&
        position.pixels == position.maxScrollExtent &&
        _control.needLoadMore) {
      handleLoadMore();
    }
  }

  void _cancelLoadChecks() {
    for (final check in _pendingLoadChecks) {
      check.cancel();
    }
    _pendingLoadChecks.clear();
  }

  Future<bool> _waitForLoadCheck() {
    final completer = Completer<bool>();
    late final Timer wait;
    wait = Timer(const Duration(seconds: 1), () {
      _loadWaiters.remove(wait);
      completer.complete(true);
    });
    _loadWaiters[wait] = completer;
    return completer.future;
  }

  void _endControlBinding() {
    _controlGeneration++;
    for (final entry in _loadWaiters.entries) {
      entry.key.cancel();
      entry.value.complete(false);
    }
    _loadWaiters.clear();
    isRefreshing = false;
    isLoadMoring = false;
  }

  @override
  void dispose() {
    _cancelLoadChecks();
    _endControlBinding();
    _control.removeListener(_onControlChanged);
    _releaseScrollController();
    super.dispose();
  }

  ///根据配置状态返回实际列表数量
  ///实际上这里可以根据你的需要做更多的处理
  ///比如多个头部，是否需要空页面，是否需要显示加载更多。
  _getListCount() {
    ///是否需要头部
    if (widget.control.needHeader) {
      ///如果需要头部，用Item 0 的 Widget 作为ListView的头部
      ///列表数量大于0时，因为头部和底部加载更多选项，需要对列表数据总数+2
      return (widget.control.dataList!.isNotEmpty)
          ? widget.control.dataList!.length + 2
          : widget.control.dataList!.length + 1;
    } else {
      ///如果不需要头部，在没有数据时，固定返回数量1用于空页面呈现
      if (widget.control.dataList!.isEmpty) {
        return 1;
      }

      ///如果有数据,因为部加载更多选项，需要对列表数据总数+1
      return (widget.control.dataList!.isNotEmpty)
          ? widget.control.dataList!.length + 1
          : widget.control.dataList!.length;
    }
  }

  ///根据配置状态返回实际列表渲染Item
  _getItem(int index) {
    if (!widget.control.needHeader &&
        index == widget.control.dataList!.length &&
        widget.control.dataList!.isNotEmpty) {
      ///如果不需要头部，并且数据不为0，当index等于数据长度时，渲染加载更多Item（因为index是从0开始）
      return _buildProgressIndicator();
    } else if (widget.control.needHeader &&
        index == _getListCount() - 1 &&
        widget.control.dataList!.isNotEmpty) {
      ///如果需要头部，并且数据不为0，当index等于实际渲染长度 - 1时，渲染加载更多Item（因为index是从0开始）
      return _buildProgressIndicator();
    } else if (!widget.control.needHeader && widget.control.dataList!.isEmpty) {
      ///如果不需要头部，并且数据为0，渲染空页面
      return _buildEmpty();
    } else {
      ///回调外部正常渲染Item，如果这里有需要，可以直接返回相对位置的index
      return GSYAdaptiveNavigation.instance.wrapListChild(
        context: context,
        child: widget.itemBuilder(context, index),
      );
    }
  }

  @protected
  Future<void> handleRefresh() => _runLoad(refresh: true);

  @protected
  Future<void> handleLoadMore() => _runLoad(refresh: false);

  Future<void> _runLoad({required bool refresh}) async {
    if (refresh ? isRefreshing : isLoadMoring) return;
    final control = _control;
    final generation = _controlGeneration;
    final callback = refresh ? widget.onRefresh : widget.onLoadMore;
    if (refresh) {
      isRefreshing = true;
    } else {
      isLoadMoring = true;
    }
    var ownsLoad = false;
    try {
      while (control.isLoading) {
        if (!await _waitForLoadCheck()) return;
        if (!mounted || generation != _controlGeneration) return;
      }
      if (!mounted || generation != _controlGeneration) return;
      control.isLoading = true;
      ownsLoad = true;
      await callback?.call();
    } finally {
      // 2026-10-24 / FPR-105: a request belongs to the control captured before
      // awaiting. A late completion must never unlock its replacement control.
      if (ownsLoad) control.isLoading = false;
      if (generation == _controlGeneration) {
        if (refresh) {
          isRefreshing = false;
        } else {
          isLoadMoring = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 拿容器真实约束，避免直接读 MediaQuery.height 再硬减一个魔法常量：
        // 那种写法在小屏 / 横屏 / 分屏 / 折叠屏折叠态下都会算错。
        _availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        if (widget.userIos) {
          ///用ios模式的下拉刷新
          return NotificationListener(
            onNotification: (ScrollNotification notification) {
              ///通知 CupertinoSliverRefreshControl 当前的拖拽状态
              sliverRefreshKey.currentState!
                  .notifyScrollNotification(notification);
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,

              ///回弹效果
              physics: const CustomBouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                  refreshHeight: iosRefreshHeight),
              slivers: <Widget>[
                ///控制显示刷新的 CupertinoSliverRefreshControl
                IOS.CupertinoSliverRefreshControl(
                  key: sliverRefreshKey,
                  refreshIndicatorExtent: iosRefreshIndicatorExtent,
                  refreshTriggerPullDistance: iosRefreshHeight,
                  onRefresh: handleRefresh,
                  builder: buildSimpleRefreshIndicator,
                ),
                SliverSafeArea(
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _getItem(index);
                      },
                      childCount: _getListCount(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          ///GlobalKey，用户外部获取RefreshIndicator的State，做显示刷新
          key: widget.refreshKey,

          ///下拉刷新触发，返回的是一个Future
          onRefresh: handleRefresh,
          child: ListView.builder(
            ///保持ListView任何情况都能滚动，解决在RefreshIndicator的兼容问题。
            physics: const AlwaysScrollableScrollPhysics(),

            ///根据状态返回子孔健
            itemBuilder: (context, index) {
              return _getItem(index);
            },

            ///根据状态返回数量
            itemCount: _getListCount(),

            ///滑动监听
            controller: _scrollController,
          ),
        );
      },
    );
  }

  ///空页面
  Widget _buildEmpty() {
    return SizedBox(
      height: _availableHeight > 0
          ? _availableHeight
          : MediaQuery.sizeOf(context).height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(
            onPressed: () {},
            child: const Image(
                image: AssetImage(GSYICons.DEFAULT_USER_ICON),
                width: 70.0,
                height: 70.0),
          ),
          Text(context.l10n.app_empty, style: GSYConstant.normalText),
        ],
      ),
    );
  }

  ///上拉加载更多
  Widget _buildProgressIndicator() {
    ///是否需要显示上拉加载更多的loading
    Widget bottomWidget = (widget.control.needLoadMore)
        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            ///loading框
            SpinKitRotatingCircle(color: Theme.of(context).primaryColor),
            Container(
              width: 5.0,
            ),

            ///加载中文本
            Text(
              context.l10n.load_more_text,
              style: const TextStyle(
                color: Color(0xFF121917),
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            )
          ])

        /// 不需要加载
        : Container();
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: bottomWidget,
      ),
    );
  }

  Widget buildSimpleRefreshIndicator(
    BuildContext? context,
    IOS.RefreshIndicatorMode? refreshState,
    double? pulledExtent,
    double? refreshTriggerPullDistance,
    double? refreshIndicatorExtent,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black,
        width: MediaQuery.sizeOf(context!).width,

        ///动态大小处理
        height:
            pulledExtent! > iosRefreshHeight ? pulledExtent : iosRefreshHeight,
        // 2026-09-13: Same pull/refresh behavior, now using the migrated Rive asset.
        child: GSYRivePullAnimation(
          pulledExtent: pulledExtent,
          refreshTriggerPullDistance: iosRefreshHeight,
          playAuto: refreshState == IOS.RefreshIndicatorMode.refresh,
        ),
      ),
    );
  }
}

class GSYPullLoadWidgetControl extends ChangeNotifier {
  ///数据，对齐增减，不能替换
  final List _dataList = [];

  List? get dataList => _dataList;

  set dataList(List? value) {
    _dataList.clear();
    if (value != null) {
      _dataList.addAll(value);
      notifyListeners();
    }
  }

  addList(List? value) {
    if (value != null) {
      _dataList.addAll(value);
      notifyListeners();
    }
  }

  ///是否需要加载更多
  bool _needLoadMore = true;

  set needLoadMore(value) {
    _needLoadMore = value;
    notifyListeners();
  }

  get needLoadMore => _needLoadMore;

  ///是否需要头部
  bool _needHeader = true;

  set needHeader(value) {
    _needHeader = value;
    notifyListeners();
  }

  get needHeader => _needHeader;

  ///是否加载中
  bool isLoading = false;
}
