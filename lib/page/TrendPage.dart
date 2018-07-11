
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';

class TrendPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new StoreConnector<GSYState, String>(
      converter: (store) => store.state.userInfo.name,
      builder: (context, count) {
        return new Text(
          count,
          style: Theme.of(context).textTheme.display1,
        );
      },
    );
  }
}
