import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gsy_github_app_flutter/model/trending_repo_model.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_provider.dart';
import 'package:gsy_github_app_flutter/page/trend/trend_user_page.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_sliver_header_delegate.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/nested_refresh.dart';
import 'package:gsy_github_app_flutter/page/repos/widget/repos_item.dart';
import 'package:lottie/lottie.dart';

/// 主页趋势tab页
/// 目前采用纯 bloc 的 rxdart(stream) + streamBuilder
/// Created by guoshuyu
/// Date: 2018-07-16
class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  TrendPageState createState() => TrendPageState();
}

class TrendPageState extends ConsumerState<TrendPage>
    with
        AutomaticKeepAliveClientMixin<TrendPage>,
        SingleTickerProviderStateMixin {
  ///显示数据时间
  TrendTypeModel? selectTime;
  int selectTimeIndex = 0;

  ///显示过滤语言
  TrendTypeModel? selectType;
  int selectTypeIndex = 0;

  /// NestedScrollView 的刷新状态 GlobalKey ，方便主动刷新使用
  final GlobalKey<NestedScrollViewRefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<NestedScrollViewRefreshIndicatorState>();

  ///滚动控制与监听
  final ScrollController scrollController = ScrollController();

  ///显示刷新
  _showRefreshLoading() {
    Future.delayed(const Duration(seconds: 0), () {
      refreshIndicatorKey.currentState!.show().then((e) {});
      return true;
    });
  }

  scrollToTop() {
    if (scrollController.offset <= 0) {
      scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 600), curve: Curves.linear)
          .then((_) {
        _showRefreshLoading();
      });
    } else {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 600), curve: Curves.linear);
    }
  }

  ///绘制tiem
  _renderItem(e) {
    ReposViewModel reposViewModel = ReposViewModel.fromTrendMap(e);
    return OpenContainer(
      closedColor: Colors.transparent,
      closedElevation: 0,
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext context, VoidCallback _) {
        return NavigatorUtils.pageContainer(
            RepositoryDetailPage(
                reposViewModel.ownerName!, reposViewModel.repositoryName!),
            context);
      },
      tappable: true,
      closedBuilder: (BuildContext _, VoidCallback openContainer) {
        return ReposItem(reposViewModel, onPressed: null);
      },
    );
  }

  ///绘制头部可选item
  _renderHeader(Radius radius) {
    if (selectTime == null && selectType == null) {
      return Container();
    }
    var trendTimeList = trendTime(context);
    var trendTypeList = trendType(context);
    return GSYCardItem(
      color: ref.watch(appThemeStateProvider).primaryColor,
      margin: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(radius),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 5.0),
        child: Row(
          children: <Widget>[
            // 左边：时间维筛（今日 / 本周 / 本月）— 用 access_time icon 强化"时间"语义
            _renderHeaderPopItem(
                selectTime!.name, trendTimeList, Icons.access_time,
                (TrendTypeModel result) {
              if (trendLoadingState) {
                showToast(context.l10n.loading_text);
                return;
              }
              scrollController
                  .animateTo(0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.bounceInOut)
                  .then((_) {
                setState(() {
                  selectTime = result;
                  selectTimeIndex = trendTimeList.indexOf(result);
                });
                _showRefreshLoading();
              });
            }),
            Container(height: 10.0, width: 0.5, color: GSYColors.white),
            // 右边：语言维筛（所有语言 / Java / Kotlin / …）— 用 code icon 强化"编程语言"语义
            // 之前默认文案是"全部"，与时间维的"今日"放一起容易被误解成两个都是时间维度，
            // 现在文案改成"所有语言" + 图标双重区分。
            _renderHeaderPopItem(
                selectType!.name, trendTypeList, Icons.code,
                (TrendTypeModel result) {
              if (trendLoadingState) {
                showToast(context.l10n.loading_text);
                return;
              }
              scrollController
                  .animateTo(0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.bounceInOut)
                  .then((_) {
                setState(() {
                  selectType = result;
                  selectTypeIndex = trendTypeList.indexOf(result);
                });
                _showRefreshLoading();
              });
            }),
          ],
        ),
      ),
    );
  }

  ///或者头部可选弹出item容器
  _renderHeaderPopItem(String data, List<TrendTypeModel> list, IconData icon,
      PopupMenuItemSelected<TrendTypeModel> onSelected) {
    return Expanded(
      child: PopupMenuButton<TrendTypeModel>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return _renderHeaderPopItemChild(list);
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: GSYColors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data,
                  style: GSYConstant.middleTextWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down,
                  size: 18, color: GSYColors.white),
            ],
          ),
        ),
      ),
    );
  }

  ///或者头部可选弹出item
  _renderHeaderPopItemChild(List<TrendTypeModel> data) {
    List<PopupMenuEntry<TrendTypeModel>> list = [];
    for (TrendTypeModel item in data) {
      list.add(PopupMenuItem<TrendTypeModel>(
        value: item,
        child: Text(item.name),
      ));
    }
    return list;
  }

  Future<void> requestRefresh() async {
    var _ = ref.refresh(trendFirstProvider(selectTime?.value, selectType?.value));
    await ref.read(trendFirstProvider(selectTime?.value, selectType?.value).future);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    if (!trendRequestedState) {
      setState(() {
        selectTime = trendTime(context)[0];
        selectType = trendType(context)[0];
      });
      _showRefreshLoading();
    } else {
      if (selectTimeIndex >= 0) {
        selectTime = trendTime(context)[selectTimeIndex];
      }
      if (selectTypeIndex >= 0) {
        selectType = trendType(context)[selectTypeIndex];
      }
      setState(() {});
    }
    super.didChangeDependencies();
  }

  ///空页面
  Widget _buildEmpty() {
    var mediaQueryData = MediaQueryData.fromView(View.of(context));
    var statusBar = mediaQueryData.padding.top;
    var bottomArea = mediaQueryData.padding.bottom;
    var height = MediaQuery.sizeOf(context).height -
        statusBar -
        bottomArea -
        kBottomNavigationBarHeight -
        kToolbarHeight;
    return SingleChildScrollView(
      child: SizedBox(
        height: height,
        width: MediaQuery.sizeOf(context).width,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.

    ///展示非注解的 riverpod 并且配置先后顺序
    return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
      final firstAsync =
          ref.watch(trendFirstProvider(selectTime?.value, selectType?.value));
      final secondAsync = ref
          .watch(trendSecondProvider(selectTime?.value, selectType?.value));
      var result = secondAsync.value?.data as List<TrendingRepoModel>? ??
          firstAsync.value?.data as List<TrendingRepoModel>?;

      return Scaffold(
        backgroundColor: GSYColors.mainBackgroundColor,
        body: NestedScrollViewRefreshIndicator(
          key: refreshIndicatorKey,
          onRefresh: requestRefresh,

          ///嵌套滚动
          child: NestedScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return _sliverBuilder(context, innerBoxIsScrolled);
            },
            body: (result == null || result.isEmpty)
                ? _buildEmpty()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _renderItem(result[index]);
                    },
                    itemCount: result.length,
                  ),
          ),
        ),
        floatingActionButton: trendUserButton(),
      );
    });
  }

  trendUserButton() {
    const double size = 56.0;
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext context, VoidCallback _) {
        return NavigatorUtils.pageContainer(const TrendUserPage(), context);
      },
      closedElevation: 6.0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(size / 2),
        ),
      ),
      closedColor: Theme.of(context).primaryColor,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return SizedBox(
          width: size,
          height: size,
          child: Lottie.asset("static/file/user.json", fit: BoxFit.cover),
        );
      },
    );
  }

  ///嵌套可滚动头部
  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    return <Widget>[
      ///动态头部
      SliverPersistentHeader(
        pinned: true,

        ///SliverPersistentHeaderDelegate 实现
        delegate: GSYSliverHeaderDelegate(
            maxHeight: 65,
            minHeight: 65,
            changeSize: true,
            vSyncs: this,
            snapConfig: FloatingHeaderSnapConfiguration(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 10),
            ),
            builder: (BuildContext context, double shrinkOffset,
                bool overlapsContent) {
              ///根据数值计算偏差
              var lr = 10 - shrinkOffset / 65 * 10;
              var radius = Radius.circular(4 - shrinkOffset / 65 * 4);
              return SizedBox.expand(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: lr, bottom: 15, left: lr, right: lr),
                  child: _renderHeader(radius),
                ),
              );
            }),
      ),
    ];
  }
}

///趋势数据过滤显示item
class TrendTypeModel {
  final String name;
  final String? value;

  TrendTypeModel(this.name, this.value);
}

///趋势数据时间过滤
List<TrendTypeModel> trendTime(BuildContext context) {
  return [
    TrendTypeModel(context.l10n.trend_day, "daily"),
    TrendTypeModel(context.l10n.trend_week, "weekly"),
    TrendTypeModel(context.l10n.trend_month, "monthly"),
  ];
}

///趋势数据语言过滤
List<TrendTypeModel> trendType(BuildContext context) {
  return [
    TrendTypeModel(context.l10n.trend_all_languages, null),
    TrendTypeModel("Java", "Java"),
    TrendTypeModel("Kotlin", "Kotlin"),
    TrendTypeModel("Dart", "Dart"),
    TrendTypeModel("Objective-C", "Objective-C"),
    TrendTypeModel("Swift", "Swift"),
    TrendTypeModel("JavaScript", "JavaScript"),
    TrendTypeModel("PHP", "PHP"),
    TrendTypeModel("Go", "Go"),
    TrendTypeModel("C++", "C++"),
    TrendTypeModel("C", "C"),
    TrendTypeModel("HTML", "HTML"),
    TrendTypeModel("CSS", "CSS"),
    TrendTypeModel("Python", "Python"),
    TrendTypeModel("C#", "c%23"),
  ];
}
