import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

class GSYCardItem extends StatelessWidget {
  final Widget child;

  GSYCardItem({@required this.child});

  @override
  Widget build(BuildContext context) {
    return new Card(
        elevation: 5.0,
        shape: new RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
        color: Color(GSYColors.cardWhite),
        margin: new EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
        child: child);
  }
}
