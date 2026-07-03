import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/issue_timeline_event.dart';
import 'package:gsy_github_app_flutter/model/pull_request.dart';
import 'package:gsy_github_app_flutter/model/reactions.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_flex_button.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_header_item.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_item.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/issue_timeline_item.dart';

/// Issue 详情页面
/// Created by guoshuyu
/// on 2018/7/21.
///
/// 本次改造对齐 GitHub 官方能力：
/// - 头部：labels/assignees/milestone/author_association/bot/edited 展示，
///   以及 reactions 汇总条（可加/减）。
/// - 列表：合并 timeline 事件与 comments，按时间序展示 label 增减、assigned、
///   milestoned、renamed、referenced、closed、reopened、locked/unlocked 等。
/// - 评论：显示 author_association 徽章、bot、edited、minimized 折叠态，
///   以及 comment 级 reactions 汇总条（可加/减）。

class IssueDetailPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  final String issueNum;

  final bool needHomeIcon;

  const IssueDetailPage(this.userName, this.reposName, this.issueNum,
      {super.key, this.needHomeIcon = false});

  @override
  _IssueDetailPageState createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage>
    with
        AutomaticKeepAliveClientMixin<IssueDetailPage>,
        GSYListState<IssueDetailPage> {
  int selectIndex = 0;

  ///头部信息数据是否加载成功，成功了就可以显示底部状态
  bool headerStatus = false;

  String? htmlUrl;

  /// issue 的头部数据显示
  IssueHeaderViewModel issueHeaderViewModel = IssueHeaderViewModel();

  ///控制编辑时issue的title
  TextEditingController issueInfoTitleControl = TextEditingController();

  ///控制编辑时issue的content
  TextEditingController issueInfoValueControl = TextEditingController();

  /// 第一页拉到的 timeline 事件（评论合并进 dataList，其它事件单独渲染）
  List<IssueTimelineEvent> _timelineEvents = <IssueTimelineEvent>[];

  ///绘制item
  _renderEventItem(index) {
    ///第一个绘制的是头部
    if (index == 0) {
      return IssueHeaderItem(
        issueHeaderViewModel,
        onPressed: () {},
        onReactionToggle: _onIssueReactionToggle,
      );
    }
    final data = pullLoadWidgetControl.dataList[index - 1];
    if (data is IssueTimelineEvent) {
      return IssueTimelineItem(data);
    }
    Issue issue = data as Issue;
    return IssueItem(
      IssueItemViewModel.fromMap(issue, needTitle: false),
      hideBottom: true,
      limitComment: false,
      onReactionToggle: (content, isAdd) =>
          _onCommentReactionToggle(issue, content, isAdd),
      onPressed: () {
        NavigatorUtils.showGSYDialog(
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(4.0)),
                      color: GSYColors.white,
                      border: Border.all(
                          color: GSYColors.subTextColor, width: 0.3)),
                  margin: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GSYFlexButton(
                        color: GSYColors.white,
                        textColor: GSYColors.primaryDarkValue,
                        text: context.l10n.issue_edit_issue_edit_commit,
                        onPress: () {
                          _editCommit(issue.id.toString(), issue.body);
                        },
                      ),
                      GSYFlexButton(
                        color: GSYColors.white,
                        text: context.l10n.issue_edit_issue_delete_commit,
                        onPress: () {
                          _deleteCommit(issue.id.toString());
                        },
                      ),
                      GSYFlexButton(
                        color: GSYColors.white,
                        text: context.l10n.issue_edit_issue_copy_commit,
                        onPress: () {
                          CommonUtils.copy(issue.body, context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            });
      },
    );
  }

  ///获取页面数据
  ///
  /// 页面刷新时：先拉头部，再并行拉 timeline，再拉 comments，
  /// 最终把 timeline（非 commented 类型）和 comments 按时间序合并展示。
  ///
  /// 注意：[GSYListState.handleRefresh] 会先消费当前 res，再看 res.next 追加一次，
  /// 因此本地 db 命中分支返回的 res 和 res.next() 返回的网络分支 res 都要各自合并 timeline，
  /// 否则会出现「本地 db 命中时能看到 timeline，网络 next() 覆盖时又消失」的一闪现象。
  _getDataLogic() async {
    if (page <= 1) {
      _getHeaderInfo();
      // 与 comments 并行拉取 timeline，仅第一页刷新
      await _refreshTimeline();
    }
    final res = await IssueRepository.getIssueCommentRequest(
        widget.userName, widget.reposName, widget.issueNum,
        page: page, needDb: page <= 1);
    if (page <= 1) {
      _decorateWithTimeline(res);
      _wrapNextWithTimeline(res);
    }
    return res;
  }

  /// 拉 timeline，缓存到 [_timelineEvents]，后续通过 [_decorateWithTimeline] 注入 dataList。
  Future<void> _refreshTimeline() async {
    try {
      final res = await IssueRepository.getIssueTimelineRequest(
          widget.userName, widget.reposName, widget.issueNum);
      if (res.result && res.data is List<IssueTimelineEvent>) {
        _timelineEvents = List<IssueTimelineEvent>.from(res.data);
      } else {
        _timelineEvents = <IssueTimelineEvent>[];
      }
    } catch (_) {
      _timelineEvents = <IssueTimelineEvent>[];
    }
  }

  /// 把非 commented 的 timeline 事件按时间序穿插到 comments 列表中。
  ///
  /// 说明：
  /// - 评论仍以 [Issue] 形式承接（复用 comments 端点旧模型）。
  /// - 事件以 [IssueTimelineEvent] 形式承接。
  /// - _renderEventItem 通过 runtimeType 分发到不同 widget。
  void _decorateWithTimeline(dynamic res) {
    if (res == null || res.data is! List) return;
    final rawList = res.data as List;
    final comments = rawList.whereType<Issue>().toList();
    if (comments.isEmpty && rawList.isNotEmpty) return; // 已合并过则跳过
    final events = _timelineEvents.where((e) => e.event != 'commented');
    final merged = <dynamic>[...comments, ...events];
    merged.sort((a, b) {
      final ta = _timeOf(a);
      final tb = _timeOf(b);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    // 直接改写 res.data，让 GSYListState.resolveRefreshResult 一次性 addAll
    res.data = merged;
  }

  /// 包一层 res.next：让 handleRefresh 在追加网络分支时也合并 timeline，
  /// 避免网络 res 覆盖掉已经合并好的 db res。
  void _wrapNextWithTimeline(dynamic res) {
    if (res == null) return;
    final original = res.next;
    if (original == null) return;
    res.next = () async {
      final resNext = await original();
      _decorateWithTimeline(resNext);
      return resNext;
    };
  }

  DateTime? _timeOf(dynamic v) {
    if (v is Issue) return v.createdAt;
    if (v is IssueTimelineEvent) return v.createdAt;
    return null;
  }

  ///获取头部数据
  ///
  /// 除了拉 issue payload 本身之外，如果发现这个 issue 其实是 PR
  /// （`issue.pullRequest != null`），额外并发一次 /pulls/:n，把 merged /
  /// mergeable / draft / head / base / additions / deletions / commits /
  /// requestedReviewers 塞进 [IssueHeaderViewModel]。失败不阻塞主 header。
  _getHeaderInfo() {
    IssueRepository.getIssueInfoRequest(
            widget.userName, widget.reposName, widget.issueNum)
        .then((res) {
      if (res != null && res.result) {
        _resolveHeaderInfo(res);
        _maybeFetchPullRequest(res.data);
        return res.next?.call();
      }
      return Future.value(null);
    }).then((res) {
      if (res != null && res.result) {
        _resolveHeaderInfo(res);
        _maybeFetchPullRequest(res.data);
      }
    });
  }

  /// 若当前 issue 其实是 PR，则拉一次 pull detail 并合入 header viewModel。
  void _maybeFetchPullRequest(Issue? issue) {
    if (issue == null) return;
    if (issue.pullRequest == null) return;
    final number = issue.number;
    if (number == null) return;
    IssueRepository.getPullRequestDetailRequest(
      widget.userName ?? '',
      widget.reposName ?? '',
      number,
    ).then((res) {
      if (!mounted) return;
      if (res == null || res.result != true) return;
      setState(() {
        issueHeaderViewModel.pullRequest = res.data as PullRequest?;
      });
    });
  }

  ///数据转化显示
  _resolveHeaderInfo(res) {
    Issue? issue = res.data;
    setState(() {
      // 保留已加载的 PR 详情，避免二次拉 header 时被 fromMap 清掉
      final prevPullRequest = issueHeaderViewModel.pullRequest;
      issueHeaderViewModel = IssueHeaderViewModel.fromMap(issue!);
      issueHeaderViewModel.pullRequest = prevPullRequest;
      htmlUrl = issue.htmlUrl;
      headerStatus = true;
    });
  }

  /// issue 头部 reaction 加/减
  ///
  /// 说明：GitHub REST 删除 reaction 需要 reactionId（issue 级 reaction 列表
  /// 端点里才能拿到），此处交互简化为「点击 chip 加、长按 chip 减」，长按删除
  /// 采取「本地即时扣减 + 触发头部刷新」的乐观策略，服务端最终一致以头部返回为准。
  Future<void> _onIssueReactionToggle(String content, bool isAdd) async {
    final failedText = context.l10n.issue_reaction_failed;
    final current = issueHeaderViewModel.reactions ?? Reactions.empty();
    setState(() {
      issueHeaderViewModel.reactions =
          current.increment(content, isAdd ? 1 : -1);
    });
    if (!isAdd) {
      // 无 reactionId，退化为拉一次头部对齐服务端
      _getHeaderInfo();
      return;
    }
    final res = await IssueRepository.addIssueReactionRequest(
        widget.userName, widget.reposName, widget.issueNum, content);
    if (res == null || res.result != true) {
      setState(() {
        issueHeaderViewModel.reactions = current;
      });
      showToast(failedText);
    } else {
      _getHeaderInfo();
    }
  }

  /// 单条评论的 reaction 加/减
  ///
  /// 说明：删除 comment reaction 需要 reactionId（`/issues/comments/{id}/reactions`
  /// GET 才能拿到）。此处采用与头部相同的乐观策略：add 走 POST，remove 只做本地态。
  Future<void> _onCommentReactionToggle(
      Issue comment, String content, bool isAdd) async {
    final current = comment.reactions ?? Reactions.empty();
    setState(() {
      comment.reactions = current.increment(content, isAdd ? 1 : -1);
    });
    if (!isAdd || comment.id == null) return;
    final res = await IssueRepository.addCommentReactionRequest(
        widget.userName, widget.reposName, comment.id, content);
    if (res == null || res.result != true) {
      setState(() {
        comment.reactions = current;
      });
    }
  }

  ///编辑回复
  _editCommit(id, content) {
    Navigator.pop(context);
    String? contentData = content;
    issueInfoValueControl = TextEditingController(text: contentData);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      context.l10n.issue_edit_issue,
      null,
      (contentValue) {
        contentData = contentValue;
      },
      () {
        if (contentData == null || contentData!.trim().isEmpty) {
          showToast(context.l10n.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueRepository.editCommentRequest(widget.userName, widget.reposName,
            widget.issueNum, id, {"body": contentData}).then((result) {
          showRefreshLoading();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      valueController: issueInfoValueControl,
      needTitle: false,
    );
  }

  ///删除回复
  _deleteCommit(id) {
    Navigator.pop(context);
    CommonUtils.showLoadingDialog(context);
    //提交修改
    IssueRepository.deleteCommentRequest(
            widget.userName, widget.reposName, widget.issueNum, id)
        .then((result) {
      Navigator.pop(context);
      showRefreshLoading();
    });
  }

  ///编译 issue
  _editIssue() {
    String? title = issueHeaderViewModel.issueComment;
    String? content = issueHeaderViewModel.issueDesHtml;
    issueInfoTitleControl = TextEditingController(text: title);
    issueInfoValueControl = TextEditingController(text: content);
    //编译Issue Info
    CommonUtils.showEditDialog(
      context,
      context.l10n.issue_edit_issue,
      (titleValue) {
        title = titleValue;
      },
      (contentValue) {
        content = contentValue;
      },
      () {
        if (title == null || title!.trim().isEmpty) {
          showToast(context.l10n.issue_edit_issue_title_not_be_null);
          return;
        }
        if (content == null || content!.trim().isEmpty) {
          showToast(context.l10n.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交修改
        IssueRepository.editIssueRequest(widget.userName, widget.reposName,
            widget.issueNum, {"title": title, "body": content}).then((result) {
          _getHeaderInfo();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      titleController: issueInfoTitleControl,
      valueController: issueInfoValueControl,
      needTitle: true,
    );
  }

  ///回复 issue
  _replyIssue() {
    //回复 Info
    issueInfoTitleControl = TextEditingController(text: "");
    issueInfoValueControl = TextEditingController(text: "");
    String? content = "";
    CommonUtils.showEditDialog(
      context,
      context.l10n.issue_reply_issue,
      null,
      (replyContent) {
        content = replyContent;
      },
      () {
        if (content == null || content?.trim().isEmpty == true) {
          showToast(context.l10n.issue_edit_issue_content_not_be_null);
          return;
        }
        CommonUtils.showLoadingDialog(context);
        //提交评论
        IssueRepository.addIssueCommentRequest(
                widget.userName, widget.reposName, widget.issueNum, content)
            .then((result) {
          showRefreshLoading();
          Navigator.pop(context);
          Navigator.pop(context);
        });
      },
      needTitle: false,
      titleController: issueInfoTitleControl,
      valueController: issueInfoValueControl,
    );
  }

  ///获取底部状态控件显示
  _getBottomWidget() {
    List<Widget> bottomWidget = (!headerStatus)
        ? []
        : <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _replyIssue();
                  },
                  child: Text(context.l10n.issue_reply,
                      style: GSYConstant.smallText),
                ),
                Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                TextButton(
                  onPressed: () {
                    _editIssue();
                  },
                  child: Text(context.l10n.issue_edit,
                      style: GSYConstant.smallText),
                ),
                Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                TextButton(
                    onPressed: () {
                      CommonUtils.showLoadingDialog(context);
                      IssueRepository.editIssueRequest(
                          widget.userName, widget.reposName, widget.issueNum, {
                        "state": (issueHeaderViewModel.state == "closed")
                            ? 'open'
                            : 'closed'
                      }).then((result) {
                        _getHeaderInfo();
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                        (issueHeaderViewModel.state == 'closed')
                            ? context.l10n.issue_open
                            : context.l10n.issue_close,
                        style: GSYConstant.smallText)),
                Container(
                    width: 0.3,
                    height: 30.0,
                    color: GSYColors.subLightTextColor),
                TextButton(
                    onPressed: () {
                      CommonUtils.showLoadingDialog(context);
                      IssueRepository.lockIssueRequest(
                              widget.userName,
                              widget.reposName,
                              widget.issueNum,
                              issueHeaderViewModel.locked)
                          .then((result) {
                        _getHeaderInfo();
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                        issueHeaderViewModel.locked!
                            ? context.l10n.issue_unlock
                            : context.l10n.issue_lock,
                        style: GSYConstant.smallText)),
              ],
            )
          ];
    return bottomWidget;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    Widget? widgetContent =
        (widget.needHomeIcon) ? null : GSYCommonOptionWidget(url: htmlUrl);
    return Scaffold(
      persistentFooterButtons: _getBottomWidget(),
      appBar: AppBar(
        title: GSYTitleBar(
          widget.reposName,
          rightWidget: widgetContent,
          needRightLocalIcon: widget.needHomeIcon,
          iconData: GSYICons.HOME,
          onRightIconPressed: (_) {
            NavigatorUtils.goReposDetail(
                context, widget.userName, widget.reposName);
          },
        ),
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
