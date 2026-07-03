import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/model/label.dart';

/// GitHub 官方彩色 label 徽章
///
/// 参考截图 2/3/4：`framework`（蓝底）、`engine`（橙底）、
/// `team-engine`（深绿底）、`triaged-design`（浅绿底）。
///
/// 颜色来源：`label.color` 为 6 位十六进制字符串（不含 #）。
/// 前景根据背景亮度自适应黑白，贴近 GitHub 网页效果。
class LabelChip extends StatelessWidget {
  final Label label;
  const LabelChip({super.key, required this.label});

  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFCCCCCC);
    var raw = hex.replaceAll('#', '').trim();
    if (raw.length == 3) {
      raw = raw.split('').map((c) => '$c$c').join();
    }
    if (raw.length != 6) return const Color(0xFFCCCCCC);
    final v = int.tryParse(raw, radix: 16);
    if (v == null) return const Color(0xFFCCCCCC);
    return Color(0xFF000000 | v);
  }

  static Color _foreground(Color bg) {
    // W3C 相对亮度，简单近似（使用 Flutter 新版归一化通道 r/g/b，取值域 [0,1]）
    final l = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b;
    return l > 0.6 ? const Color(0xFF1F2328) : const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseHex(label.color);
    final fg = _foreground(bg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.name ?? '',
        style: TextStyle(
          color: fg,
          fontSize: GSYConstant.smallTextSize,
          fontWeight: FontWeight.w500,
          height: 1.1,
        ),
      ),
    );
  }
}

/// 一组 label 的横向自适应容器
class LabelChipList extends StatelessWidget {
  final List<Label>? labels;
  const LabelChipList({super.key, this.labels});

  @override
  Widget build(BuildContext context) {
    final list = labels;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final l in list) LabelChip(label: l)],
      ),
    );
  }
}
