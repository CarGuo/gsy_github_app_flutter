import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/issue_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/scoped_model/scoped_model.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/RepositoryQL.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_issue_list_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_readme_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_file_list_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repostory_detail_info_page.dart';
import 'package:gsy_github_app_flutter/page/repos/scope/repos_detail_model.dart';
import 'package:gsy_github_app_flutter/widget/gsy_bottom_action_bar.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';

/**
 * 仓库详情
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class RepositoryDetailPage extends StatefulWidget {
  ///用户名
  final String? userName;

  ///仓库名
  final String? reposName;

  RepositoryDetailPage(this.userName, this.reposName);

  @override
  _RepositoryDetailPageState createState() => _RepositoryDetailPageState();
}

class _RepositoryDetailPageState extends State<RepositoryDetailPage>
    with SingleTickerProviderStateMixin {
  /// 文件列表页的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<RepositoryDetailFileListPageState> fileListKey =
      new GlobalKey<RepositoryDetailFileListPageState>();

  /// 详情信息页的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<ReposDetailInfoPageState> infoListKey =
      new GlobalKey<ReposDetailInfoPageState>();

  /// readme 页面的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<RepositoryDetailReadmePageState> readmeKey =
      new GlobalKey<RepositoryDetailReadmePageState>();

  /// issue 列表页的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<RepositoryDetailIssuePageState> issueListKey =
      new GlobalKey<RepositoryDetailIssuePageState>();

  ///动画控制器，用于底部发布 issue 按键动画
  late AnimationController animationController;

  ///仓库的详情数据实体
  ReposDetailModel? reposDetailModel;

  ///渲染 Tab 的 Item
  _renderTabItem() {
    var itemList = [
      GSYLocalizations.i18n(context)!.repos_tab_info,
      GSYLocalizations.i18n(context)!.repos_tab_readme,
      GSYLocalizations.i18n(context)!.repos_tab_issue,
      GSYLocalizations.i18n(context)!.repos_tab_file,
    ];
    renderItem(String item, int i) {
      return new Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: new Text(
            item,
            style: GSYConstant.smallTextWhite,
            maxLines: 1,
          ));
    }

    List<Widget> list = [];
    for (int i = 0; i < itemList.length; i++) {
      list.add(renderItem(itemList[i], i));
    }
    return list;
  }

  ///title 显示更多弹出item
  _getMoreOtherItem(RepositoryQL? repository) {
    return [
      ///Release Page
      new GSYOptionModel(GSYLocalizations.i18n(context)!.repos_option_release,
          GSYLocalizations.i18n(context)!.repos_option_release, (model) {
        String releaseUrl = "";
        String tagUrl = "";
        if (infoListKey.currentState == null) {
          releaseUrl = GSYConstant.app_default_share_url;
          tagUrl = GSYConstant.app_default_share_url;
        } else {
          releaseUrl = repository == null
              ? GSYConstant.app_default_share_url
              : repository.htmlUrl! + "/releases";
          tagUrl = repository == null
              ? GSYConstant.app_default_share_url
              : repository.htmlUrl! + "/tags";
        }
        NavigatorUtils.goReleasePage(
            context, widget.userName, widget.reposName, releaseUrl, tagUrl);
      }),

      ///Branch Page
      new GSYOptionModel(GSYLocalizations.i18n(context)!.repos_option_branch,
          GSYLocalizations.i18n(context)!.repos_option_branch, (model) {
        if (reposDetailModel!.branchList!.length == 0) {
          return;
        }
        CommonUtils.showCommitOptionDialog(
            context, reposDetailModel?.branchList, (value) {
          reposDetailModel!.currentBranch =
              reposDetailModel!.branchList![value];
          if (infoListKey.currentState != null &&
              infoListKey.currentState!.mounted) {
            infoListKey.currentState!.showRefreshLoading();
          }
          if (fileListKey.currentState != null &&
              fileListKey.currentState!.mounted) {
            fileListKey.currentState!.showRefreshLoading();
          }
          if (readmeKey.currentState != null &&
              readmeKey.currentState!.mounted) {
            readmeKey.currentState!.refreshReadme();
          }
        });
      }),
    ];
  }

  ///创建 issue
  _createIssue() {
    String title = "";
    String content = "";
    CommonUtils.showEditDialog(
        context, GSYLocalizations.i18n(context)!.issue_edit_issue,
        (titleValue) {
      title = titleValue;
    }, (contentValue) {
      content = contentValue;
    }, () {
      if (title.trim().length == 0) {
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context)!
                .issue_edit_issue_title_not_be_null);
        return;
      }
      if (content.trim().length == 0) {
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context)!
                .issue_edit_issue_content_not_be_null);
        return;
      }
      CommonUtils.showLoadingDialog(context);
      //提交修改
      IssueDao.createIssueDao(widget.userName, widget.reposName,
          {"title": title, "body": content}).then((result) {
        if (issueListKey.currentState != null &&
            issueListKey.currentState!.mounted) {
          issueListKey.currentState!.showRefreshLoading();
        }

        Navigator.pop(context);
        Navigator.pop(context);
      });
    },
        needTitle: true,
        titleController: new TextEditingController(),
        valueController: new TextEditingController());
  }

  @override
  void initState() {
    super.initState();

    ///仓库的详情数据实体
    reposDetailModel ??= new ReposDetailModel(
        userName: widget.userName, reposName: widget.reposName);

    reposDetailModel!.getBranchList();

    ///悬浮按键动画控制器
    animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    ///跨 tab 共享状态
    return new ScopedModel<ReposDetailModel>(
      model: reposDetailModel!,
      child: new ScopedModelDescendant<ReposDetailModel>(
        builder: (context, child, model) {
          Widget widgetContent =
              (model?.repository != null && model?.repository!.htmlUrl != null)
                  ? new GSYCommonOptionWidget(
                      url: model?.repository?.htmlUrl,
                      otherList: _getMoreOtherItem(model?.repository))
                  : Container();

          ///绘制顶部 tab 控件
          return new GSYTabBarWidget(
            type: TabType.top,
            tabItems: _renderTabItem(),
            resizeToAvoidBottomPadding: false,
            //footerButtons: model.footerButtons,
            tabViews: [
              new ReposDetailInfoPage(widget.userName, widget.reposName,
                  key: infoListKey),
              new RepositoryDetailReadmePage(widget.userName, widget.reposName,
                  key: readmeKey),
              new RepositoryDetailIssuePage(
                widget.userName,
                widget.reposName,
                key: issueListKey,
              ),
              new RepositoryDetailFileListPage(
                  widget.userName, widget.reposName,
                  key: fileListKey),
            ],
            backgroundColor: GSYColors.primarySwatch,
            indicatorColor: GSYColors.white,
            title: new GSYTitleBar(
              widget.reposName,
              rightWidget: widgetContent,
            ),
            onPageChanged: (index) {
              reposDetailModel!.currentIndex = index;
            },

            ///悬浮按键，增加出现动画
            floatingActionButton: ScaleTransition(
              //scale: CurvedAnimation(parent: animationController, curve: Curves.bounceInOut),
              scale: CurvedAnimation(
                  parent: animationController, curve: Curves.decelerate),
              child: FloatingActionButton(
                onPressed: () {
                  if (model?.repository?.hasIssuesEnabled == false) {
                    Fluttertoast.showToast(
                        msg: GSYLocalizations.i18n(context)!
                            .repos_no_support_issue);
                    return;
                  }
                  _createIssue();
                },
                child: Icon(Icons.add),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),

            ///悬浮按键位置
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,

            ///底部bar，增加对悬浮按键的缺省容器处理
            bottomBar: GSYBottomAppBar(
                color: GSYColors.white,
                fabLocation: FloatingActionButtonLocation.endDocked,
                shape: CircularNotchedRectangle(),
                rowContents: (model?.footerButtons == null)
                    ? [
                        SizedBox.fromSize(
                          size: Size(0, 0),
                        )
                      ]
                    : model?.footerButtons!.length == 0
                        ? [
                            SizedBox.fromSize(
                              size: Size(0, 0),
                            )
                          ]
                        : model?.footerButtons),
          );
        },
      ),
    );
  }
}

///底部状态实体
class BottomStatusModel {
  final String watchText;
  final String starText;
  final IconData watchIcon;
  final IconData starIcon;

  BottomStatusModel(
      this.watchText, this.starText, this.watchIcon, this.starIcon);
}
