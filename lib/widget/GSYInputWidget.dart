import 'package:flutter/material.dart';

/// 带图标的输入框
class GSYInputWidget extends StatefulWidget {

  final String hintText;

  final IconData iconData;

  GSYInputWidget({Key key, this.hintText, this.iconData}) : super(key: key);

  @override
  _GSYInputWidgetState createState() => new _GSYInputWidgetState(hintText, iconData);
}

/// State for [GSYInputWidget] widgets.
class _GSYInputWidgetState extends State<GSYInputWidget> {

  final String hintText;

  final IconData iconData;

  final TextEditingController _controller = new TextEditingController();

  _GSYInputWidgetState(this.hintText, this.iconData) : super();

  @override
  Widget build(BuildContext context) {
    return new TextField(
        controller: _controller,
        decoration: new InputDecoration(
          hintText: hintText,
          icon: new Icon(iconData),
        ),
      );
  }
}