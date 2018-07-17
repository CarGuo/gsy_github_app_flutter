
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/widget/UserHeader.dart';
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

// ignore: mixin_inherits_from_not_object
class _MyPageState extends State<MyPage>  with AutomaticKeepAliveClientMixin  {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }



  @override
  Widget build(BuildContext context) {
    return new StoreConnector<GSYState, String>(
      converter: (store) => store.state.userInfo.name,
      builder: (context, count) {
        return new UserHeaderItem();
      },
    );
  }
}
