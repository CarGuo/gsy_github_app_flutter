import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_sponsors_provider.g.dart';

/// 单个 sponsor 的最小视图模型
///
/// GitHub Sponsors 的 `Sponsor` 是 `User | Organization` union，本 view model 只
/// 存 login/avatarUrl（够渲染横向头像圆图 + 点击跳转），不做类型区分，跳转统一
/// 走 [NavigatorUtils.goPerson]：GSY 侧无独立 organization profile 页，User 与
/// Organization 走同一个 [PersonPage] 就能兼容。
class UserSponsorViewModel {
  final String? login;
  final String? avatarUrl;

  UserSponsorViewModel({this.login, this.avatarUrl});

  factory UserSponsorViewModel.fromMap(Map<String, dynamic> map) {
    return UserSponsorViewModel(
      login: map["login"] as String?,
      avatarUrl: map["avatarUrl"] as String?,
    );
  }
}

/// Sponsors 整块视图模型：总数 + 前 5 位头像
///
/// 页面层用 `totalCount == 0 || sponsors.isEmpty` 判断整块隐藏；`totalCount`
/// 与 sponsors.length 单独存放，因为 UI 会显示"共 N 位"小字，N 可能大于展示的
/// 5 个（例如 totalCount=42, sponsors.length=5）。
class UserSponsorsViewModel {
  final int totalCount;
  final List<UserSponsorViewModel> sponsors;

  UserSponsorsViewModel({
    this.totalCount = 0,
    this.sponsors = const [],
  });

  bool get isEmpty => totalCount <= 0 || sponsors.isEmpty;
}

/// 拉取指定用户 / 组织的 sponsors
///
/// - 与 [fetchUserPinnedItems] / [fetchUserStatus] 同构：plain `@riverpod` +
///   family + autoDispose，不加 `dependencies: []` scoped，因为 sponsors 只在
///   [PersonPage] 消费一次
/// - 失败或未启用 Sponsors 都返回 `UserSponsorsViewModel()` 空态（totalCount=0）；
///   UI 侧按整块 [SizedBox.shrink] 处理
/// - 不做 organization 短路：GraphQL 的 `user(login:)` 命中 Org 也能拿 sponsors
///   字段（Sponsors 面向 Org 开放），若 login 无效兜底成空态
@riverpod
Future<UserSponsorsViewModel> fetchUserSponsors(
    Ref ref, String userName) async {
  var res = await UserRepository.getUserSponsorsRequest(userName);
  if (res == null || res.result != true || res.data == null) {
    return UserSponsorsViewModel();
  }
  final map = Map<String, dynamic>.from(res.data as Map);
  final int totalCount = (map["totalCount"] as int?) ?? 0;
  final List rawNodes = map["nodes"] as List? ?? const [];
  final List<UserSponsorViewModel> sponsors = rawNodes
      .map((e) =>
          UserSponsorViewModel.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
  return UserSponsorsViewModel(
    totalCount: totalCount,
    sponsors: sponsors,
  );
}
