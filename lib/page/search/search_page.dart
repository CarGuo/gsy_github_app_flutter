import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/search_history_repository.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/search/search_bloc.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_drawer.dart';
import 'package:gsy_github_app_flutter/page/search/widget/gsy_search_input_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_item.dart';
import 'package:gsy_github_app_flutter/page/user/widget/user_item.dart';

/// 搜索页面
/// Created by guoshuyu
/// on 2018/7/24.
class SearchPage extends StatefulWidget {
  final Offset centerPosition;

  const SearchPage(this.centerPosition, {super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with
        AutomaticKeepAliveClientMixin<SearchPage>,
        GSYListState<SearchPage>,
        SingleTickerProviderStateMixin {
  final SearchBLoC searchBLoC = SearchBLoC();

  late AnimationController controller;
  Animation? animation;
  bool endAnima = false;

  /// 搜索历史（本地持久化）
  ///
  /// 仅在数据列表为空 & 搜索框为空时以 chip 形式展示，
  /// 避免遮挡有效搜索结果。
  List<String> _history = const [];

  ///绘制item
  _renderItem(index) {
    var data = pullLoadWidgetControl.dataList[index];
    if (searchBLoC.selectIndex == 0) {
      ReposViewModel reposViewModel = ReposViewModel.fromMap(data);
      return ReposItem(reposViewModel, onPressed: () {
        NavigatorUtils.goReposDetail(
            context, reposViewModel.ownerName, reposViewModel.repositoryName);
      });
    } else if (searchBLoC.selectIndex == 1) {
      return UserItem(UserItemViewModel.fromMap(data), onPressed: () {
        NavigatorUtils.goPerson(
            context, UserItemViewModel.fromMap(data).userName);
      });
    }
  }

  ///切换tab
  _resolveSelectIndex() {
    clearData();
    showRefreshLoading();
  }

  ///获取搜索数据
  _getDataLogic() async {
    return await searchBLoC.getDataLogic(page);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => false;

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  _search() {
    if (searchBLoC.searchText == null ||
        searchBLoC.searchText?.trim().isEmpty == true) {
      return;
    }
    if (isLoading) {
      return;
    }
    _resolveSelectIndex();
    // 搜索请求完成后延后刷新历史 chip。请求路径见 [SearchBLoC.getDataLogic]，
    // 那里只在 page==1 且成功时写库，所以这里 delay 500ms 拉最新数据即可。
    Future.delayed(const Duration(milliseconds: 500), _loadHistory);
  }

  Future<void> _loadHistory() async {
    final list = await SearchHistoryRepository.load();
    if (!mounted) return;
    setState(() {
      _history = list;
    });
  }

  void _onHistoryTap(String query) {
    searchBLoC.textEditingController.text = query;
    searchBLoC.textEditingController.selection =
        TextSelection.collapsed(offset: query.length);
    _search();
  }

  Future<void> _onHistoryClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.l10n.search_history_clear_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.app_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.search_history_clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SearchHistoryRepository.clear();
    if (!mounted) return;
    setState(() {
      _history = const [];
    });
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInCubic,
    )..addListener(() {
        setState(() {});
      });

    Future.delayed(const Duration(seconds: 0), () {
      controller.forward().then((_) {
        setState(() {
          endAnima = true;
        });
      });
    });

    _loadHistory();
  }

  @override
  void dispose() {
    searchBLoC.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return Container(
      ///填充剩下半圆颜色
      color: endAnima ? Theme.of(context).primaryColor : Colors.transparent,
      child: CRAnimation(
        minR: MediaQuery.sizeOf(context).height - 8,
        maxR: 0,
        offset: widget.centerPosition,
        animation: animation as Animation<double>?,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          ///右侧 Drawer
          endDrawer: GSYSearchDrawer(
            (String? type) {
              ///排序类型
              searchBLoC.type = type;
              Navigator.pop(context);
              _resolveSelectIndex();
            },
            (String? sort) {
              ///排序状态
              searchBLoC.sort = sort;
              Navigator.pop(context);
              _resolveSelectIndex();
            },
            (String? language) {
              ///过滤语言
              searchBLoC.language = language;
              Navigator.pop(context);
              _resolveSelectIndex();
            },
          ),
          appBar: AppBar(
              leading: IconButton(
                highlightColor: Colors.transparent,
                icon: const BackButtonIcon(),
                onPressed: () {
                  setState(() {
                    endAnima = false;
                  });
                  controller.reverse().then((_) {
                    Navigator.maybePop(context);
                  });
                },
              ),
              title: Text(context.l10n.search_title),
              bottom: SearchBottom(
                  textEditingController: searchBLoC.textEditingController,
                  onSubmitted: (_) {
                    _search();
                  },
                  onSubmitPressed: () {
                    _search();
                  },
                  selectItemChanged: (selectIndex) {
                    if (searchBLoC.searchText == null ||
                        searchBLoC.searchText?.trim().isEmpty == true) {
                      return;
                    }
                    if (isLoading) {
                      return;
                    }
                    searchBLoC.selectIndex = selectIndex;
                    _resolveSelectIndex();
                  })),
          body: Stack(
            children: [
              GSYPullLoadWidget(
                pullLoadWidgetControl,
                (BuildContext context, int index) => _renderItem(index),
                handleRefresh,
                onLoadMore,
                refreshKey: refreshIndicatorKey,
              ),
              // 输入框空 & 数据列表空 时才显示搜索历史面板。
              // 一开始就有搜索结果或用户已在输入 → 直接透传给 GSYPullLoadWidget。
              if (pullLoadWidgetControl.dataList.isEmpty &&
                  (searchBLoC.searchText?.trim().isEmpty ?? true))
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: _SearchHistoryPanel(
                        history: _history,
                        onTap: _onHistoryTap,
                        onClear: _onHistoryClear,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

///实现 PreferredSizeWidget 实现自定义 appbar bottom 控件
class SearchBottom extends StatelessWidget implements PreferredSizeWidget {
  final SelectItemChanged? onSubmitted;

  final SelectItemChanged? selectItemChanged;

  final VoidCallback? onSubmitPressed;
  final TextEditingController? textEditingController;

  const SearchBottom(
      {super.key, this.onSubmitted,
      this.onSubmitPressed,
      this.selectItemChanged,
      this.textEditingController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GSYSearchInputWidget(
            controller: textEditingController,
            onSubmitted: onSubmitted,
            onSubmitPressed: onSubmitPressed),
        GSYSelectItemWidget(
          [
            context.l10n.search_tab_repos,
            context.l10n.search_tab_user,
          ],
          selectItemChanged,
          elevation: 0.0,
          margin: const EdgeInsets.all(5.0),
        )
      ],
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(100.0);
  }
}

class CRAnimation extends StatelessWidget {
  final Offset? offset;

  final double? minR;

  final double? maxR;

  final Widget child;

  final Animation<double>? animation;

  const CRAnimation({super.key, 
    required this.child,
    required this.animation,
    this.offset,
    this.minR,
    this.maxR,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation!,
      builder: (_, __) {
        return ClipPath(
          clipper: AnimationClipper(
            value: animation!.value,
            minR: minR,
            maxR: maxR,
            offset: offset,
          ),
          child: child,
        );
      },
    );
  }
}

class AnimationClipper extends CustomClipper<Path> {
  final double? value;

  final double? minR;

  final double? maxR;

  final Offset? offset;

  AnimationClipper({
    this.value,
    this.offset,
    this.minR,
    this.maxR,
  });

  @override
  bool shouldReclip(oldClipper) => true;

  @override
  Path getClip(Size size) {
    var path = Path();
    var offset = this.offset ?? Offset(size.width / 2, size.height / 2);

    var maxRadius = minR ?? radiusSize(size, offset);

    var minRadius = maxR ?? 0;

    var radius = lerpDouble(minRadius, maxRadius, value!)!;
    var rect = Rect.fromCircle(
      radius: radius,
      center: offset,
    );

    path.addOval(rect);
    return path;
  }

  double radiusSize(Size size, Offset offset) {
    final height = max(offset.dy, size.height - offset.dy);
    final width = max(offset.dx, size.width - offset.dx);
    return sqrt(width * width + height * height);
  }
}

/// 搜索历史 chip 面板。
///
/// 无历史 → 提示"输入关键字开始搜索"，避免出现空白面板让用户以为坏了。
/// 有历史 → 顶部标题 + 右上"清空"按钮 + Wrap 排列 chip。
/// 只做纯展示与回调，不持有任何持久化逻辑，方便被 review。
class _SearchHistoryPanel extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const _SearchHistoryPanel({
    required this.history,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.search_history_empty_hint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.search_history_title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(l10n.search_history_clear),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final q in history)
                  ActionChip(
                    label: Text(q),
                    onPressed: () => onTap(q),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

