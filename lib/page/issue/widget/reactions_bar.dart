import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/model/reactions.dart';

/// 展示并触发 issue / comment 的 reactions
///
/// 参考 GitHub 官方 UI（截图 4/5）：只展示 count > 0 的 emoji chip；
/// 点击 chip 会通过 [onToggle] 通知外部执行 add / remove。
///
/// 交互语义（对齐 GitHub 官方 web/mobile）：
/// - 点击「+」入口选一个 emoji = add
/// - 点击已有的 emoji chip = **toggle**（外部按当前用户是否已 react 决定加或删）
///
/// 为什么不用长按删除：Android 上 Comment 卡片自身也绑定了长按弹菜单（编辑/删除/
/// 复制），会吸掉 chip 的 long press，remove 路径永远走不到。改用「点已存在 chip
/// = toggle」既对齐官方，也避开手势冲突。
class ReactionsBar extends StatelessWidget {
  final Reactions reactions;

  /// 是否显示 "+" 添加入口
  final bool showAddEntry;

  /// 点击 chip 回调
  /// - [content] 官方 8 种之一：+1/-1/laugh/hooray/confused/heart/rocket/eyes
  /// - [isAdd]  true=添加，false=删除（点已存在 chip 走 false，"+"入口选一个走 true）
  final void Function(String content, bool isAdd)? onToggle;

  const ReactionsBar({
    super.key,
    required this.reactions,
    this.showAddEntry = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final e in reactions.entries) {
      if (e.count <= 0) continue;
      chips.add(_ReactionChip(
        emoji: e.emoji,
        count: e.count,
        onTap: onToggle == null
            ? null
            : () {
                // 点已存在 chip = 尝试 remove；上层若发现当前用户其实没 react
                // 过（GET 反查拿不到 reactionId），会降级为 add，实现 toggle
                // 语义。
                onToggle!(e.content, false);
              },
      ));
    }
    if (showAddEntry && onToggle != null) {
      chips.add(_AddReactionButton(onSelected: (c) => onToggle!(c, true)));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final VoidCallback? onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: GSYColors.subLightTextColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: GSYColors.subLightTextColor.withValues(alpha: 0.4),
              width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('$count', style: GSYConstant.smallSubText),
          ],
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const _AddReactionButton({required this.onSelected});

  static const _all = <MapEntry<String, String>>[
    MapEntry('+1', '👍'),
    MapEntry('-1', '👎'),
    MapEntry('laugh', '😄'),
    MapEntry('hooray', '🎉'),
    MapEntry('confused', '😕'),
    MapEntry('heart', '❤️'),
    MapEntry('rocket', '🚀'),
    MapEntry('eyes', '👀'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.issue_reactions_add_tooltip,
      onSelected: onSelected,
      itemBuilder: (ctx) => _all
          .map((e) => PopupMenuItem<String>(
                value: e.key,
                child: Row(children: [
                  Text(e.value, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(e.key),
                ]),
              ))
          .toList(),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: GSYColors.subLightTextColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: GSYColors.subLightTextColor.withValues(alpha: 0.4),
              width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_emotions_outlined,
                size: 14, color: GSYColors.subTextColor),
            const SizedBox(width: 4),
            Text('+', style: GSYConstant.smallSubText),
          ],
        ),
      ),
    );
  }
}
