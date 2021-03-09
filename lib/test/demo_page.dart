import 'package:flutter/material.dart';

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
          return new Card(
            ///设置阴影的深度
            elevation: 5.0,
            ///增加圆角
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            color: Colors.white,
            margin: const EdgeInsets.only(left: 30.0, right: 30.0, top: 30),
            child: new Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: 80,
              child: new Text("显示文本 ${index}"),
            ),
          );
        },
        itemCount: 20,
      ),
      floatingActionButton: Builder(builder: (builderContext) {
        ///利用 builder 的 builderContext
        ///才能获取到  Scaffold.of(builderContext) 的 ScaffoldState
        return FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(builderContext)
                .showSnackBar(SnackBar(content: new Text("SnackBar")));
          },
        );
      }),
    );
  }
}
