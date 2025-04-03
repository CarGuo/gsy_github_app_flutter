import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gsy_github_app_flutter/model/notification.dart' as Model;
import 'package:signals/signals_flutter.dart';

/// 通知消息
/// Created by guoshuyu
/// Date: 2018-07-24

class NotifyPage extends StatefulWidget {
  const NotifyPage({super.key});

  @override
  _NotifyPageState createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage>
    with
        AutomaticKeepAliveClientMixin<NotifyPage>,
        SingleTickerProviderStateMixin,
        SignalsMixin {
  final EasyRefreshController controller =
      EasyRefreshController(controlFinishLoad: true);

  late Completer<bool> isLoading;

  late var notifySignal = createListSignal<Model.Notification>([]);
  late var notifyIndexSignal = createSignal<int>(0);
  late var signalPage = createSignal<int>(-1);

  @override
  void initState() {
    super.initState();
    createEffect(() async {
      notifyIndexSignal.value;
      signalPage.value;
      loadData();
    });
  }

  loadData() async {
    if (signalPage.value == -1) {
      return;
    }
    DataResult res = await _getDataLogic(signalPage.value);
    if (res.result && res.data is List<Model.Notification>) {
      var data = res.data as List<Model.Notification>;
      if (data.length < Config.PAGE_SIZE) {
        controller.finishLoad(IndicatorResult.noMore);
      } else {
        controller.finishLoad(IndicatorResult.success);
      }
      if (signalPage.value == 0) {
        notifySignal.value = data;
      } else {
        notifySignal.addAll(data);
      }
    }
    if (!isLoading.isCompleted) {
      isLoading.complete(true);
    }
  }

  ///绘制 Item
  _renderItem(index) {
    Model.Notification notification = notifySignal[index];
    if (notifyIndexSignal.value != 0) {
      return _renderEventItem(notification);
    }

    ///只有未读消息支持 Slidable 滑动效果
    return Slidable(
      key: ValueKey<String>("${index}_${notifyIndexSignal.value}"),
      endActionPane: ActionPane(
        dragDismissible: false,
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () {
          UserRepository.setNotificationAsReadRequest(
                  notification.id.toString())
              .then((res) {
            notifySignal.remove(notification);
          });
        }),
        children: [
          SlidableAction(
            label: context.l10n.notify_readed,
            backgroundColor: Colors.redAccent,
            icon: Icons.delete,
            onPressed: (c) {
              UserRepository.setNotificationAsReadRequest(
                      notification.id.toString())
                  .then((res) {
                notifySignal.remove(notification);
              });
            },
          ),
        ],
      ),
      child: _renderEventItem(notification),
    );
  }

  ///绘制实际的内容数据item
  _renderEventItem(Model.Notification notification) {
    EventViewModel eventViewModel =
        EventViewModel.fromNotify(context, notification);
    return GSYEventItem(eventViewModel, onPressed: () {
      if (notification.unread!) {
        UserRepository.setNotificationAsReadRequest(notification.id.toString());
      }
      if (notification.subject!.type == 'Issue') {
        String url = notification.subject!.url!;
        StringList tmp = url.split("/");
        String number = tmp[tmp.length - 1];
        String? userName = notification.repository!.owner!.login;
        String? reposName = notification.repository!.name;
        NavigatorUtils.goIssueDetail(context, userName, reposName, number,
                needRightLocalIcon: true)
            .then((res) {
          _forceRefresh();
        });
      }
    }, needImage: false);
  }

  _getDataLogic(int page) async {
    return await UserRepository.getNotifyRequest(
        notifyIndexSignal.value == 2, notifyIndexSignal.value == 1, page);
  }

  requestLoadMore() async {
    isLoading = Completer<bool>();
    signalPage.value++;
    await isLoading.future;
  }

  requestRefresh() async {
    isLoading = Completer<bool>();
    controller.finishLoad(IndicatorResult.none);
    signalPage.value = 0;
    await isLoading.future;
  }

  _forceRefresh() async {
    signalPage.value = -1;
    controller.callRefresh();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      appBar: AppBar(
        title: GSYTitleBar(
          context.l10n.notify_title,
          iconData: GSYICons.NOTIFY_ALL_READ,
          needRightLocalIcon: true,
          onRightIconPressed: (_) {
            CommonUtils.showLoadingDialog(context);
            UserRepository.setAllNotificationAsReadRequest().then((res) {
              Navigator.pop(context);
              _forceRefresh();
            });
          },
        ),
        bottom: GSYSelectItemWidget(
          [
            context.l10n.notify_tab_unread,
            context.l10n.notify_tab_part,
            context.l10n.notify_tab_all,
          ],
          (selectIndex) {
            notifyIndexSignal.value = selectIndex;
          },
          height: 30.0,
          margin: const EdgeInsets.all(0.0),
          elevation: 0.0,
        ),
        elevation: 4.0,
      ),
      body: EasyRefresh(
        controller: controller,
        header: const MaterialHeader(),
        footer: const BezierFooter(),
        refreshOnStart: true,
        onRefresh: requestRefresh,
        onLoad: requestLoadMore,
        child: ListView.builder(
          itemBuilder: (_, int index) => _renderItem(index),
          itemCount: notifySignal.length,
        ),
      ),
    );
  }
}
