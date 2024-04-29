import 'package:flutter/material.dart';

class RadialMenuButton extends StatelessWidget {
  const RadialMenuButton({super.key, 
    required this.child,
    this.backgroundColor,
    this.onPressed,
  });

  final Widget child;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color color = backgroundColor ?? Theme.of(context).primaryColor;

    return Semantics(
      button: true,
      enabled: true,
      child: Material(
        type: MaterialType.circle,
        color: color,
        child: InkWell(
          onTap: onPressed,
          child: child,
        ),
      ),
    );
  }
}
