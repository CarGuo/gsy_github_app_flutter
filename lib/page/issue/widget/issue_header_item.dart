import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/label.dart';
import 'package:gsy_github_app_flutter/model/reactions.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/label_chip.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/reactions_bar.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// Issue 详情头
/// Created by guoshuyu
/// on 2018/7/21.

class IssueHeaderItem extends StatelessWidget {
  final IssueHeaderViewModel issueHeaderViewModel;

  final VoidCallback? onPressed;

  /// 点击 reaction chip 时的回调
  /// (content, isAdd) 分别是 8 种官方 reaction 之一与增/减语义
  final void Function(String content, bool isAdd)? onReactionToggle;

  const IssueHeaderItem(
    this.issueHeaderViewModel, {
    super.key,
    this.onPressed,
    this.onReactionToggle,
  });

  _renderBottomContainer() {
    Color issueStateColor =
        issueHeaderViewModel.state == "open" ? Colors.green : Colors.red;

    ///底部Issue状态
    Widget bottomContainer = Row(
      children: <Widget>[
        ///issue 关闭打开状态
        GSYIConText(
          GSYICons.ISSUE_ITEM_ISSUE,
          issueHeaderViewModel.state,
          TextStyle(
            color: issueStateColor,
            fontSize: GSYConstant.smallTextSize,
          ),
          issueStateColor,
          15.0,
          padding: 2.0,
        ),
        const Padding(padding: EdgeInsets.all(2.0)),

        ///issue issue编码
        Text(issueHeaderViewModel.issueTag, style: GSYConstant.smallTextWhite),
        const Padding(padding: EdgeInsets.all(2.0)),

        ///issue 评论数
        GSYIConText(
          GSYICons.ISSUE_ITEM_COMMENT,
          issueHeaderViewModel.commentCount,
          GSYConstant.smallTextWhite,
          GSYColors.white,
          15.0,
          padding: 2.0,
        ),
      ],
    );
    return bottomContainer;
  }

  ///关闭操作人
  _renderCloseByText() {
    return (issueHeaderViewModel.closedBy == null ||
            issueHeaderViewModel.closedBy!.trim().isEmpty)
        ? Container()
        : Container(
            margin: const EdgeInsets.only(right: 5.0, top: 10.0, bottom: 10.0),
            alignment: Alignment.topRight,
            child: Text(
              "Close By ${issueHeaderViewModel.closedBy!}",
              style: GSYConstant.smallSubLightText,
            ));
  }

  /// author association 徽章
  Widget? _renderAuthorAssociation(BuildContext context) {
    final v = issueHeaderViewModel.authorAssociation;
    if (v == null || v.isEmpty || v == 'NONE') return null;
    // OWNER / MEMBER / COLLABORATOR / CONTRIBUTOR / FIRST_TIME_CONTRIBUTOR / MANNEQUIN
    final label = _prettifyAssociation(context, v);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.6),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  static String _prettifyAssociation(BuildContext context, String raw) {
    final l = context.l10n;
    switch (raw) {
      case 'OWNER':
        return l.issue_assoc_owner;
      case 'MEMBER':
        return l.issue_assoc_member;
      case 'COLLABORATOR':
        return l.issue_assoc_collaborator;
      case 'CONTRIBUTOR':
        return l.issue_assoc_contributor;
      case 'FIRST_TIME_CONTRIBUTOR':
        return l.issue_assoc_first_time_contributor;
      case 'FIRST_TIMER':
        return l.issue_assoc_first_timer;
      case 'MANNEQUIN':
        return l.issue_assoc_mannequin;
      default:
        return raw;
    }
  }

  /// labels 彩标行
  Widget _renderLabels() {
    return LabelChipList(labels: issueHeaderViewModel.labels);
  }

  /// assignees + milestone
  Widget _renderAssigneesAndMilestone() {
    final assignees = issueHeaderViewModel.assignees;
    final milestone = issueHeaderViewModel.milestoneTitle;
    final hasAssignees = assignees != null && assignees.isNotEmpty;
    final hasMilestone = milestone != null && milestone.isNotEmpty;
    if (!hasAssignees && !hasMilestone) return const SizedBox.shrink();
    final children = <Widget>[];
    if (hasAssignees) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            assignees.map((u) => u.login ?? '').where((s) => s.isNotEmpty).join(', '),
            style: GSYConstant.smallSubLightText.copyWith(color: Colors.white70),
          ),
        ],
      ));
    }
    if (hasMilestone) {
      children.add(Padding(
        padding: EdgeInsets.only(left: hasAssignees ? 12 : 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              milestone,
              style: GSYConstant.smallSubLightText.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 8, runSpacing: 4, children: children),
    );
  }

  Widget _renderReactions() {
    final r = issueHeaderViewModel.reactions;
    if (r == null || r.totalCount == 0 && onReactionToggle == null) {
      return const SizedBox.shrink();
    }
    return ReactionsBar(
      reactions: r,
      showAddEntry: onReactionToggle != null,
      onToggle: onReactionToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authorBadge = _renderAuthorAssociation(context);
    return GSYCardItem(
      color: Theme.of(context).primaryColor,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.all(0.0)),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ///头像
                  GSYUserIconWidget(
                      padding: const EdgeInsets.only(
                          top: 0.0, right: 10.0, left: 0.0),
                      width: 50.0,
                      height: 50.0,
                      image: issueHeaderViewModel.actionUserPic ??
                          GSYICons.DEFAULT_REMOTE_PIC,
                      onPressed: () {
                        NavigatorUtils.goPerson(
                            context, issueHeaderViewModel.actionUser);
                      }),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            ///名称
                            Flexible(
                                child: Text(
                              issueHeaderViewModel.actionUser!,
                              style: GSYConstant.normalTextWhite,
                              overflow: TextOverflow.ellipsis,
                            )),
                            if (authorBadge != null) authorBadge,
                            if (issueHeaderViewModel.isBot)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(context.l10n.issue_badge_bot,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10)),
                              ),
                            const Spacer(),

                            ///时间
                            Text(
                              issueHeaderViewModel.actionTime,
                              style: GSYConstant.smallSubLightText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.all(2.0)),

                        ///底部Item
                        _renderBottomContainer(),
                        Container(

                            ///评论标题
                            margin:
                                const EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft,

                            ///评论标题
                            child: Text(
                              issueHeaderViewModel.issueComment!,
                              style: GSYConstant.smallTextWhite,
                            )),
                        const Padding(
                          padding: EdgeInsets.only(
                              left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              ///labels
              _renderLabels(),

              ///assignees + milestone
              _renderAssigneesAndMilestone(),

              ///评论内容
              GSYMarkdownWidget(
                markdownData: issueHeaderViewModel.issueDesHtml,
                style: GSYMarkdownWidget.DARK_THEME,
                baseUrl: "",
                shrinkWrap: true,
                scroll: false,
              ),

              ///reactions
              _renderReactions(),

              ///close 用户
              _renderCloseByText()
            ],
          ),
        ),
      ),
    );
  }
}

class IssueHeaderViewModel {
  String actionTime = "---";
  String? actionUser = "---";
  String? actionUserPic;

  String? closedBy = "";
  bool? locked = false;
  String? issueComment = "---";
  String? issueDesHtml = "---";
  String commentCount = "---";
  String? state = "---";
  String issueDes = "---";
  String issueTag = "---";

  /// 官方能力对齐字段
  String? authorAssociation;
  bool isBot = false;
  List<Label>? labels;
  List<User>? assignees;
  String? milestoneTitle;
  Reactions? reactions;
  bool edited = false;

  IssueHeaderViewModel();

  IssueHeaderViewModel.fromMap(Issue issueMap) {
    actionTime = CommonUtils.getNewsTimeStr(issueMap.createdAt!);
    actionUser = issueMap.user!.login;
    actionUserPic = issueMap.user!.avatar_url;
    closedBy = issueMap.closeBy != null ? issueMap.closeBy!.login : "";
    locked = issueMap.locked;
    issueComment = issueMap.title;
    issueDesHtml =
        issueMap.bodyHtml ?? ((issueMap.body != null) ? issueMap.body : "");
    commentCount = "${issueMap.commentNum}";
    state = issueMap.state;
    issueDes = issueMap.body != null ? ": \n${issueMap.body!}" : '';
    issueTag = "#${issueMap.number}";

    authorAssociation = issueMap.authorAssociation;
    isBot = issueMap.user?.type == 'Bot' ||
        (issueMap.user?.login ?? '').endsWith('[bot]');
    labels = issueMap.labels;
    assignees = issueMap.assignees;
    milestoneTitle = issueMap.milestone?.title;
    reactions = issueMap.reactions;
    edited = issueMap.updatedAt != null &&
        issueMap.createdAt != null &&
        issueMap.updatedAt!.isAfter(issueMap.createdAt!);
  }
}
