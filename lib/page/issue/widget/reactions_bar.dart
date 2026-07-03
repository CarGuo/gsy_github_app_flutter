import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/model/reactions.dart';

/// 展示并触发 issue / comment 的 reactions
///
/// 参考 GitHub 官方 UI（截图 4/5）：只展示 count > 0 的 emoji chip；
/// 点击 chip 会通过 [onToggle] 通知外部执行 add / remove。
///
/// 因为 REST 端点 POST 后返回该 reaction 的 id，删除需要用该 id；
/// 上层不需要在 chip 上追踪 id，直接调用 [onToggle]，外部按 (content, isAdd) 处理。
class ReactionsBar extends StatelessWidget {
  final Reactions reactions;

  /// 是否显示 "+" 添加入口
  final bool showAddEntry;

  /// 点击 chip 回调
  /// - [content] 官方 8 种之一：+1/-1/laugh/hooray/confused/heart/rocket/eyes
  /// - [isAdd]  true=添加，false=删除
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
                // 简单交互：点击已有 chip 视为再次 +1（GitHub 无法在无用户上下文
                // 判断本地当前用户是否已 react，这里退化为 add 语义）。
                onToggle!(e.content, true);
              },
        onLongPress: onToggle == null
            ? null
            : () {
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
  final VoidCallback? onLongPress;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
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
