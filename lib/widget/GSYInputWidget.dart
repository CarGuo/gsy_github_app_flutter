import 'package:flutter/material.dart';

/// 带图标的输入框
class GSYInputWidget extends StatefulWidget {
  final bool obscureText;

  final String hintText;

  final IconData iconData;

  final ValueChanged<String> onChanged;

  final TextStyle textStyle;

  final TextEditingController controller;

  GSYInputWidget({Key key, this.hintText, this.iconData, this.onChanged, this.textStyle, this.controller, this.obscureText = false}) : super(key: key);

  @override
  _GSYInputWidgetState createState() => new _GSYInputWidgetState(hintText, iconData, onChanged, textStyle, controller, obscureText);
}

/// State for [GSYInputWidget] widgets.
class _GSYInputWidgetState extends State<GSYInputWidget> {
  final bool obscureText;

  final String hintText;

  final IconData iconData;

  final ValueChanged<String> onChanged;

  final TextStyle textStyle;

  final TextEditingController controller;

  _GSYInputWidgetState(this.hintText, this.iconData, this.onChanged, this.textStyle, this.controller, this.obscureText) : super();

  @override
  Widget build(BuildContext context) {
    return new TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: new InputDecoration(
        hintText: hintText,
        icon: iconData == null ? null : new Icon(iconData),
      ),
    );
  }
}
