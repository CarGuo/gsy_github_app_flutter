import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/model/issue.dart';
import 'package:gsy_github_app_flutter/model/reactions.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/issue/widget/reactions_bar.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// Issue相关item
/// Created by guoshuyu
/// Date: 2018-07-19
class IssueItem extends StatelessWidget {
  final IssueItemViewModel issueItemViewModel;

  ///点击
  final GestureTapCallback? onPressed;

  ///长按
  final GestureTapCallback? onLongPress;

  ///是否需要底部状态
  final bool hideBottom;

  ///是否需要限制内容行数
  final bool limitComment;

  /// 点击 reaction chip 时的回调（仅评论卡片使用）
  final void Function(String content, bool isAdd)? onReactionToggle;

  const IssueItem(this.issueItemViewModel,
      {super.key,
      this.onPressed,
      this.onLongPress,
      this.hideBottom = false,
      this.limitComment = true,
      this.onReactionToggle});

  ///issue 底部状态
  _renderBottomContainer() {
    Color issueStateColor =
        issueItemViewModel.state == "open" ? Colors.green : Colors.red;
    return (hideBottom)
        ? Container()
        : Row(
            children: <Widget>[
              ///issue 关闭打开状态
              GSYIConText(
                GSYICons.ISSUE_ITEM_ISSUE,
                issueItemViewModel.state,
                TextStyle(
                  color: issueStateColor,
                  fontSize: GSYConstant.smallTextSize,
                ),
                issueStateColor,
                15.0,
                padding: 2.0,
              ),
              const Padding(padding: EdgeInsets.all(2.0)),

              ///issue标号
              Expanded(
                child: Text(issueItemViewModel.issueTag,
                    style: GSYConstant.smallSubText),
              ),

              ///评论数
              GSYIConText(
                GSYICons.ISSUE_ITEM_COMMENT,
                issueItemViewModel.commentCount,
                GSYConstant.smallSubText,
                GSYColors.subTextColor,
                15.0,
                padding: 2.0,
              ),
            ],
          );
  }

  ///评论内容
  Widget _renderCommentText(BuildContext context) {
    if (issueItemViewModel.minimized) {
      return Container(
        margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
        alignment: Alignment.topLeft,
        child: Text(
          context.l10n.issue_comment_minimized,
          style: GSYConstant.smallSubLightText
              .copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    return (limitComment)
        ? Container(
            margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
            alignment: Alignment.topLeft,
            child: Text(
              issueItemViewModel.issueComment,
              style: GSYConstant.smallSubText,
              maxLines: limitComment ? 2 : 1000,
            ),
          )
        : GSYMarkdownWidget(
            markdownData: issueItemViewModel.issueComment,
            baseUrl: "",
            shrinkWrap: true,
            scroll: false,
          );
  }

  Widget _renderMetaBadges(BuildContext context) {
    final l = context.l10n;
    final badges = <Widget>[];
    final assoc = issueItemViewModel.authorAssociation;
    if (assoc != null && assoc.isNotEmpty && assoc != 'NONE') {
      badges.add(_smallBadge(_prettifyAssociation(context, assoc),
          color: GSYColors.subLightTextColor));
    }
    if (issueItemViewModel.isBot) {
      badges.add(
          _smallBadge(l.issue_badge_bot, color: GSYColors.subLightTextColor));
    }
    if (issueItemViewModel.edited) {
      badges.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('· ${l.issue_badge_edited}',
            style: GSYConstant.smallSubLightText),
      ));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: badges),
    );
  }

  Widget _smallBadge(String text, {required Color color}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: GSYColors.subTextColor)),
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

  Widget _renderReactions() {
    final r = issueItemViewModel.reactions;
    if (r == null || (r.totalCount == 0 && onReactionToggle == null)) {
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
    return GSYCardItem(
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 5.0, top: 5.0, right: 10.0, bottom: 8.0),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ///头像
                GSYUserIconWidget(
                    width: 30.0,
                    height: 30.0,
                    image: issueItemViewModel.actionUserPic,
                    onPressed: () {
                      NavigatorUtils.goPerson(
                          context, issueItemViewModel.actionUser);
                    }),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          ///用户名
                          Flexible(
                              child: Text(issueItemViewModel.actionUser!,
                                  style: GSYConstant.smallTextBold,
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 6),
                          Expanded(child: _renderMetaBadges(context)),
                          Text(
                            issueItemViewModel.actionTime,
                            style: GSYConstant.smallSubText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      ///评论内容
                      _renderCommentText(context),

                      ///reactions
                      _renderReactions(),

                      const Padding(
                        padding: EdgeInsets.only(
                            left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                      ),
                      _renderBottomContainer(),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

class IssueItemViewModel {
  String actionTime = "---";
  String? actionUser = "---";
  String? actionUserPic;

  String issueComment = "---";
  String commentCount = "---";
  String? state = "---";
  String issueTag = "---";
  String number = "---";
  String id = "";

  /// 官方能力对齐字段（评论专属）
  String? authorAssociation;
  bool isBot = false;
  bool edited = false;
  bool minimized = false;
  Reactions? reactions;

  IssueItemViewModel();

  IssueItemViewModel.fromMap(Issue issueMap, {needTitle = true}) {
    String fullName = CommonUtils.getFullName(issueMap.repoUrl);
    actionTime = CommonUtils.getNewsTimeStr(issueMap.createdAt!);
    actionUser = issueMap.user!.login;
    actionUserPic = issueMap.user!.avatar_url;
    if (needTitle) {
      issueComment = "$fullName- ${issueMap.title!}";
      commentCount = issueMap.commentNum.toString();
      state = issueMap.state;
      issueTag = "#${issueMap.number}";
      number = issueMap.number.toString();
    } else {
      issueComment = issueMap.body ?? "";
      id = issueMap.id.toString();
    }
    authorAssociation = issueMap.authorAssociation;
    isBot = issueMap.user?.type == 'Bot' ||
        (issueMap.user?.login ?? '').endsWith('[bot]');
    edited = issueMap.updatedAt != null &&
        issueMap.createdAt != null &&
        issueMap.updatedAt!.isAfter(issueMap.createdAt!);
    reactions = issueMap.reactions;
    // 简易折叠近似：REST 没有 isMinimized，规则： -1 计数 >= 4 且大于其它任意 reaction。
    final r = issueMap.reactions;
    minimized = r != null &&
        r.minusOne >= 4 &&
        r.minusOne >= r.plusOne &&
        r.minusOne >= r.heart &&
        r.minusOne >= r.hooray &&
        r.minusOne >= r.laugh &&
        r.minusOne >= r.rocket;
  }
}
