import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/search_history_repository.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/code_search_item.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/repository.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_item.dart';
import 'package:gsy_github_app_flutter/page/search/search_bloc.dart';
import 'package:gsy_github_app_flutter/page/search/widget/code_search_item_widget.dart';
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
  ///
  /// issue #942 双保险：即便 selectItemChanged 已经在切 tab 时
  /// clearData 抹掉旧类型残留，仍有一种"网络请求 late 回填"的场景可能
  /// 让 dataList 里混入非当前 tab 类型（例如 User tab 请求慢，回填时
  /// selectIndex 已经切到 Code）。这里对每个分支加 `is` 类型守卫，
  /// 遇到不匹配的元素直接渲染成空占位，绝不再走 `as` 强 cast。
  _renderItem(index) {
    var data = pullLoadWidgetControl.dataList[index];
    if (searchBLoC.selectIndex == 0) {
      if (data is! Repository) return const SizedBox.shrink();
      ReposViewModel reposViewModel = ReposViewModel.fromMap(data);
      return ReposItem(reposViewModel, onPressed: () {
        NavigatorUtils.goReposDetail(
            context, reposViewModel.ownerName, reposViewModel.repositoryName);
      });
    } else if (searchBLoC.selectIndex == 1) {
      if (data is! User) return const SizedBox.shrink();
      return UserItem(UserItemViewModel.fromMap(data), onPressed: () {
        NavigatorUtils.goPerson(
            context, UserItemViewModel.fromMap(data).userName);
      });
    } else if (searchBLoC.selectIndex == 2) {
      // Issue 搜索跨仓库，无法像仓库详情页那样传固定的 owner/repo，
      // 需要从每条 issue 的 repository_url 里 split 出 owner/repo。
      if (data is! Issue) return const SizedBox.shrink();
      final issue = data;
      final vm = IssueItemViewModel.fromMap(issue);
      final fullName = CommonUtils.getFullName(issue.repoUrl);
      return IssueItem(
        vm,
        onPressed: () {
          if (fullName.isEmpty) return;
          final parts = fullName.split('/');
          if (parts.length != 2) return;
          NavigatorUtils.goIssueDetail(
              context, parts[0], parts[1], vm.number);
        },
      );
    } else if (searchBLoC.selectIndex == 3) {
      // Code 搜索：GSY 定位是只读客户端，代码文件用内嵌 WebView 打开
      // html_url 展示，符合官方 GitHub App 的做法。
      if (data is! CodeSearchItem) return const SizedBox.shrink();
      final code = data;
      return CodeSearchItemWidget(
        code,
        onPressed: () {
          if (code.htmlUrl.isEmpty) return;
          CommonUtils.launchWebView(context, code.name, code.htmlUrl);
        },
      );
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
            selectIndex: searchBLoC.selectIndex,
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
                    // 无论有没有搜索词、正不正在加载，tab 切换本身必须先落到
                    // searchBLoC.selectIndex，否则用户"先切 tab 再输入"的自然
                    // 顺序会造成 UI 高亮和实际请求类型不一致（Issue tab 亮着
                    // 但实际发的是 repo 请求）。
                    final changed = searchBLoC.selectIndex != selectIndex;
                    searchBLoC.selectIndex = selectIndex;
                    // 抽屉是按 selectIndex 动态显示分段（隐藏 Code sort、隐藏
                    // User language），tab 一变必须触发 rebuild，否则抽屉里
                    // 拿到的还是旧 selectIndex，隐藏逻辑就错位了。
                    if (mounted) setState(() {});
                    // 没搜索词的话不需要发请求，等用户输入完再搜。
                    if (searchBLoC.searchText == null ||
                        searchBLoC.searchText?.trim().isEmpty == true) {
                      return;
                    }
                    // issue #942：快速切换 tab 会导致
                    // "type 'User' is not a subtype of type 'CodeSearchItem'"。
                    // 根因是原来这里 `if (isLoading) return;` 短路——上一次请求
                    // 还没结束时，selectIndex 已经变为新 tab（如 Code），但
                    // dataList 里还留着上一次 tab 的旧类型数据（如 User），
                    // _renderItem 就会用新 selectIndex 强 cast 旧类型崩溃。
                    // 修法：只要 tab 实际发生变化，就无条件 clearData +
                    // showRefreshLoading，把 dataList 立刻抹掉，避免混合类型。
                    if (changed) {
                      _resolveSelectIndex();
                      return;
                    }
                    if (isLoading) {
                      return;
                    }
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
            context.l10n.search_tab_issue,
            context.l10n.search_tab_code,
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

