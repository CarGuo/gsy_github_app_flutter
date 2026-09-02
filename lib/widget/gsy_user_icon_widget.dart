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

  /// 命中区（tap target）最小边长。视觉尺寸仍受 [width]/[height] 控制，
  /// 命中区仅在**存在 [onPressed]** 且 [width]/[height] 小于此值时才会外扩。
  ///
  /// 默认 [kMinInteractiveDimension] (48dp) 对齐 Material / iOS HIG 的
  /// 最小可点击尺寸红线。列表里的 20-36dp 小头像通过外扩命中区把 tap 面积
  /// 撑到 48×48，视觉呈现依然是 caller 指定的小尺寸——**视觉尺寸与命中区解耦**。
  ///
  /// 不外扩的两种情况：
  /// - [onPressed] 为 null：纯装饰头像，天然无需 tap target
  /// - [minTapTargetSize] 显式设为 null：命中区严格等于视觉尺寸，用于
  ///   **空间极度紧张**的可点击位置。显式设 null 是明确 opt-out 无障碍下限，
  ///   谨慎使用。
  final double? minTapTargetSize;

  const GSYUserIconWidget(
      {super.key, this.image,
      this.onPressed,
      this.width = 30.0,
      this.height = 30.0,
      this.padding,
      this.minTapTargetSize = kMinInteractiveDimension});

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

    // 命中区尺寸：仅在有 onPressed 且需要外扩时才扩，避免让纯装饰头像
    // 白白撑大兄弟 Expanded 的挤压面。
    // - onPressed=null：无 tap 语义，命中区 = 视觉尺寸
    // - onPressed!=null 且 minTapTargetSize!=null：命中区 = max(visual, minTap)
    //   目的是把"视觉呈现"和"命中区"两件事解耦——视觉可以是 20 dp 的小头像，
    //   命中区却撑到 48×48 满足 Material / iOS HIG 的可点击红线，
    //   避免上一轮 tight SizedBox 直接把命中区压到 20×20 造成无障碍回归。
    // - onPressed!=null 且 minTapTargetSize=null：caller 明确 opt-out 无障碍下限
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
