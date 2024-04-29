import 'package:flutter/material.dart';

/// 带图标的输入框
class GSYInputWidget extends StatefulWidget {
  final bool obscureText;

  final String? hintText;

  final IconData? iconData;

  final ValueChanged<String>? onChanged;

  final TextStyle? textStyle;

  final TextEditingController? controller;

  const GSYInputWidget(
      {super.key,
      this.hintText,
      this.iconData,
      this.onChanged,
      this.textStyle,
      this.controller,
      this.obscureText = false});

  @override
  _GSYInputWidgetState createState() => _GSYInputWidgetState();
}

/// State for [GSYInputWidget] widgets.
class _GSYInputWidgetState extends State<GSYInputWidget> {
  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          hintText: widget.hintText,
          icon: widget.iconData == null ? null : Icon(widget.iconData),
        ),
        magnifierConfiguration: TextMagnifierConfiguration(magnifierBuilder: (
          BuildContext context,
          MagnifierController controller,
          ValueNotifier<MagnifierInfo> magnifierInfo,
        ) {
          return null;
        }));
  }
}
