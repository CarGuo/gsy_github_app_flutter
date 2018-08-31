import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double _defaultButtonSize = 48.0;

/// An item in a [RadialMenu].
///
/// The type `T` is the type of the value the entry represents. All the entries
/// in a given menu must represent values with consistent types.
class RadialMenuItem<T> extends StatelessWidget {
  /// Creates a circular action button for an item in a [RadialMenu].
  ///
  /// The [child] argument is required.
  const RadialMenuItem({
    Key key,
    @required this.child,
    this.value,
    this.tooltip,
    this.size = _defaultButtonSize,
    this.backgroundColor,
    this.iconColor,
    // this.iconSize: 24.0,
  })  : assert(child != null),
        assert(size != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically an [Icon] widget.
  final Widget child;

  /// The value to return if the user selects this menu item.
  ///
  /// Eventually returned in a call to [RadialMenu.onSelected].
  final T value;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String tooltip;

  /// The color to use when filling the button.
  ///
  /// Defaults to the primary color of the current theme.
  final Color backgroundColor;

  /// The size of the button.
  ///
  /// Defaults to 48.0.
  final double size;

  /// The color to use when painting the child icon.
  ///
  /// Defaults to the primary icon theme color.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final Color _iconColor =
        iconColor ?? Theme.of(context).primaryIconTheme.color;

    Widget result;

    if (child != null) {
      result = new Center(
        child: IconTheme.merge(
          data: new IconThemeData(
            color: _iconColor,
          ),
          child: child,
        ),
      );
    }

    if (tooltip != null) {
      result = new Tooltip(
        message: tooltip,
        child: result,
      );
    }

    result = new Container(
      width: size,
      height: size,
      child: result,
    );

    return result;
  }
}
