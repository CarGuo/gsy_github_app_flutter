import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_status_provider.g.dart';

/// User Profile "Status" 视图模型
///
/// 与 [UserPinnedItemViewModel] 同构：轻量、无 model 层入侵、就近放在 provider
/// 文件里，避免为一个一次性 UI chip 引入 `model/*.dart` + `*.g.dart` 一整套。
///
/// GitHub 返回的 emoji 是 shortcode（例如 `:tada:`），本 view model 层不做解析，
/// 交给 UI 层 [UserStatusSection] 通过 [emojiShortcodeMap] 转 unicode。
class UserStatusViewModel {
  /// GitHub 原始 shortcode，可能是 `:tada:` 或 `null`
  final String? emojiShortcode;

  /// 用户填写的状态文本，可能为 null 或空串
  final String? message;

  /// GitHub 官方 "Busy" 开关。为 true 时头像旁边会附加"忙碌中"角标
  final bool isBusy;

  UserStatusViewModel({
    this.emojiShortcode,
    this.message,
    this.isBusy = false,
  });

  /// 语义"用户其实没设置任何 status"，UI 直接 [SizedBox.shrink]
  bool get isEmpty =>
      (emojiShortcode == null || emojiShortcode!.isEmpty) &&
      (message == null || message!.isEmpty) &&
      !isBusy;

  factory UserStatusViewModel.fromMap(Map<String, dynamic> map) {
    return UserStatusViewModel(
      emojiShortcode: map["emoji"] as String?,
      message: map["message"] as String?,
      isBusy: map["indicatesLimitedAvailability"] == true,
    );
  }
}

/// 拉取指定用户的 status
///
/// - 与 [fetchUserPinnedItems] 同构：plain `@riverpod` + family + autoDispose，
///   不加 `dependencies: []` scoped，因为 status 只在 [PersonPage] 消费一次
/// - 失败或空 status 都返回 `null`；UI 侧统一按"隐藏整块"处理，避免为组织类型
///   或未设置 status 的用户显示空白 chip
/// - **不加 organization 短路**：调用侧 [BasePersonState] 已按
///   `login != null && login.isNotEmpty && type != "Organization"` 三段条件
///   挂载，若短路失效或未来被拿掉，organization login 走到这里 GraphQL 会
///   返回 `user: null`，本 provider 兜底成 `null`，UI 隐藏，无副作用
@riverpod
Future<UserStatusViewModel?> fetchUserStatus(
    Ref ref, String userName) async {
  var res = await UserRepository.getUserStatusRequest(userName);
  if (res == null || res.result != true) {
    return null;
  }
  if (res.data == null) {
    return null;
  }
  final vm = UserStatusViewModel.fromMap(
      Map<String, dynamic>.from(res.data as Map));
  return vm.isEmpty ? null : vm;
}
