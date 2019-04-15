import 'package:flutter/material.dart';

/**
 * 带图标Icon的文本，可调节
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class GSYIConText extends StatelessWidget {
  final String iconText;

  final IconData iconData;

  final TextStyle textStyle;

  final Color iconColor;

  final double padding;

  final double iconSize;

  final VoidCallback onPressed;

  final MainAxisAlignment mainAxisAlignment;

  final MainAxisSize mainAxisSize;

  final CrossAxisAlignment crossAxisAlignment;

  final double textWidth;

  GSYIConText(
    this.iconData,
    this.iconText,
    this.textStyle,
    this.iconColor,
    this.iconSize, {
    this.padding = 0.0,
    this.onPressed,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textWidth = -1,
  });

  @override
  Widget build(BuildContext context) {
    Widget showText = (textWidth == -1)
        ? new Text(
            iconText,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )
        : new Container(
            width: textWidth,
            child:

                ///显示数量文本
                new Text(
              iconText,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ));

    return new Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        new Icon(
          iconData,
          size: iconSize,
          color: iconColor,
        ),
        new Padding(padding: new EdgeInsets.all(padding)),
        new Expanded(child: showText)
      ],
    );
  }
}
