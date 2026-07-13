import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/user/user_pinned_provider.dart';

/// User Profile 页 "Pinned Repositories" 展示区域
///
/// 对齐 GitHub 官方 profile 顶部 pinned 卡片能力（AGENTS.md fixture 表已固化
/// CarGuo pinned 6 条作为冒烟数据源）。
///
/// 设计取舍：
/// - 与 [ReposItem](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/repos/widget/repos_item.dart)（trend / search 用的大卡片）不同，pinned 官方样式是紧凑窄卡片，
///   一屏可展示多张，因此这里自绘小卡片而不复用 ReposItem
/// - 不复用 [RepositoryQL.fromMap](file:///d:/workspace/project/gsy_github_app_flutter/lib/model/repository_ql.dart)：pinnedItems query 为压缩载荷刻意省略了
///   issues/topics/watchers/languages 等重字段，硬套 fromMap 会 NPE
/// - 点击跳转沿用 [NavigatorUtils.goReposDetail]，与全站仓库卡片交互一致
/// - 视图模型 [UserPinnedItemViewModel] 与 provider 共存于 [user_pinned_provider.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/user_pinned_provider.dart)，
///   本文件只负责 UI（避免 riverpod_generator 3.0.3 在混合 scoped/plain provider
///   同文件时的 AsyncValue 自动导入 bug）

/// Pinned 区域整块：标题 + 横向卡片列表
///
/// 用 [ConsumerWidget] 直接消费 [fetchUserPinnedItemsProvider]。
/// 上层通过 [key] 传入 userName 触发 provider family 命中。
class UserPinnedSection extends ConsumerWidget {
  final String userName;

  const UserPinnedSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(fetchUserPinnedItemsProvider(userName));

    return asyncValue.when(
      loading: () => _buildContainer(
        context,
        const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContainer(
          context,
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _PinnedCard(item: list[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContainer(BuildContext context, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 12.0),
          alignment: Alignment.topLeft,
          child: Text(
            context.l10n.user_pinned_title,
            style: GSYConstant.normalTextBold,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        child,
      ],
    );
  }
}

class _PinnedCard extends StatelessWidget {
  final UserPinnedItemViewModel item;

  const _PinnedCard({required this.item});

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var v = hex.startsWith("#") ? hex.substring(1) : hex;
    if (v.length == 6) v = "FF$v";
    final parsed = int.tryParse(v, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  String _formatCount(int? n) {
    if (n == null) return "0";
    if (n >= 1000) {
      return "${(n / 1000).toStringAsFixed(1)}k";
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final owner = item.ownerLogin;
    final repo = item.name;
    final langColor = _parseColor(item.primaryLanguageColorHex);

    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: GSYColors.subLightTextColor, width: 0.3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: (owner != null && repo != null)
              ? () => NavigatorUtils.goReposDetail(context, owner, repo)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(GSYICons.REPOS_ITEM_STAR,
                        size: 14, color: GSYColors.subTextColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.nameWithOwner ?? item.name ?? "---",
                        style: GSYConstant.smallTextBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isFork)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(GSYICons.REPOS_ITEM_FORK,
                            size: 12, color: GSYColors.subTextColor),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    item.description ?? "---",
                    style: GSYConstant.smallSubText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    if (item.primaryLanguageName != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: langColor ?? GSYColors.subLightTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(item.primaryLanguageName!,
                          style: GSYConstant.smallSubText),
                      const SizedBox(width: 10),
                    ],
                    const Icon(GSYICons.REPOS_ITEM_STAR,
                        size: 12, color: GSYColors.subTextColor),
                    const SizedBox(width: 2),
                    Text(_formatCount(item.stargazerCount),
                        style: GSYConstant.smallSubText),
                    const SizedBox(width: 10),
                    const Icon(GSYICons.REPOS_ITEM_FORK,
                        size: 12, color: GSYColors.subTextColor),
                    const SizedBox(width: 2),
                    Text(_formatCount(item.forkCount),
                        style: GSYConstant.smallSubText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
