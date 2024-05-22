import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/user_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_event_item.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_select_item_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gsy_github_app_flutter/model/Notification.dart' as Model;

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
        GSYListState<NotifyPage>,
        SingleTickerProviderStateMixin {
  late SlidableController slidableController;

  int selectIndex = 0;

  ///绘制 Item
  _renderItem(index) {
    Model.Notification notification = pullLoadWidgetControl.dataList[index];
    if (selectIndex != 0) {
      return _renderEventItem(notification);
    }

    ///只有未读消息支持 Slidable 滑动效果
    return Slidable(
      key: ValueKey<String>("${index}_$selectIndex"),
      controller: slidableController,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () {
          UserDao.setNotificationAsReadDao(notification.id.toString())
              .then((res) {
            showRefreshLoading();
          });
        }),
        children: [
          SlidableAction(
            label: GSYLocalizations.i18n(context)!.notify_readed,
            backgroundColor: Colors.redAccent,
            icon: Icons.delete,
            onPressed: (c) {
              UserDao.setNotificationAsReadDao(notification.id.toString())
                  .then((res) {
                showRefreshLoading();
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
        UserDao.setNotificationAsReadDao(notification.id.toString());
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
          showRefreshLoading();
        });
      }
    }, needImage: false);
  }

  ///切换tab
  _resolveSelectIndex() {
    clearData();
    showRefreshLoading();
  }

  _getDataLogic() async {
    return await UserDao.getNotifyDao(selectIndex == 2, selectIndex == 1, page);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => true;

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  void initState() {
    super.initState();
    slidableController = SlidableController(this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return Scaffold(
      backgroundColor: GSYColors.mainBackgroundColor,
      appBar: AppBar(
        title: GSYTitleBar(
          GSYLocalizations.i18n(context)!.notify_title,
          iconData: GSYICons.NOTIFY_ALL_READ,
          needRightLocalIcon: true,
          onRightIconPressed: (_) {
            CommonUtils.showLoadingDialog(context);
            UserDao.setAllNotificationAsReadDao().then((res) {
              Navigator.pop(context);
              _resolveSelectIndex();
            });
          },
        ),
        bottom: GSYSelectItemWidget(
          [
            GSYLocalizations.i18n(context)!.notify_tab_unread,
            GSYLocalizations.i18n(context)!.notify_tab_part,
            GSYLocalizations.i18n(context)!.notify_tab_all,
          ],
          (selectIndex) {
            this.selectIndex = selectIndex;
            _resolveSelectIndex();
          },
          height: 30.0,
          margin: const EdgeInsets.all(0.0),
          elevation: 0.0,
        ),
        elevation: 4.0,
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        (BuildContext context, int index) => _renderItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
