import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/data_result.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
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

  bool _hasMore = true;

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
      _hasMore = data.length >= Config.PAGE_SIZE;
      if (_hasMore) {
        controller.finishLoad(IndicatorResult.success);
      } else {
        controller.finishLoad(IndicatorResult.noMore);
      }
      if (signalPage.value == 1) {
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
      _openNotificationTarget(notification);
    }, needImage: false);
  }

  /// 按 subject.type 分派到对应内嵌页面；未识别类型走 html_url 兜底
  /// - Issue / PullRequest: subject.url 末段是 number → IssueDetailPage
  ///   （GSY 的 IssueDetailPage 内部会检测 pull_request 字段自动切 PR 视图）
  /// - Commit: subject.url 末段是 sha → PushDetailPage
  /// - Release: 需要 repo 的 htmlUrl 拼 releases/tags 页 → ReleasePage
  /// - 其它 (Discussion / CheckSuite / 未来新增)：走外部浏览器
  /// 已知类型但字段缺失时静默 fallback（不弹"不支持类型"toast，因为类型明明是支持的）；
  /// 只有真正 default 分支才弹"不支持类型"提示。
  void _openNotificationTarget(Model.Notification notification) {
    final subject = notification.subject;
    final repository = notification.repository;
    // repository 为空时也别静默失效，让用户至少能通过浏览器打开
    if (subject == null || repository == null) {
      _openFallbackUnsupported(notification);
      return;
    }
    final String? type = subject.type;
    final String? subjectUrl = subject.url;
    final String? userName = repository.owner?.login;
    final String? reposName = repository.name;
    final String? repoHtmlUrl = repository.htmlUrl;

    switch (type) {
      case 'Issue':
      case 'PullRequest':
        final number =
            subjectUrl == null ? '' : _lastPathSegment(subjectUrl);
        if (userName == null || reposName == null || number.isEmpty) {
          _openFallbackDegraded(notification);
          return;
        }
        NavigatorUtils.goIssueDetail(context, userName, reposName, number,
                needRightLocalIcon: true)
            .then((_) {
          if (!mounted) return;
          _forceRefresh();
        });
        return;
      case 'Commit':
        final sha = subjectUrl == null ? '' : _lastPathSegment(subjectUrl);
        if (userName == null || reposName == null || sha.isEmpty) {
          _openFallbackDegraded(notification);
          return;
        }
        NavigatorUtils.goPushDetailPage(
                context, userName, reposName, sha, true)
            .then((_) {
          if (!mounted) return;
          _forceRefresh();
        });
        return;
      case 'Release':
        if (userName == null || reposName == null || repoHtmlUrl == null) {
          _openFallbackDegraded(notification);
          return;
        }
        NavigatorUtils.goReleasePage(context, userName, reposName,
                '$repoHtmlUrl/releases', '$repoHtmlUrl/tags')
            .then((_) {
          if (!mounted) return;
          _forceRefresh();
        });
        return;
      default:
        _openFallbackUnsupported(notification);
        return;
    }
  }

  /// 已知类型但字段缺失：不弹"不支持类型"toast，直接尽力用外部浏览器兜底。
  /// launchOutURL 内部打不开时会自己弹一条错误 toast，不会静默。
  Future<void> _openFallbackDegraded(Model.Notification notification) async {
    final htmlUrl = _resolveHtmlUrl(notification);
    if (!mounted) return;
    if (htmlUrl != null && htmlUrl.isNotEmpty) {
      await CommonUtils.launchOutURL(htmlUrl, context);
    }
  }

  /// 走到 default 分支：类型确实不认识，弹一次说明性 toast，然后尽力浏览器兜底。
  Future<void> _openFallbackUnsupported(Model.Notification notification) async {
    final type = notification.subject?.type ?? '';
    showToast(context.l10n.notify_unsupported_type(type));
    final htmlUrl = _resolveHtmlUrl(notification);
    if (!mounted) return;
    if (htmlUrl != null && htmlUrl.isNotEmpty) {
      await CommonUtils.launchOutURL(htmlUrl, context);
    }
  }

  /// 从 notification 里解析出一个能用浏览器打开的 html url。
  /// 顺序：subject.url 已经是 https://github.com/ (Discussion 场景) → 直接用；
  /// subject.url 是 api.github.com/repos/… → 段替换成 web 路径（pulls→pull）；
  /// 其它情况（url 为 null、非 github 域、路径不认识）→ 退回 repository.htmlUrl。
  String? _resolveHtmlUrl(Model.Notification notification) {
    final apiUrl = notification.subject?.url;
    if (apiUrl != null && apiUrl.isNotEmpty) {
      if (apiUrl.startsWith('https://github.com/')) {
        return apiUrl;
      }
      const apiPrefix = 'https://api.github.com/repos/';
      if (apiUrl.startsWith(apiPrefix)) {
        final rest = apiUrl.substring(apiPrefix.length);
        // pulls -> pull（github web 用单数）；其它段名 issues/commits/releases 在 web
        // 上同名，直接透传。releases 段末尾是内部 id 而不是 tag，可能 404，
        // 这是浏览器兜底的已知限制，不在内嵌路径上出现。
        final web = rest.replaceFirst('/pulls/', '/pull/');
        return 'https://github.com/$web';
      }
    }
    return notification.repository?.htmlUrl;
  }

  /// 取 url path 最后一个非空段。用 Uri 解析天然处理尾斜杠、query、fragment。
  String _lastPathSegment(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    for (final s in uri.pathSegments.reversed) {
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  _getDataLogic(int page) async {
    return await UserRepository.getNotifyRequest(
        notifyIndexSignal.value == 2, notifyIndexSignal.value == 1, page);
  }

  requestLoadMore() async {
    if (!_hasMore) {
      controller.finishLoad(IndicatorResult.noMore);
      return;
    }
    isLoading = Completer<bool>();
    signalPage.value++;
    await isLoading.future;
  }

  requestRefresh() async {
    isLoading = Completer<bool>();
    _hasMore = true;
    controller.finishLoad(IndicatorResult.none);
    signalPage.value = 1;
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
