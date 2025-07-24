import 'package:flutter/material.dart';

/// 带图标的输入框
class GSYInputWidget extends StatelessWidget {
  final bool obscureText;
  final String? hintText;
  final IconData? iconData;
  final ValueChanged<String>? onChanged;
  final TextStyle? textStyle;
  final TextEditingController? controller;

  static const TextMagnifierConfiguration _magnifierConfig = 
      TextMagnifierConfiguration(
        magnifierBuilder: _magnifierBuilder,
      );

  const GSYInputWidget({
    super.key,
    this.hintText,
    this.iconData,
    this.onChanged,
    this.textStyle,
    this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      style: textStyle,
      decoration: InputDecoration(
        hintText: hintText,
        icon: iconData != null ? Icon(iconData) : null,
      ),
      magnifierConfiguration: _magnifierConfig,
    );
  }

  static Widget? _magnifierBuilder(
    BuildContext context,
    MagnifierController controller,
    ValueNotifier<MagnifierInfo> magnifierInfo,
  ) {
    return null;
  }
}
