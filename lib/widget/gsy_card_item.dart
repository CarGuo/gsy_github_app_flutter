import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/// Card Widget
/// Created by guoshuyu
/// Date: 2018-07-16
class GSYCardItem extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final Color color;
  final RoundedRectangleBorder shape;
  final double elevation;

  static const EdgeInsets _defaultMargin = 
      EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0);
  static const RoundedRectangleBorder _defaultShape = 
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  const GSYCardItem({
    super.key, 
    required this.child,
    this.margin = _defaultMargin,
    this.color = GSYColors.cardWhite,
    this.shape = _defaultShape,
    this.elevation = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: shape,
      color: color,
      margin: margin,
      child: child,
    );
  }
}
