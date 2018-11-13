import 'dart:async';

import 'package:flutter/material.dart';

class DEMOWidget extends StatelessWidget {
  final String text;

  DEMOWidget(this.text);

  @override
  Widget build(BuildContext context) {
    //这里返回你需要的控件
    //这里末尾有没有的逗号，对于格式化代码而已是不一样的。
    return Container(
      color: Colors.white,
      child: Text(text ?? "这就是无状态DMEO"),
    );
  }
}

class DemoStateWidget extends StatefulWidget  {

  final String text;

  DemoStateWidget(this.text);

  @override
  _DemoStateWidgetState createState() => _DemoStateWidgetState(text);
}

class _DemoStateWidgetState extends State<DemoStateWidget> with AutomaticKeepAliveClientMixin  {

  String text;

  _DemoStateWidgetState(this.text);

  @override
  void initState() {
    ///初始化，这个函数在生命周期中只调用一次
    super.initState();
  }

  @override
  void dispose() {
    ///销毁
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    ///在initState之后调 Called when a dependency of this [State] object changes.
    super.didChangeDependencies();
    new Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        text = "这就变了数值";
      });
      return true;
    });
  }


  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(text ?? "这就是有状态DMEO"),
    );
  }
}
