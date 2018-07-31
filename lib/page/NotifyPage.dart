import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/UserDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/EventItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYSelectItemWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/common/model/Notification.dart' as Model;

/**
 * 通知消息
 * Created by guoshuyu
 * Date: 2018-07-24
 */

class NotifyPage extends StatefulWidget {
  NotifyPage();

  @override
  _NotifyPageState createState() => _NotifyPageState();
}

// ignore: mixin_inherits_from_not_object
class _NotifyPageState extends GSYListState<NotifyPage> {
  int selectIndex;

  _NotifyPageState();

  _renderEventItem(index) {
    Model.Notification notification = pullLoadWidgetControl.dataList[index];
    EventViewModel eventViewModel = EventViewModel.fromNotify(notification);
    return new EventItem(eventViewModel, onPressed: () {
      if (notification.unread) {
        UserDao.setNotificationAsReadDao(notification.id.toString());
      }
      if (notification.subject.type == 'Issue') {
        String url = notification.subject.url;
        List<String> tmp = url.split("/");
        String number = tmp[tmp.length - 1];
        String userName = notification.repository.owner.login;
        String reposName = notification.repository.name;
        NavigatorUtils.goIssueDetail(context, userName, reposName, number, needRightLocalIcon: true).then((res) {
          showRefreshLoading();
        });
      }
    }, needImage: false);
  }

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
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new Scaffold(
      backgroundColor: Color(GSYColors.mainBackgroundColor),
      appBar: new AppBar(
        title: GSYTitleBar(
          GSYStrings.notify_title,
          iconData: GSYICons.NOTIFY_ALL_READ,
          needRightLocalIcon: true,
          onPressed: () {
            CommonUtils.showLoadingDialog(context);
            UserDao.setAllNotificationAsReadDao().then((res) {
              Navigator.pop(context);
              _resolveSelectIndex();
            });
          },
        ),
        bottom: new GSYSelectItemWidget(
          [
            GSYStrings.notify_tab_unread,
            GSYStrings.notify_tab_part,
            GSYStrings.notify_tab_all,
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
        (BuildContext context, int index) => _renderEventItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
