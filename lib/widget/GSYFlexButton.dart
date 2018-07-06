import 'package:flutter/material.dart';

class GSYFlexButton extends StatelessWidget {
  final String text;

  final Color color;

  final Color textColor;

  final VoidCallback onPress;

  GSYFlexButton({Key key, this.text, this.color, this.textColor, this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Row(children: <Widget>[
      new Expanded(
          child: new RaisedButton(
              padding: new EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0, bottom: 10.0),
              textColor: textColor,
              color: color,
              child: new Text(text, style: new TextStyle(fontSize: 20.0)),
              onPressed: () {
                if (this.onPress != null) {
                  this.onPress();
                }
              }))
    ]);
  }
}
