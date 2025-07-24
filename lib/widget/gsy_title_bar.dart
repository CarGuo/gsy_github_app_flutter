import 'package:flutter/material.dart';

/// title 控件
/// Created by guoshuyu
/// on 2018/7/24.
class GSYTitleBar extends StatelessWidget {
  final String? title;
  final IconData? iconData;
  final ValueChanged? onRightIconPressed;
  final bool needRightLocalIcon;
  final Widget? rightWidget;

  final GlobalKey rightKey = GlobalKey();

  // Constants for better performance
  static const double _iconSize = 19.0;
  static const int _maxLines = 1;

  GSYTitleBar(
    this.title, {
    super.key,
    this.iconData,
    this.onRightIconPressed,
    this.needRightLocalIcon = false,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Widget rightChild = _buildRightWidget();
    
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title!,
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        rightChild,
      ],
    );
  }

  Widget _buildRightWidget() {
    if (rightWidget != null) {
      return rightWidget!;
    }
    
    if (needRightLocalIcon) {
      return IconButton(
        icon: Icon(
          iconData,
          key: rightKey,
          size: _iconSize,
        ),
        onPressed: _handleRightIconPress,
      );
    }
    
    return const SizedBox.shrink(); // More efficient than Container()
  }

  void _handleRightIconPress() {
    final renderBox = rightKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final centerPosition = Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
      onRightIconPressed?.call(centerPosition);
    }
  }
}
