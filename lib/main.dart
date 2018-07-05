import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new GSYTabBarWidget(
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
          title: "Title"),
    );
  }
}
