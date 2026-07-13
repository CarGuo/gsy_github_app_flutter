import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/emoji_shortcode_map.dart';
import 'package:gsy_github_app_flutter/page/user/user_status_provider.dart';

/// User Profile 页 "Status" chip 展示区域
///
/// 对齐 GitHub 官方 profile 头像下方"状态胶囊"（emoji + message + 可选的
/// "Busy" 角标）。设计取舍：
/// - 结构与 [UserPinnedSection](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/user/widget/user_pinned.dart) 类似：ConsumerWidget + AsyncValue.when。
///   但空态处理更激进——status 是可选的一等公民、大多数用户未设置，
///   loading / error / empty 一律 `SizedBox.shrink`，不做占位 spinner，避免
///   在贡献图与 Pinned 之间闪一下就消失（pinned 是稳定占位所以 loading 用 spinner）
/// - 不承担 status 编辑能力：GSY 定位是"只读 + 评论"（见 AGENTS.md 允许/禁止
///   写操作清单），status 属于"作者行为"边缘的资料编辑，明确不做
/// - emoji 解析用 [resolveEmojiShortcode]：命中映射 → unicode；未命中 →
///   原始 shortcode（例 `:foo:`），保证不丢信息
class UserStatusSection extends ConsumerWidget {
  final String userName;

  const UserStatusSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(fetchUserStatusProvider(userName));

    return asyncValue.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vm) {
        if (vm == null) {
          return const SizedBox.shrink();
        }
        return _StatusChip(vm: vm);
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final UserStatusViewModel vm;

  const _StatusChip({required this.vm});

  @override
  Widget build(BuildContext context) {
    final emojiText = resolveEmojiShortcode(vm.emojiShortcode);
    final message = vm.message;

    return Container(
      margin: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GSYColors.subLightTextColor,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (emojiText != null) ...[
            Text(emojiText, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
          ],
          if (message != null && message.isNotEmpty)
            Flexible(
              child: Text(
                message,
                style: GSYConstant.smallTextBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (vm.isBusy) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Text(
                context.l10n.user_status_busy_label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
