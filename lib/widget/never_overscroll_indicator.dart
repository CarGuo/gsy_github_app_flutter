import 'package:flutter/material.dart';

///去除ScrollView的Material效果
class NeverOverScrollIndicator extends StatelessWidget {
  final bool needOverload;

  final Widget? child;

  NeverOverScrollIndicator({this.child, this.needOverload = true});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      child: child!,
      behavior: NeverOverScrollBehavior(needOverload: needOverload),
    );
  }
}

class NeverOverScrollBehavior extends ScrollBehavior {
  final bool needOverload;

  NeverOverScrollBehavior({this.needOverload = true});

  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        if (needOverload) {
          return const BouncingScrollPhysics();
        }
        return const ClampingScrollPhysics();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      default:
        return const ClampingScrollPhysics();
    }
  }
}
