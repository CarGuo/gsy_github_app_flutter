import 'package:flutter/material.dart';

/// 带图标Icon的文本，可调节
/// Created by guoshuyu
/// Date: 2018-07-16
class GSYIConText extends StatelessWidget {
  final String? iconText;

  final IconData iconData;

  final TextStyle textStyle;

  final Color iconColor;

  final double padding;

  final double iconSize;

  final VoidCallback? onPressed;

  final MainAxisAlignment mainAxisAlignment;

  final MainAxisSize mainAxisSize;

  /// Requested text width; a bounded parent can allocate less space.
  final double textWidth;

  const new(
    this.iconData,
    this.iconText,
    this.textStyle,
    this.iconColor,
    this.iconSize, {super.key, 
    this.padding = 0.0,
    this.onPressed,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.textWidth = -1,
  });

  @override
  Widget build(BuildContext context) {
    Widget showText = (textWidth == -1)
        ? Text(
          iconText ?? "",
          style: textStyle
              .merge(const TextStyle(textBaseline: TextBaseline.alphabetic)),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        )
        : SizedBox(
            width: textWidth,
            child:

                ///显示数量文本
                Text(
              iconText!,
              style: textStyle
                  .merge(const TextStyle(textBaseline: TextBaseline.alphabetic)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ));

    return LayoutBuilder(builder: (context, constraints) {
      // 2026-10-24 / FPR-108: ellipsis needs the space left by the icon,
      // not an unconstrained Row child. Counter rows also use this component
      // without a horizontal bound, where adding flex would be invalid.
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            iconData,
            size: iconSize,
            color: iconColor,
          ),
          Padding(padding: EdgeInsets.all(padding)),
          if (constraints.hasBoundedWidth)
            Flexible(child: showText)
          else
            showText,
        ],
      );
    });
  }
}
