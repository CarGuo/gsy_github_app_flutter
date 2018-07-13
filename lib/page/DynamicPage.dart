import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/EventDao.dart';
import 'package:gsy_github_app_flutter/common/redux/GSYState.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:redux/redux.dart';

class DynamicPage extends StatefulWidget {
  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {

  final GSYPullLoadWidgetControl pullLoadWidgetControl = new GSYPullLoadWidgetControl();

  Future<Null> _handleRefresh() async {
    setState(() {
      pullLoadWidgetControl.count = 5;
    });
    return null;
  }

  bool _onNotification<Notification>(Notification notify) {
    if (notify is! OverscrollNotification) {
      return true;
    }
    setState(() {
      pullLoadWidgetControl.count += 5;
    });
    return true;
  }

  @override
  void didChangeDependencies() {
    Store<GSYState> store =  StoreProvider.of(context);
    EventDao.getEventReceived(store);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return GSYPullLoadWidget(
            pullLoadWidgetControl,
            (BuildContext context, int index) => new EventItem(),
            _handleRefresh,
            _onNotification);
      },
    );
  }
}
