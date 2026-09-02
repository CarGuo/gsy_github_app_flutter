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

  /// 命中区（tap target）最小边长。**默认 [kMinInteractiveDimension]（48dp）**——
  /// 无障碍红线优先：Material / iOS HIG 均要求可点击控件命中区不低于 48dp，
  /// 默认值 48dp 保证 widget 层"点得中"是**安全出厂设置**，不需要每个 caller 记着显式声明。
  ///
  /// 当 [onPressed] 非空且本字段非空时，命中区会外扩到
  /// `max(width/height, minTapTargetSize)`。视觉呈现仍严格按 [width]/[height]，
  /// 只有布局占位 / RawMaterialButton 的响应区域会被撑到 48dp。
  ///
  /// **稠密列表如何 opt-out**：
  /// 稠密列表（dynamic timeline / discussion 内嵌评论 / PR files inline
  /// comment），以及 Row 里**横排多头像**（用户主页组织横排 / 赞助者横排）
  /// 都属于稠密位——头像本就 20-36 dp，紧挨 `Expanded(Text)` 或彼此挤在
  /// 有限 Row 宽度里，默认外扩到 48 会挤压兄弟文本或让 Row 越界。
  /// 这类 caller **必须显式传 `minTapTargetSize: null`**，声明"我明确接受
  /// <48dp 的命中区以换布局稳定"。
  /// 参见 `docs/03-runbooks/dart-3.13-adoption.md` 的 D5 决策记录与 opt-out 名单。
  ///
  /// 使用：
  /// - 非稠密位（个人主页头像 / issue header / repos item 等）：**不传**，接受默认 48dp
  /// - 稠密位（timeline / 内嵌评论）：显式 `minTapTargetSize: null`，视觉==命中区==布局占位
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

    // 命中区尺寸：默认 minTapTargetSize=48（无障碍红线），有 onPressed 时外扩到
    // max(视觉尺寸, 48)。稠密列表 caller 需要显式传 minTapTargetSize:null 才 opt-out
    // 到"视觉==命中区==布局占位"的稠密档次；否则会挤压相邻 Expanded 文本。
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
