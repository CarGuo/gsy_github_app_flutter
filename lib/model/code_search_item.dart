/// GitHub `/search/code` 返回的单条命中。
///
/// 手写 fromJson 而不是 json_serializable，因为 code 搜索的字段用得少，
/// 不值得跑一次 build_runner；同时该 model 只在搜索页读取，不参与写回，
/// 保持轻量即可。
///
/// 字段来源：
/// - [name] / [path] / [htmlUrl]：直接来自顶层
/// - [repositoryFullName]：`repository.full_name`
/// - [repositoryOwnerAvatar]：`repository.owner.avatar_url`
class CodeSearchItem {
  final String name;
  final String path;
  final String htmlUrl;
  final String repositoryFullName;
  final String? repositoryOwnerAvatar;

  CodeSearchItem({
    required this.name,
    required this.path,
    required this.htmlUrl,
    required this.repositoryFullName,
    this.repositoryOwnerAvatar,
  });

  factory CodeSearchItem.fromJson(Map<String, dynamic> json) {
    final repo = (json['repository'] as Map?)?.cast<String, dynamic>() ?? {};
    final owner = (repo['owner'] as Map?)?.cast<String, dynamic>() ?? {};
    return CodeSearchItem(
      name: (json['name'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      htmlUrl: (json['html_url'] ?? '').toString(),
      repositoryFullName: (repo['full_name'] ?? '').toString(),
      repositoryOwnerAvatar: owner['avatar_url']?.toString(),
    );
  }
}
