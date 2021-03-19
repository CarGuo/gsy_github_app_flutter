import 'package:flutter/material.dart';

///动画大小变化打开的路由
class SizeRoute extends PageRouteBuilder {
  final Widget? widget;

  SizeRoute({this.widget})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              widget!,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            var begin = 0.0;
            var end = 1.0;
            var curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return Align(
              child: SizeTransition(
                sizeFactor: animation.drive(tween),
                child: child,
              ),
            );
          },
        );
}

class NoAnimationRoute extends PageRouteBuilder {
  final Widget? widget;

  NoAnimationRoute({this.widget})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              widget!,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              new SlideTransition(
            position: new Tween<Offset>(
              begin: const Offset(0.0, 0.0),
              end: const Offset(0.0, 0.0),
            ).animate(animation),
            child: child,
          ),
        );
}
