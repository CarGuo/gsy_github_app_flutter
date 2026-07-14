import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/page/user/user_contribution_provider.dart';

/// User Profile 页 "贡献日历" 展示区域
///
/// 对齐 GitHub 官方 profile 页顶部的贡献热力图。设计取舍：
/// - 数据源从第三方 ghchart.rshah.org 的静态 SVG 切换到 GraphQL
///   `contributionsCollection.contributionCalendar`，拿到结构化的
///   `weeks[].contributionDays[]`（date + contributionCount + color）
/// - 前端自绘 heatmap（52 列 × 7 行 grid），每个 cell 用 [Tooltip] 包裹
///   ([triggerMode: TooltipTriggerMode.tap])，点击弹出"YYYY-MM-DD: N 次贡献"，
///   与 GitHub 官方 hover-tip 语义等价（手机上无 hover，用 tap 触发）
/// - 颜色直接用 GraphQL 返回的 hex，白主题 5 级绿阶梯，无需二次映射
/// - loading 走 [SpinKitRipple] 占位（与原 [UserHeaderChart._renderChart]
///   保持一致的用户体感）；error / 空态给一个提示条，不静默隐藏
///   （这块是官方 profile 的一等公民能力，隐藏会让用户以为页面坏了）
/// - 组织账号不挂载本 widget（由 [UserHeaderChart] 判 type == "Organization"
///   直接跳过，与旧 SVG 分支保持一致）
class UserContributionCalendarSection extends ConsumerWidget {
  final String userName;

  const UserContributionCalendarSection({super.key, required this.userName});

  /// heatmap cell 边长（dp），配合 [_cellGap] 决定整块宽度
  static const double _cellSize = 12.0;

  /// heatmap cell 间距（dp）
  static const double _cellGap = 3.0;

  /// 整块 heatmap 高度：7 行 * (cell + gap) - 最后一行不需要 gap
  static const double _gridHeight = 7 * _cellSize + 6 * _cellGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(fetchUserContributionCalendarProvider(userName));

    return asyncValue.when(
      loading: () => SizedBox(
        height: 140,
        child: Center(
          child: SpinKitRipple(color: Theme.of(context).primaryColor),
        ),
      ),
      error: (_, __) => SizedBox(
        height: 140,
        child: Center(
          child: Text(
            context.l10n.nothing_now,
            style: GSYConstant.smallSubText,
          ),
        ),
      ),
      data: (vm) {
        if (vm.isEmpty) {
          return SizedBox(
            height: 140,
            child: Center(
              child: Text(
                context.l10n.nothing_now,
                style: GSYConstant.smallSubText,
              ),
            ),
          );
        }
        return _buildCalendar(context, vm);
      },
    );
  }

  Widget _buildCalendar(
      BuildContext context, UserContributionCalendarViewModel vm) {
    final int weekCount = vm.weeks.length;
    // 每列宽度 = cell + gap，最后一列不加 gap
    final double gridWidth =
        weekCount * _cellSize + (weekCount - 1).clamp(0, weekCount) * _cellGap;

    return Card(
      margin: const EdgeInsets.only(
          top: 0.0, left: 10.0, right: 10.0, bottom: 0.0),
      color: GSYColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 头行：总数小字，与 UserSponsorsSection "共 N 位" 风格一致
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                context.l10n
                    .user_contributions_count(vm.totalContributions),
                style: GSYConstant.smallSubText,
              ),
            ),

            /// heatmap 主体：52 列 * 7 行 grid，横向可滚动
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              /// 从最右侧起（=最新一周）显示，与 GitHub 官方一致
              reverse: true,
              child: SizedBox(
                width: gridWidth,
                height: _gridHeight,
                child: _ContributionGrid(weeks: vm.weeks),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// heatmap 网格：52 列 × 7 行，每个 cell 是一个可点击的 [_ContributionCell]
class _ContributionGrid extends StatelessWidget {
  final List<ContributionWeek> weeks;

  const _ContributionGrid({required this.weeks});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: weeks
          .asMap()
          .entries
          .map((entry) {
            final int weekIndex = entry.key;
            final ContributionWeek week = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  right: weekIndex == weeks.length - 1
                      ? 0
                      : UserContributionCalendarSection._cellGap),
              child: _WeekColumn(week: week),
            );
          })
          .toList(),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  final ContributionWeek week;

  const _WeekColumn({required this.week});

  @override
  Widget build(BuildContext context) {
    // 一列 7 行；GraphQL 里 contributionDays 首尾周可能不足 7 项，
    // 用透明占位 cell 把缺失位补齐（与 GitHub 官方 grid 一致）
    final List<Widget> cells = [];
    for (int row = 0; row < 7; row++) {
      final Widget cell = (row < week.contributionDays.length)
          ? _ContributionCell(day: week.contributionDays[row])
          : const SizedBox(
              width: UserContributionCalendarSection._cellSize,
              height: UserContributionCalendarSection._cellSize,
            );
      cells.add(cell);
      if (row < 6) {
        cells.add(
            const SizedBox(height: UserContributionCalendarSection._cellGap));
      }
    }
    return Column(children: cells);
  }
}

class _ContributionCell extends StatelessWidget {
  final ContributionDay day;

  const _ContributionCell({required this.day});

  Color _parseHexColor(String hex) {
    // GitHub 返回 `#RRGGBB`；兜底空串或非法值给 GitHub 默认最浅灰
    var value = hex.replaceFirst('#', '');
    if (value.length != 6) {
      value = 'ebedf0';
    }
    return Color(int.parse('ff$value', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _parseHexColor(day.color);
    final String tooltip = day.contributionCount == 0
        ? '${day.date}: ${context.l10n.user_contributions_none}'
        : '${day.date}: ${context.l10n.user_contributions_count(day.contributionCount)}';

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      showDuration: const Duration(seconds: 2),
      child: Container(
        width: UserContributionCalendarSection._cellSize,
        height: UserContributionCalendarSection._cellSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
