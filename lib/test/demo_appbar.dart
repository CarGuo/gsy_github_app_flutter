import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final bool needLeading;
  final double leadingWidth;
  final List<Widget>? actions;
  final IconData backBtnIconData;
  final VoidCallback? backPress;
  final Color iconColor;
  final Color textColor;
  final Widget? title;

  ImageAppbar(
      {this.leading,
      this.actions,
      this.needLeading = true,
      this.title,
      this.backBtnIconData = Icons.arrow_back_ios,
      this.backPress,
      this.leadingWidth = 56.0,
      this.iconColor = Colors.white,
      this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    var leading = this.leading;

    if (leading == null) {
      leading ??= needLeading
          ? IconButton(
              highlightColor: Colors.transparent,
              icon: Icon(
                backBtnIconData,
                color: iconColor,
              ),
              color: iconColor,
              onPressed: () {
                if (backPress != null) {
                  backPress!();
                  return;
                }
                Navigator.maybePop(context);
              },
            )
          : Container();
    }

    leading = ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: leadingWidth),
      child: leading,
    );

    TextStyle? centerStyle = Theme.of(context).textTheme.titleLarge ??
        Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).primaryTextTheme.titleLarge;

    Widget? title = this.title;
    if (title != null) {
      title = DefaultTextStyle(
        style: centerStyle!,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        child: title,
      );
    }

    var content = Stack(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("static/images/logo.png"), fit: BoxFit.cover),
          ),
        ),
        SafeArea(
          child: Container(
            alignment: Alignment.centerLeft,
            child: leading,
          ),
        ),
        SafeArea(
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Center(
                    child: title ?? Container(),
                  )),
            ],
          ),
        ),
        SafeArea(
          child: Row(
            children: <Widget>[
              Expanded(child: Container()),
              Row(
                children: actions ?? [],
              )
            ],
          ),
        )
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: content,
    );
  }

  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
