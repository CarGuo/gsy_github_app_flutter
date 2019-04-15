import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/test/demo_item.dart';

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    ///一个页面的开始
    ///如果是新页面，会自带返回按键
    return new Scaffold(
      ///背景样式
      backgroundColor: Colors.blue,

      ///标题栏，当然不仅仅是标题栏
      appBar: new AppBar(
        ///这个title是一个Widget
        title: new Text("Title"),
      ),

      ///正式的页面开始
      ///一个ListView，20个Item
      body: new ListView.builder(
        itemBuilder: (context, index) {
          return new DemoItem();
        },
        itemCount: 20,
      ),
    );
  }

  request() async {
    await Future.delayed(Duration(seconds: 1));
    return "ok!";
  }

  doSomeThing() async {
    String data = await request();
    data = "ok from request";
    return data;
  }

  renderSome() {
    doSomeThing().then((value) {
      print(value);
      ///输出ok from request
    });
  }
}
