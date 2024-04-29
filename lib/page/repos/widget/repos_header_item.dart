import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/CommonListDataType.dart';
import 'package:gsy_github_app_flutter/model/RepositoryQL.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';

/// 仓库详情信息头控件
/// Created by guoshuyu
/// Date: 2018-07-18

class ReposHeaderItem extends StatefulWidget {
  final ReposHeaderViewModel reposHeaderViewModel;

  final ValueChanged<Size>? layoutListener;

  const ReposHeaderItem(this.reposHeaderViewModel, {super.key, this.layoutListener});

  @override
  _ReposHeaderItemState createState() => _ReposHeaderItemState();
}

class _ReposHeaderItemState extends State<ReposHeaderItem> {
  final GlobalKey layoutKey = GlobalKey();
  final GlobalKey layoutTopicContainerKey = GlobalKey();
  final GlobalKey layoutLastTopicKey = GlobalKey();

  double widgetHeight = 0;

  ///底部仓库状态信息，比如star数量等
  _getBottomItem(IconData icon, String text, onPressed) {
    return Expanded(
      child: Center(
          child: RawMaterialButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
              constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
              onPressed: onPressed,
              child: GSYIConText(
                icon,
                text,
                GSYConstant.smallSubLightText.copyWith(shadows: [
                  const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                ]),
                GSYColors.subLightTextColor,
                15.0,
                padding: 3.0,
                mainAxisAlignment: MainAxisAlignment.center,
              ))),
    );
  }

  _renderTopicItem(BuildContext context, String item, index) {
    return RawMaterialButton(
        key: index == widget.reposHeaderViewModel.topics!.length - 1
            ? layoutLastTopicKey
            : null,
        onPressed: () {
          NavigatorUtils.gotoCommonList(context, item, "repository", CommonListDataType.topics,
              userName: item, reposName: "");
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(0.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        child: Container(
          padding:
              const EdgeInsets.only(left: 5.0, right: 5.0, top: 2.5, bottom: 2.5),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
            color: Colors.white30,
            border: Border.all(color: Colors.white30, width: 0.0),
          ),
          child: Text(
            item,
            style: GSYConstant.smallSubLightText.copyWith(shadows: [
              const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
            ]),
          ),
        ));
  }

  ///话题组控件
  _renderTopicGroup(BuildContext context) {
    if (widget.reposHeaderViewModel.topics == null ||
        widget.reposHeaderViewModel.topics!.isEmpty) {
      return Container(
        key: layoutTopicContainerKey,
      );
    }
    List<Widget> list = [];
    for (int i = 0; i < widget.reposHeaderViewModel.topics!.length; i++) {
      var item = widget.reposHeaderViewModel.topics![i]!;
      list.add(_renderTopicItem(context, item, i));
    }
    return Container(
      key: layoutTopicContainerKey,
      alignment: Alignment.topLeft,
      //margin: EdgeInsets.only(top: 5.0),
      child: Wrap(
        spacing: 10.0,
        runSpacing: 5.0,
        children: list,
      ),
    );
  }

  ///仓库创建和提交状态信息
  _getInfoText(BuildContext context) {
    String createStr = widget.reposHeaderViewModel.repositoryIsFork!
        ? '${GSYLocalizations.i18n(context)!.repos_fork_at}${widget.reposHeaderViewModel.repositoryParentName!}\n'
        : "${GSYLocalizations.i18n(context)!.repos_create_at}${widget.reposHeaderViewModel.created_at}\n";

    String updateStr = GSYLocalizations.i18n(context)!.repos_last_commit +
        widget.reposHeaderViewModel.push_at;

    return createStr + updateStr;
  }

  ///顶部信息
  _renderTopNameInfo() {
    return Row(
      children: <Widget>[
        ///用户名
        RawMaterialButton(
          constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
          padding: const EdgeInsets.all(0.0),
          onPressed: () {
            NavigatorUtils.goPerson(
                context, widget.reposHeaderViewModel.ownerName);
          },
          child: Text(widget.reposHeaderViewModel.ownerName!,
              style: GSYConstant.normalTextActionWhiteBold.copyWith(shadows: [
                const BoxShadow(color: Colors.black, offset: Offset(0.5, 0.5))
              ])),
        ),
        Text(" / ",
            style: GSYConstant.normalTextMitWhiteBold.copyWith(shadows: [
              const BoxShadow(color: Colors.black, offset: Offset(0.5, 0.5))
            ])),

        ///仓库名,
        Expanded(
            child: Text(widget.reposHeaderViewModel.repositoryName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GSYConstant.normalTextMitWhiteBold.copyWith(shadows: [
                  const BoxShadow(color: Colors.black, offset: Offset(0.5, 0.5))
                ])))
      ],
    );
  }

  ///次要信息
  _renderSubInfo() {
    return Row(
      children: <Widget>[
        ///仓库语言
        Text(widget.reposHeaderViewModel.repositoryType ?? "--",
            style: GSYConstant.smallSubLightText.copyWith(shadows: [
              const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
            ])),
        const SizedBox(width: 5.3, height: 1.0),

        ///仓库大小
        Text(widget.reposHeaderViewModel.repositorySize,
            style: GSYConstant.smallSubLightText.copyWith(shadows: [
              const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
            ])),
        const SizedBox(width: 5.3, height: 1.0),

        ///仓库协议
        Expanded(
            child: Text(widget.reposHeaderViewModel.license ?? "--",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GSYConstant.smallSubLightText.copyWith(shadows: [
                  const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                ]))),
      ],
    );
  }

  ///仓库描述
  renderDes() {
    return Container(
        margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
        alignment: Alignment.topLeft,
        child: Text(
          CommonUtils.removeTextTag(
                  widget.reposHeaderViewModel.repositoryDes) ??
              "---",
          style: GSYConstant.smallSubLightText.copyWith(shadows: [
            const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
          ]),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ));
  }

  /// 右下角的信息
  renderRepoStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 6.0, bottom: 2.0, right: 5.0),
      alignment: Alignment.topRight,
      child: RawMaterialButton(
        onPressed: () {
          if (widget.reposHeaderViewModel.repositoryIsFork!) {
            NavigatorUtils.goReposDetail(
                context,
                widget.reposHeaderViewModel.repositoryParentUser,
                widget.reposHeaderViewModel.repositoryName);
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(0.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        child: Text(_getInfoText(context),
            style: widget.reposHeaderViewModel.repositoryIsFork!
                ? GSYConstant.smallActionLightText.copyWith(shadows: [
                    const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                  ])
                : GSYConstant.smallSubLightText.copyWith(shadows: [
                    const BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                  ])),
      ),
    );
  }

  ///底部仓库状态信息
  renderBottomInfo() {
    return Padding(
        padding: const EdgeInsets.all(0.0),

        ///创建数值状态
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ///star状态
            _getBottomItem(
              GSYICons.REPOS_ITEM_STAR,
              widget.reposHeaderViewModel.repositoryStar,
              () {
                NavigatorUtils.gotoCommonList(
                    context,
                    widget.reposHeaderViewModel.repositoryName,
                    "user",
                    CommonListDataType.repoStar,
                    userName: widget.reposHeaderViewModel.ownerName,
                    reposName: widget.reposHeaderViewModel.repositoryName);
              },
            ),

            Container(
              width: 0.3,
              height: 25.0,
              decoration: const BoxDecoration(
                  color: GSYColors.subLightTextColor,
                  boxShadow: [
                    BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                  ]),
            ),

            ///fork状态
            _getBottomItem(
              GSYICons.REPOS_ITEM_FORK,
              widget.reposHeaderViewModel.repositoryFork,
              () {
                NavigatorUtils.gotoCommonList(
                    context,
                    widget.reposHeaderViewModel.repositoryName,
                    "repository",
                    CommonListDataType.repoFork,
                    userName: widget.reposHeaderViewModel.ownerName,
                    reposName: widget.reposHeaderViewModel.repositoryName);
              },
            ),

            Container(
              width: 0.3,
              height: 25.0,
              decoration: const BoxDecoration(
                  color: GSYColors.subLightTextColor,
                  boxShadow: [
                    BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                  ]),
            ),

            ///订阅状态
            _getBottomItem(
              GSYICons.REPOS_ITEM_WATCH,
              widget.reposHeaderViewModel.repositoryWatch,
              () {
                NavigatorUtils.gotoCommonList(
                    context,
                    widget.reposHeaderViewModel.repositoryName,
                    "user",
                    CommonListDataType.repoWatcher,
                    userName: widget.reposHeaderViewModel.ownerName,
                    reposName: widget.reposHeaderViewModel.repositoryName);
              },
            ),

            Container(
              width: 0.3,
              height: 25.0,
              decoration: const BoxDecoration(
                  color: GSYColors.subLightTextColor,
                  boxShadow: [
                    BoxShadow(color: Colors.grey, offset: Offset(0.5, 0.5))
                  ]),
            ),

            ///issue状态
            _getBottomItem(
              GSYICons.REPOS_ITEM_ISSUE,
              widget.reposHeaderViewModel.repositoryIssue,
              () {
                if (widget.reposHeaderViewModel.allIssueCount == null ||
                    widget.reposHeaderViewModel.allIssueCount! <= 0) {
                  return;
                }
                StringList list = [
                  GSYLocalizations.i18n(context)!.repos_all_issue_count +
                      widget.reposHeaderViewModel.allIssueCount.toString(),
                  GSYLocalizations.i18n(context)!.repos_open_issue_count +
                      widget.reposHeaderViewModel.openIssuesCount.toString(),
                  GSYLocalizations.i18n(context)!.repos_close_issue_count +
                      (widget.reposHeaderViewModel.allIssueCount! -
                              widget.reposHeaderViewModel.openIssuesCount!)
                          .toString(),
                ];
                CommonUtils.showCommitOptionDialog(context, list, (index) {},
                    height: 150.0);
              },
            ),
          ],
        ));
  }

  @override
  void didUpdateWidget(ReposHeaderItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    ///如果存在tag，根据tag去判断，修复溢出
    Future.delayed(const Duration(seconds: 0), () {
      /// tag 所在 container
      RenderBox? renderBox2 =
          layoutTopicContainerKey.currentContext?.findRenderObject() as RenderBox?;

      var dy = renderBox2
              ?.localToGlobal(Offset.zero,
                  ancestor: layoutKey.currentContext!.findRenderObject()).dy ??
          0;
      var sizeTagContainer =
          layoutTopicContainerKey.currentContext?.size;
      var headerSize = layoutKey.currentContext?.size;
      if (dy > 0 && headerSize != null && sizeTagContainer != null) {
        /// 20是 card 的上下 padding
        var newSize = dy + sizeTagContainer.height + 20;
        if (widgetHeight != newSize && newSize > 0) {
          print("widget?.layoutListener?.call");
          widgetHeight = newSize;
          widget.layoutListener
              ?.call(Size(layoutKey.currentContext!.size!.width, widgetHeight));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: layoutKey,
      child: GSYCardItem(
        color: Theme.of(context).primaryColorDark,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          child: Container(
            ///背景头像
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(widget.reposHeaderViewModel.ownerPic ??
                    GSYICons.DEFAULT_REMOTE_PIC),
              ),
            ),
            child: BackdropFilter(
              ///高斯模糊
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10.0, top: 0.0, right: 10.0, bottom: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _renderTopNameInfo(),
                    _renderSubInfo(),

                    ///仓库描述
                    renderDes(),

                    ///创建状态
                    renderRepoStatus(),
                    const Divider(
                      color: GSYColors.subTextColor,
                    ),

                    ///底部信息
                    renderBottomInfo(),

                    ///底部tag
                    _renderTopicGroup(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReposHeaderViewModel {
  String? ownerName = '---';
  String? ownerPic;
  String? repositoryName = "---";
  String repositorySize = "---";
  String repositoryStar = "---";
  String repositoryFork = "---";
  String repositoryWatch = "---";
  String repositoryIssue = "---";
  String repositoryIssueClose = "";
  String repositoryIssueAll = "";
  String? repositoryType = "---";
  String? repositoryDes = "---";
  String repositoryLastActivity = "";
  String? repositoryParentName = "";
  String? repositoryParentUser = "";
  String created_at = "";
  String push_at = "";
  String? license = "";
  List<String?>? topics;
  int? allIssueCount = 0;
  int? openIssuesCount = 0;
  bool repositoryStared = false;
  bool repositoryForked = false;
  bool repositoryWatched = false;
  bool? repositoryIsFork = false;

  ReposHeaderViewModel();

  ReposHeaderViewModel.fromHttpMap(ownerName, reposName, RepositoryQL? map) {
    this.ownerName = ownerName;
    if (map == null || map.ownerName == null) {
      return;
    }
    ownerPic = map.ownerAvatarUrl;
    repositoryName = reposName;
    allIssueCount = map.issuesTotal;
    topics = map.topics;
    openIssuesCount = map.issuesOpen;
    repositoryStar = map.starCount != null ? map.starCount.toString() : "";
    repositoryFork = map.forkCount != null ? map.forkCount.toString() : "";
    repositoryWatch =
        map.watcherCount != null ? map.watcherCount.toString() : "";
    repositoryIssue =
        map.issuesOpen != null ? map.issuesOpen.toString() : "";
    //this.repositoryIssueClose = map.closedIssuesCount != null ? map.closed_issues_count.toString() : "";
    //this.repositoryIssueAll = map.all_issues_count != null ? map.all_issues_count.toString() : "";
    repositorySize =
        "${(map.size! / 1024.0).toString().substring(0, 3)}M";
    repositoryType = map.language;
    repositoryDes = map.shortDescriptionHTML;
    repositoryIsFork = map.isFork;
    license = map.license != null ? map.license : "";
    repositoryParentName =
        map.parent?.reposName;
    repositoryParentUser =
        map.parent?.ownerName;
    created_at = CommonUtils.getNewsTimeStr(DateTime.parse(map.createdAt!));
    push_at = CommonUtils.getNewsTimeStr((DateTime.parse(map.pushAt!)));
  }
}
