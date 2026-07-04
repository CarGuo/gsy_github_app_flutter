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

  const GSYUserIconWidget(
      {super.key, this.image,
      this.onPressed,
      this.width = 30.0,
      this.height = 30.0,
      this.padding});

  @override
  Widget build(BuildContext context) {
    // 用 URL 作为 FadeInImage 的 key：
    // 场景是列表 ListView 会复用同一个 Element 承载不同 item（A 头像 → B 头像）。
    // 当 URL 变化时，如果不 rebuild State，FadeInImage 内部会一直显示旧解码 frame，
    // 直到新图完全下载解码才切换——用户看到的就是"文本已经是 B 但头像还是 A 的老图"。
    // 加 ValueKey(url) 后 URL 变化就换新 State：立刻抛弃旧 stream，从 placeholder
    // 开始重新走 fade-in。URL 未变则 key 未变，widget identity 保留、不闪。
    final url = image ?? GSYICons.DEFAULT_REMOTE_PIC;
    return RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding:
            padding ?? const EdgeInsets.only(top: 4.0, right: 5.0, left: 5.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        onPressed: onPressed,
        child: ClipOval(
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
        ));
  }
}
