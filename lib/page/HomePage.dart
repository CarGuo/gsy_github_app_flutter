import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';

class HomePage extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.BOTTOM_TAB,
        tabItems: [
          new Tab(icon: new Icon(Icons.directions_car)),
          new Tab(icon: new Icon(Icons.directions_transit)),
          new Tab(icon: new Icon(Icons.directions_bike)),
        ],
        tabViews: [
          new Icon(Icons.directions_car),
          new Icon(Icons.directions_transit),
          new Icon(Icons.directions_bike),
        ],
        backgroundColor: Colors.deepOrange,
        indicatorColor: Colors.white,
        title: "Title");
  }
}
