import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/bloc/base/base_bloc.dart';
import 'package:gsy_github_app_flutter/bloc/dynamic_bloc.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/model/Event.dart';
import 'package:gsy_github_app_flutter/common/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/utils/event_utils.dart';
import 'package:gsy_github_app_flutter/widget/event_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_bloc_list_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_pull_new_load_widget.dart';
import 'package:redux/redux.dart';

/**
 * 主页动态tab页
 * Created by guoshuyu
 * Date: 2018-07-16
 */
class DynamicPage extends StatefulWidget {
  @override
  _DynamicPageState createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> with AutomaticKeepAliveClientMixin<DynamicPage>, GSYListState<DynamicPage>, WidgetsBindingObserver {
  final DynamicBloc dynamicBloc = new DynamicBloc();

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    return await dynamicBloc.requestRefresh(_getStore().state.userInfo?.login);
  }

  @override
  requestLoadMore() async {
    return await dynamicBloc.requestLoadMore(_getStore().state.userInfo?.login);
  }

  @override
  bool get isRefreshFirst => false;

  @override
  BlocListBase get bloc => dynamicBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ReposDao.getNewsVersion(context, false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (bloc.getDataLength() == 0) {
      showRefreshLoading();
    }
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (bloc.getDataLength() != 0) {
        showRefreshLoading();
      }
    }
  }

  _renderEventItem(Event e) {
    EventViewModel eventViewModel = EventViewModel.fromEventMap(e);
    return new EventItem(
      eventViewModel,
      onPressed: () {
        EventUtils.ActionUtils(context, e, "");
      },
    );
  }

  Store<GSYState> _getStore() {
    return StoreProvider.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new StoreBuilder<GSYState>(
      builder: (context, store) {
        return BlocProvider<DynamicBloc>(
          bloc: dynamicBloc,
          child: GSYPullLoadWidget(
            bloc.pullLoadWidgetControl,
            (BuildContext context, int index) => _renderEventItem(bloc.dataList[index]),
            requestRefresh,
            requestLoadMore,
            refreshKey: refreshIndicatorKey,
          ),
        );
      },
    );
  }
}
