import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_pinned_provider.g.dart';

/// User Profile "Pinned Repositories" 视图模型
///
/// 独立文件的原因：riverpod_generator 3.0.3 在同一个源文件同时存在
/// `@Riverpod(dependencies: [])` scoped provider 和 plain `@riverpod` 时，
/// AnalyzerBuffer 会踩到 AsyncValue 自动导入 bug（"Cannot find import for
/// AsyncValue"）。把 pinned 相关 provider 拆到独立文件后，本文件是纯 plain
/// `@riverpod` 场景，生成器可正常产出，不阻塞 build_runner。
///
/// pinnedItems query 为压缩载荷（[readUserPinnedItems]）刻意省略了
/// issues/topics/watchers/languages 等重字段，所以不复用 [RepositoryQL.fromMap]，
/// 而是就近提供一个精简视图模型。
class UserPinnedItemViewModel {
  final String? name;
  final String? nameWithOwner;
  final String? ownerLogin;
  final String? description;
  final int? stargazerCount;
  final int? forkCount;
  final String? primaryLanguageName;
  final String? primaryLanguageColorHex;
  final bool isFork;
  final bool isPrivate;

  UserPinnedItemViewModel({
    this.name,
    this.nameWithOwner,
    this.ownerLogin,
    this.description,
    this.stargazerCount,
    this.forkCount,
    this.primaryLanguageName,
    this.primaryLanguageColorHex,
    this.isFork = false,
    this.isPrivate = false,
  });

  factory UserPinnedItemViewModel.fromMap(Map<String, dynamic> map) {
    final owner = map["owner"];
    final language = map["primaryLanguage"];
    return UserPinnedItemViewModel(
      name: map["name"] as String?,
      nameWithOwner: map["nameWithOwner"] as String?,
      ownerLogin: owner is Map ? owner["login"] as String? : null,
      description: map["description"] as String?,
      stargazerCount: map["stargazerCount"] as int?,
      forkCount: map["forkCount"] as int?,
      primaryLanguageName:
          language is Map ? language["name"] as String? : null,
      primaryLanguageColorHex:
          language is Map ? language["color"] as String? : null,
      isFork: map["isFork"] == true,
      isPrivate: map["isPrivate"] == true,
    );
  }
}

/// 拉取指定用户/组织的 Pinned Repositories 视图模型列表
///
/// - 不加 `dependencies: []` scoped：pinned 数据只在 [PersonPage] 的一个 sliver
///   位置消费，没有必要像 [fetchHonorData] 那样通过 [OnlyShareInstanceWidget]
///   跨节点共享
/// - 用 family 承载 userName：切换到不同用户 profile 时自然生成不同 provider 实例
/// - 失败或空列表都返回空 `[]`，让 UI 侧统一按"无 pinned 隐藏整块"处理，避免
///   为组织类型或未设置 pinned 的用户显示空白标题
@riverpod
Future<List<UserPinnedItemViewModel>> fetchUserPinnedItems(
    Ref ref, String userName) async {
  var res = await UserRepository.getUserPinnedItemsRequest(userName);
  if (res == null || res.result != true) {
    return const <UserPinnedItemViewModel>[];
  }
  final List rawList = res.data as List? ?? const [];
  return rawList
      .map((e) => UserPinnedItemViewModel.fromMap(
          Map<String, dynamic>.from(e as Map)))
      .toList();
}
