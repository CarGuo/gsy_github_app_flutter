import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/**
 * Card Widget
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class GSYCardItem extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final Color? color;
  final RoundedRectangleBorder? shape;
  final double elevation;

  GSYCardItem(
      {required this.child,
      this.margin,
      this.color,
      this.shape,
      this.elevation = 5.0});

  @override
  Widget build(BuildContext context) {
    EdgeInsets? margin = this.margin;
    RoundedRectangleBorder? shape = this.shape;
    Color? color = this.color;
    margin ??=
        EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0);
    shape ??= new RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4.0)));
    color ??= GSYColors.cardWhite;
    return new Card(
        elevation: elevation,
        shape: shape,
        color: color,
        margin: margin,
        child: child);
  }
}
