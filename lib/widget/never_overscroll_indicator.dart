import 'package:flutter/material.dart';

///去除ScrollView的Material效果
class NeverOverScrollIndicator extends StatelessWidget {
  final bool needOverload;

  final Widget? child;

  const NeverOverScrollIndicator({super.key, this.child, this.needOverload = true});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NeverOverScrollBehavior(needOverload: needOverload),
      child: child!,
    );
  }
}

class NeverOverScrollBehavior extends ScrollBehavior {
  final bool needOverload;

  const NeverOverScrollBehavior({this.needOverload = true});

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
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
