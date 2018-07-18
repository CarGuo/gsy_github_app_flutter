import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-18
 */

class RepositoryDetailReadmePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: new Center(
          child: new Text("Flutter现在没有WebView!!\n残念！！！", style: GSYConstant.largeText, textAlign:TextAlign.center),
        ),
    );
  }
}
