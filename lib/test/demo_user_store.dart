/// Created by guoshuyu
/// Date: 2018-08-06
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';

class DemoUseStorePage extends StatelessWidget {
  const DemoUseStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    ///通过 StoreConnector 关联 GSYState 中的 User
    return StoreConnector<GSYState, User?>(
      ///通过 converter 将 GSYState 中的 userInfo返回
      converter: (store) => store.state.userInfo,
      ///在 userInfo 中返回实际渲染的控件
      builder: (context, userInfo) {
        return Text(
          userInfo!.name!,
          style: Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}
