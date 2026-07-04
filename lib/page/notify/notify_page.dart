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

  /// 按仓库过滤 - 值为 `owner/name`（Repository.fullName），null 表示"所有仓库"。
  /// 只在客户端对已加载数据做筛选，不改数据请求 —— GitHub 官方 `GET /notifications`
  /// 不支持 repo 查询参数。切换 tab / 强制刷新时保持不变，切页面重建时归位 null。
  late var selectedRepoSignal = createSignal<String?>(null);

  @override
  void initState() {
    super.initState();
    createEffect(() async {
      notifyIndexSignal.value;
      signalPage.value;
      loadData();
    });
    // 切 tab 时把"按仓库筛选"重置回"所有仓库"。
    // 原因：新 tab 拉的数据集通常包含新的仓库子集，保留旧筛选值可能筛出空列表，
    // 让用户以为"这个 tab 没数据"，反而更混乱。
    createEffect(() {
      notifyIndexSignal.value;
      selectedRepoSignal.value = null;
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
  _renderItem(Model.Notification notification) {
    final isUnread = notifyIndexSignal.value == 0;

    // 所有 tab 都需要侧滑面板：
    // - 未读 tab：标记已读 + 订阅切换 + 归档
    // - 已读/全部 tab：订阅切换 + 归档（"已读"对已读消息没意义）
    // key 里带上 tab index 是为了让 Slidable 在 tab 切换时重建、避免残留展开状态
    final actions = <Widget>[];
    if (isUnread) {
      actions.add(_buildSlideAction(
        label: context.l10n.notify_readed,
        backgroundColor: Colors.redAccent,
        icon: Icons.done,
        onPressed: () => _markAsRead(notification),
      ));
    }
    actions.add(_buildSlideAction(
      label: context.l10n.notify_subscribe,
      backgroundColor: Colors.blueAccent,
      icon: Icons.notifications_active,
      onPressed: () => _subscribeThread(notification),
    ));
    actions.add(_buildSlideAction(
      label: context.l10n.notify_unsubscribe,
      backgroundColor: Colors.grey,
      icon: Icons.notifications_off,
      onPressed: () => _unsubscribeThread(notification),
    ));
    actions.add(_buildSlideAction(
      label: context.l10n.notify_archive,
      backgroundColor: Colors.deepOrange,
      icon: Icons.archive,
      onPressed: () => _archiveThread(notification),
    ));

    return Slidable(
      key: ValueKey<String>("${notification.id}_${notifyIndexSignal.value}"),
      endActionPane: ActionPane(
        dragDismissible: false,
        motion: const ScrollMotion(),
        extentRatio: isUnread ? 0.78 : 0.62,
        // 滑到底的默认动作：未读 tab 走"已读"，其它 tab 走"归档"
        // 这个默认动作和用户潜在预期一致：未读用户想清读、已读用户想清 inbox
        dismissible: DismissiblePane(
          onDismissed: () {
            if (isUnread) {
              _markAsRead(notification);
            } else {
              _archiveThread(notification);
            }
          },
        ),
        children: actions,
      ),
      child: _renderEventItem(notification),
    );
  }

  /// 侧滑按钮统一封装：走 CustomSlidableAction，label 用 FittedBox scaleDown
  /// 包裹，超过按钮宽度自动缩小字号而不是变成"..."。i18n 全语言鲁棒。
  Widget _buildSlideAction({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return CustomSlidableAction(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      onPressed: (_) => onPressed(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 13, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部筛选条：显示当前"按仓库筛选"状态；点击弹底部 sheet 选择 repo。
  /// [visibleCount] 是当前过滤后可见条数，仅在筛选态下展示反馈信息。
  Widget _buildRepoFilterBar(int visibleCount) {
    final selectedRepo = selectedRepoSignal.value;
    final isFiltered = selectedRepo != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showRepoFilterSheet,
      child: Container(
        color: isFiltered
            ? Colors.blueAccent.withValues(alpha: 0.08)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 18,
              color: isFiltered ? Colors.blueAccent : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isFiltered
                    ? "${context.l10n.notify_filter_repo}: $selectedRepo ($visibleCount)"
                    : context.l10n.notify_filter_repo_all,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isFiltered ? Colors.blueAccent : Colors.grey.shade700,
                  fontWeight:
                      isFiltered ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFiltered)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => selectedRepoSignal.value = null,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              )
            else
              Icon(Icons.arrow_drop_down,
                  size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  /// 按当前 selectedRepoSignal 从 notifySignal 里过滤出可见列表。
  /// 单独抽出来是因为 filter bar 显示 count 和 ListView 都要用同一份数据，
  /// 避免过滤逻辑写两遍导致漂移。
  List<Model.Notification> _currentFilteredList() {
    final selectedRepo = selectedRepoSignal.value;
    if (selectedRepo == null) {
      return notifySignal.toList();
    }
    return notifySignal
        .where((n) => n.repository?.fullName == selectedRepo)
        .toList();
  }

  /// 弹出 BottomSheet 让用户从当前已加载通知里出现过的所有 repo 中选一个。
  /// 用 Set 去重再排序，避免重复项；把"所有仓库"作为第一项 sentinel。
  void _showRepoFilterSheet() {
    final repoNames = notifySignal
        .map((n) => n.repository?.fullName)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: repoNames.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return ListTile(
                  leading: const Icon(Icons.all_inbox),
                  title: Text(context.l10n.notify_filter_repo_all),
                  selected: selectedRepoSignal.value == null,
                  onTap: () {
                    selectedRepoSignal.value = null;
                    Navigator.pop(sheetCtx);
                  },
                );
              }
              final repo = repoNames[i - 1];
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(repo,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: selectedRepoSignal.value == repo,
                onTap: () {
                  selectedRepoSignal.value = repo;
                  Navigator.pop(sheetCtx);
                },
              );
            },
          ),
        );
      },
    );
  }

  /// 标记已读：成功再从列表移除；失败保留 item + toast 提示，避免服务端与 UI 不一致。
  Future<void> _markAsRead(Model.Notification notification) async {
    final res = await UserRepository.setNotificationAsReadRequest(
        notification.id.toString());
    if (!mounted) return;
    final ok = res != null && res.result == true;
    if (ok) {
      notifySignal.remove(notification);
    } else {
      showToast(context.l10n.notify_read_failed);
    }
  }

  /// 归档：对应官方 App "Done"；DELETE /notifications/threads/{id}
  /// 成功后从当前列表移除（所有 tab 都从当前视图消失）。
  Future<void> _archiveThread(Model.Notification notification) async {
    final res = await UserRepository.archiveNotificationThreadRequest(
        notification.id.toString());
    if (!mounted) return;
    if (res.result == true) {
      notifySignal.remove(notification);
      showToast(context.l10n.notify_archive_success);
    } else {
      showToast(context.l10n.notify_archive_failed);
    }
  }

  /// 订阅 thread：不改变列表可见性，仅 toast 反馈结果。
  Future<void> _subscribeThread(Model.Notification notification) async {
    final res = await UserRepository.subscribeNotificationThreadRequest(
        notification.id.toString());
    if (!mounted) return;
    if (res.result == true) {
      showToast(context.l10n.notify_subscribe_success);
    } else {
      showToast(context.l10n.notify_subscribe_failed);
    }
  }

  /// 取消订阅：同上，仅 toast。
  Future<void> _unsubscribeThread(Model.Notification notification) async {
    final res = await UserRepository.unsubscribeNotificationThreadRequest(
        notification.id.toString());
    if (!mounted) return;
    if (res.result == true) {
      showToast(context.l10n.notify_unsubscribe_success);
    } else {
      showToast(context.l10n.notify_subscribe_failed);
    }
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
      body: Column(
        children: [
          // 筛选条独立在 EasyRefresh 之外，避免 EasyRefresh 手势层遮挡点击、
          // 也防止筛选条被下拉刷新一起滚走。
          Watch((_) => _buildRepoFilterBar(_currentFilteredList().length)),
          Expanded(
            child: EasyRefresh(
              controller: controller,
              header: const MaterialHeader(),
              footer: const BezierFooter(),
              refreshOnStart: true,
              onRefresh: requestRefresh,
              onLoad: requestLoadMore,
              child: Watch((_) {
                // 依赖 signal 变化重建：selectedRepoSignal / notifySignal 任一变化都刷视图。
                final selectedRepo = selectedRepoSignal.value;
                final filtered = _currentFilteredList();
                if (filtered.isEmpty && selectedRepo != null) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            context.l10n.notify_filter_repo_empty_hint,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  itemBuilder: (_, int index) => _renderItem(filtered[index]),
                  itemCount: filtered.length,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
