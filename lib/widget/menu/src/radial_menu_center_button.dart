import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/widget/menu/src/radial_menu_button.dart';

const double _defaultButtonSize = 48.0;

/// The button at the center of a [RadialMenu] which controls its open/closed
/// state.
class RadialMenuCenterButton extends StatelessWidget {
  /// Drives the opening/closing animation of the [RadialMenu].
  final Animation<double> openCloseAnimationController;

  /// Drives the animation when an item in the [RadialMenu] is pressed.
  final Animation<double> activateAnimationController;

  /// Called when the user presses this button.
  final VoidCallback onPressed;

  /// The opened/closed state of the menu.
  ///
  /// Determines which of [closedColor] or [openedColor] should be used as the
  /// background color of the button.
  final bool isOpen;

  /// The color to use when painting the icon.
  ///
  /// Defaults to [Colors.black].
  final Color iconColor;

  /// Background color when it is in its closed state.
  ///
  /// Defaults to [Colors.white].
  final Color closedColor;

  /// Background color when it is in its opened state.
  ///
  /// Defaults to [Colors.grey].
  final Color openedColor;

  /// The size of the button.
  ///
  /// Defaults to 48.0.
  final double size;

  /// The animation progress for the [AnimatedIcon] in the center of the button.
  final Animation<double> _progress;

  /// The scale factor applied to the button.
  ///
  /// Animates from 1.0 to 0.0 when an an item is pressed in the menu and
  /// [activateAnimationController] progresses.
  final Animation<double> _scale;

  RadialMenuCenterButton({
    required this.openCloseAnimationController,
    required this.activateAnimationController,
    required this.onPressed,
    required this.isOpen,
    this.iconColor = Colors.black,
    this.closedColor = Colors.white,
    this.openedColor = Colors.grey,
    this.size = _defaultButtonSize,
  })  : _progress = new Tween(begin: 0.0, end: 1.0).animate(
          new CurvedAnimation(
            parent: openCloseAnimationController,
            curve: new Interval(
              0.0,
              0.5,
              curve: Curves.ease,
            ),
          ),
        ),
        _scale = new Tween(begin: 1.0, end: 0.0).animate(
          new CurvedAnimation(
            parent: activateAnimationController,
            curve: Curves.elasticIn,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final AnimatedIcon animatedIcon = new AnimatedIcon(
      color: iconColor,
      icon: AnimatedIcons.menu_close,
      progress: _progress,
    );

    final Widget child = new Container(
      width: size,
      height: size,
      child: new Center(
        child: animatedIcon,
      ),
    );

    final Color color = isOpen ? openedColor : closedColor;

    return new ScaleTransition(
      scale: _scale,
      child: new RadialMenuButton(
        child: child,
        backgroundColor: color,
        onPressed: onPressed,
      ),
    );
  }
}
