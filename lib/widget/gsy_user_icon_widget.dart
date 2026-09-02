import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/// 头像Icon
/// Created by guoshuyu
/// Date: 2018-07-30

class GSYUserIconWidget extends StatelessWidget {
  final String? image;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final EdgeInsetsGeometry? padding;

  /// 命中区（tap target）最小边长。**默认 null 表示视觉尺寸与命中区一致**——
  /// 沿用 GSY 从 2018 年就在用的隐式契约：`SizedBox(width, height)` 同时决定
  /// 视觉呈现和布局占位，caller 传多大就占多大。
  ///
  /// 只有在 [onPressed] 非空且本字段显式非空时，命中区才会外扩到
  /// `max(width/height, minTapTargetSize)`，用于**非 dense 列表**里的头像
  /// （比如个人中心大头像、单页详情大头像）满足 Material / iOS HIG 的 48dp 红线。
  ///
  /// **不默认设 48**（[kMinInteractiveDimension]）的原因：
  /// - 稠密列表（discussion / dynamic timeline）里的头像本就是 20-28 dp，
  ///   默认外扩到 48 会挤压相邻 Expanded 文本，引发布局回归
  /// - Material 官方对 dense list 的可访问性建议也是 40dp 而非 48dp
  /// - 无障碍下限由 caller 按语境显式声明，而不是 widget 层一刀切
  ///
  /// 使用：
  /// - 稠密列表 / timeline / 事件行：不传（默认 null），视觉==命中区
  /// - 单人卡片 / 用户中心 / 设置页大头像：显式传 [kMinInteractiveDimension]
  final double? minTapTargetSize;

  const GSYUserIconWidget(
      {super.key, this.image,
      this.onPressed,
      this.width = 30.0,
      this.height = 30.0,
      this.padding,
      this.minTapTargetSize});

  @override
  Widget build(BuildContext context) {
    // 用 URL 作为 FadeInImage 的 key：
    // 场景是列表 ListView 会复用同一个 Element 承载不同 item（A 头像 → B 头像）。
    // 当 URL 变化时，如果不 rebuild State，FadeInImage 内部会一直显示旧解码 frame，
    // 直到新图完全下载解码才切换——用户看到的就是"文本已经是 B 但头像还是 A 的老图"。
    // 加 ValueKey(url) 后 URL 变化就换新 State：立刻抛弃旧 stream，从 placeholder
    // 开始重新走 fade-in。URL 未变则 key 未变，widget identity 保留、不闪。
    final url = image ?? GSYICons.DEFAULT_REMOTE_PIC;

    // 视觉尺寸：ClipOval + FadeInImage 严格按 caller 指定的 width/height 呈现。
    final Widget visual = ClipOval(
      child: FadeInImage(
        key: ValueKey<String>(url),
        placeholder: const AssetImage(
          GSYICons.DEFAULT_USER_ICON,
        ),
        image: NetworkImage(url),
        //预览图
        fit: BoxFit.fitWidth,
        width: width,
        height: height,
      ),
    );

    // 命中区尺寸：仅在有 onPressed 且 caller 显式声明 minTapTargetSize 时才外扩。
    // 默认（minTapTargetSize=null）保留 GSY 2018 至今的隐式契约：视觉==命中区==布局占位，
    // 稠密列表里 20 dp 头像的 Row 占位就是 20 dp，兄弟 Expanded 文本可用宽度不被挤压。
    // 需要满足 48 dp 无障碍红线的大头像位由 caller 显式传入 kMinInteractiveDimension。
    final bool expandTapTarget =
        onPressed != null && minTapTargetSize != null;
    final double tapWidth = expandTapTarget
        ? (width > minTapTargetSize! ? width : minTapTargetSize!)
        : width;
    final double tapHeight = expandTapTarget
        ? (height > minTapTargetSize! ? height : minTapTargetSize!)
        : height;

    // 外层 Padding 承担"和相邻兄弟之间留白"的语义。原来传给
    // RawMaterialButton.padding 会同时撑大 button 尺寸让 tap 区域比头像多一圈——
    // 现在通过 minTapTargetSize 显式控制命中，语义清晰。
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 4.0, right: 5.0, left: 5.0),
      child: SizedBox(
        width: tapWidth,
        height: tapHeight,
        child: RawMaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
          onPressed: onPressed,
          child: Center(child: visual),
        ),
      ),
    );
  }
}
