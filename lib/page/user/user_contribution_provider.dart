import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_contribution_provider.g.dart';

/// 贡献日历里单日 cell 的最小视图模型
///
/// 字段：
/// - [date]: `YYYY-MM-DD` 格式，直接透传 GraphQL 返回值。存字符串而不是
///   [DateTime]：Tooltip 显示只需原文本，且避免时区转换带来的边界日抖动
/// - [contributionCount]: 该日贡献总数（commit + issue + PR + review）
/// - [color]: `#RRGGBB` 十六进制，GitHub GraphQL 已按 5 级 quartile 分配
///   （light 主题白背景 + 绿色阶梯）。UI 直接解析成 [Color]，不做二次映射
class ContributionDay {
  final String date;
  final int contributionCount;
  final String color;

  const ContributionDay({
    required this.date,
    required this.contributionCount,
    required this.color,
  });

  factory ContributionDay.fromMap(Map<String, dynamic> map) {
    return ContributionDay(
      date: (map["date"] as String?) ?? "",
      contributionCount: (map["contributionCount"] as int?) ?? 0,
      color: (map["color"] as String?) ?? "#ebedf0",
    );
  }
}

/// 贡献日历里一列（一周 7 天）
///
/// GraphQL 保证 `contributionDays` 至多 7 项、按周内顺序（周日开头）
/// 排列，但**首尾周可能不足 7 项**（例如 12 个月起始那周从周三开始）。
/// UI 侧渲染时按 index 直接落到 grid 上，缺失的 index 留空即可。
class ContributionWeek {
  final List<ContributionDay> contributionDays;

  const ContributionWeek({this.contributionDays = const []});

  factory ContributionWeek.fromMap(Map<String, dynamic> map) {
    final rawDays = map["contributionDays"];
    final List<ContributionDay> days = (rawDays is List)
        ? rawDays
            .whereType<Map>()
            .map((e) => ContributionDay.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : const [];
    return ContributionWeek(contributionDays: days);
  }
}

/// 贡献日历整块视图模型
///
/// - [totalContributions]: 近 12 个月贡献总数，UI 显示"共 N 次贡献"小字
/// - [weeks]: 约 52-53 项，每项一周；从左到右为时间正序
/// - [isEmpty]: 空态判定；组织账号 / 未启用 profile contributions 的用户
///   会得到 `totalContributions=0 && weeks 为空` 或 weeks 全 0 count
///   两种情况——UI 都按整块占位处理
class UserContributionCalendarViewModel {
  final int totalContributions;
  final List<ContributionWeek> weeks;

  const UserContributionCalendarViewModel({
    this.totalContributions = 0,
    this.weeks = const [],
  });

  bool get isEmpty => weeks.isEmpty;
}

/// 拉取指定用户的贡献日历（近 12 个月）
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] / [fetchUserSponsors]
///   同构：plain `@riverpod` + family + autoDispose，只在 [PersonPage]
///   消费一次
/// - 失败 / 空态都返回 [UserContributionCalendarViewModel] 空态；
///   UI 侧按占位 SizedBox 处理
/// - Organization 已在页面层短路，不会走到这里；若未来短路被拿掉，
///   repository 兜底会返回空 weeks，行为仍安全
@riverpod
Future<UserContributionCalendarViewModel> fetchUserContributionCalendar(
    Ref ref, String userName) async {
  var res = await UserRepository.getUserContributionCalendarRequest(userName);
  if (res == null || res.result != true || res.data == null) {
    return const UserContributionCalendarViewModel();
  }
  final map = Map<String, dynamic>.from(res.data as Map);
  final int totalContributions = (map["totalContributions"] as int?) ?? 0;
  final List rawWeeks = map["weeks"] as List? ?? const [];
  final List<ContributionWeek> weeks = rawWeeks
      .map((e) =>
          ContributionWeek.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
  return UserContributionCalendarViewModel(
    totalContributions: totalContributions,
    weeks: weeks,
  );
}
