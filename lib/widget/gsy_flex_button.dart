import 'package:flutter/material.dart';

/**
 * 充满的button
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class GSYFlexButton extends StatelessWidget {
  final String? text;

  final Color? color;

  final Color textColor;

  final VoidCallback? onPress;

  final double fontSize;
  final int maxLines;

  final MainAxisAlignment mainAxisAlignment;

  GSYFlexButton(
      {Key? key,
      this.text,
      this.color,
      this.textColor = Colors.black,
      this.onPress,
      this.fontSize = 20.0,
      this.mainAxisAlignment = MainAxisAlignment.center,
      this.maxLines = 1})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new ElevatedButton(
        style: ButtonStyle(
          backgroundColor: ButtonStyleButton.allOrNull<Color>(
            color,
          ),
          textStyle: ButtonStyleButton.allOrNull<TextStyle>(
              new TextStyle(color: textColor)),
          padding: ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(
            new EdgeInsets.only(
                left: 20.0, top: 10.0, right: 20.0, bottom: 10.0),
          ),
        ),
        child: new Flex(
          mainAxisAlignment: mainAxisAlignment,
          direction: Axis.horizontal,
          children: <Widget>[
            new Expanded(
              child: new Text(text!,
                  style: new TextStyle(fontSize: fontSize),
                  textAlign: TextAlign.center,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis),
            )
          ],
        ),
        onPressed: () {
          this.onPress?.call();
        });
  }
}
