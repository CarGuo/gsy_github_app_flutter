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
  final double textWidth;

  static const TextStyle _baselineTextStyle = 
      TextStyle(textBaseline: TextBaseline.alphabetic);

  const GSYIConText(
    this.iconData,
    this.iconText,
    this.textStyle,
    this.iconColor,
    this.iconSize, {
    super.key,
    this.padding = 0.0,
    this.onPressed,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.textWidth = -1,
  });

  @override
  Widget build(BuildContext context) {
    final mergedTextStyle = textStyle.merge(_baselineTextStyle);
    
    final Widget showText = (textWidth == -1)
        ? Text(
            iconText ?? "",
            style: mergedTextStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )
        : SizedBox(
            width: textWidth,
            child: Text(
              iconText!,
              style: mergedTextStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );

    return Row(
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: <Widget>[
        Icon(
          iconData,
          size: iconSize,
          color: iconColor,
        ),
        if (padding > 0) Padding(padding: EdgeInsets.all(padding)),
        showText,
      ],
    );
  }
}
