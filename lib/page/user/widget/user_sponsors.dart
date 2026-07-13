import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/user/user_sponsors_provider.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// User Profile 页 "Sponsors" 展示区域
///
/// 对齐 GitHub 官方 profile 页 pinned 附近的"Sponsors"栏（GitHub Sponsors 一等
/// 公民能力）。设计取舍：
/// - 结构与 [UserPinnedSection](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/widget/user_pinned.dart) 同构：ConsumerWidget + AsyncValue.when，
///   loading 走 `SizedBox.shrink` 而不是占位 spinner（sponsors 大多数用户未启用，
///   避免 pinned 与事件流之间闪一下就消失，语义与 [UserStatusSection](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/widget/user_status.dart) 一致）
/// - 头像使用现成 [GSYUserIconWidget](file:///d:/workspace/project/gsy_github_app_flutter/lib/widget/gsy_user_icon_widget.dart)：FadeInImage + ClipOval，已解决 URL
///   变更时的头像串图问题
/// - 点击头像走 [NavigatorUtils.goPerson]：GSY 侧 User 与 Organization profile
///   共享同一个 [PersonPage]，无需在此区分 sponsor 类型
/// - 不承担 sponsor 编辑 / mutation 能力（GSY 定位"只读+评论"，见 AGENTS.md
///   允许/禁止写操作清单）
class UserSponsorsSection extends ConsumerWidget {
  final String userName;

  const UserSponsorsSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(fetchUserSponsorsProvider(userName));

    return asyncValue.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vm) {
        if (vm.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContainer(context, vm);
      },
    );
  }

  Widget _buildContainer(BuildContext context, UserSponsorsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 12.0),
          alignment: Alignment.topLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                context.l10n.user_sponsors_title,
                style: GSYConstant.normalTextBold,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n
                    .user_sponsors_count(vm.totalCount),
                style: GSYConstant.smallSubText,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 4.0),
          child: Row(
            children: vm.sponsors
                .map(
                  (s) => _SponsorAvatar(
                    sponsor: s,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SponsorAvatar extends StatelessWidget {
  final UserSponsorViewModel sponsor;

  const _SponsorAvatar({required this.sponsor});

  @override
  Widget build(BuildContext context) {
    final login = sponsor.login;
    return GSYUserIconWidget(
      width: 36,
      height: 36,
      padding: const EdgeInsets.only(right: 8.0),
      image: sponsor.avatarUrl,
      onPressed: (login != null && login.isNotEmpty)
          ? () => NavigatorUtils.goPerson(context, login)
          : null,
    );
  }
}
