import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/repository_ql.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_issue_list_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_detail_readme_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repository_file_list_page.dart';
import 'package:gsy_github_app_flutter/page/repos/repostory_detail_info_page.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_detail_provider.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_network_provider.dart';
import 'package:gsy_github_app_flutter/widget/gsy_bottom_action_bar.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:provider/provider.dart';

/// 仓库详情
/// Created by guoshuyu
/// Date: 2018-07-18
class RepositoryDetailPage extends StatefulWidget {
  ///用户名
  final String userName;

  ///仓库名
  final String reposName;

  const RepositoryDetailPage(this.userName, this.reposName, {super.key});

  @override
  _RepositoryDetailPageState createState() => _RepositoryDetailPageState();
}

class _RepositoryDetailPageState extends State<RepositoryDetailPage>
    with SingleTickerProviderStateMixin {
  /// 文件列表页的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<RepositoryDetailFileListPageState> fileListKey =
      GlobalKey<RepositoryDetailFileListPageState>();

  /// 详情信息页的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<ReposDetailInfoPageState> infoListKey =
      GlobalKey<ReposDetailInfoPageState>();

  /// readme 页面的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<RepositoryDetailReadmePageState> readmeKey =
      GlobalKey<RepositoryDetailReadmePageState>();

  /// issue 列表页的 GlobalKey ，可用于当前控件控制文件也行为
  GlobalKey<RepositoryDetailIssuePageState> issueListKey =
      GlobalKey<RepositoryDetailIssuePageState>();

  ///动画控制器，用于底部发布 issue 按键动画
  late AnimationController animationController;

  ///仓库的详情数据实体
  late ReposDetailProvider reposDetailProvider;

  ///渲染 Tab 的 Item
  _renderTabItem() {
    var itemList = [
      context.l10n.repos_tab_info,
      context.l10n.repos_tab_readme,
      context.l10n.repos_tab_issue,
      context.l10n.repos_tab_file,
    ];
    renderItem(String item, int i) {
      return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
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
      GSYOptionModel(
          context.l10n.repos_option_release, context.l10n.repos_option_release,
          (model) {
        String releaseUrl = "";
        String tagUrl = "";
        if (infoListKey.currentState == null) {
          releaseUrl = GSYConstant.app_default_share_url;
          tagUrl = GSYConstant.app_default_share_url;
        } else {
          releaseUrl = repository == null
              ? GSYConstant.app_default_share_url
              : "${repository.htmlUrl!}/releases";
          tagUrl = repository == null
              ? GSYConstant.app_default_share_url
              : "${repository.htmlUrl!}/tags";
        }
        NavigatorUtils.goReleasePage(
            context, widget.userName, widget.reposName, releaseUrl, tagUrl);
      }),

      ///Branch Page
      GSYOptionModel(
          context.l10n.repos_option_branch, context.l10n.repos_option_branch,
          (model) {
        if (reposDetailProvider.branchList!.isEmpty) {
          return;
        }
        CommonUtils.showCommitOptionDialog(
            context, reposDetailProvider.branchList, (value) {
          reposDetailProvider.currentBranch =
              reposDetailProvider.branchList![value];
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
  _createIssue(ReposDetailProvider provider) {
    String title = "";
    String content = "";
    CommonUtils.showEditDialog(context, context.l10n.issue_edit_issue,
        (titleValue) {
      title = titleValue;
    }, (contentValue) {
      content = contentValue;
    }, () {
      if (title.trim().isEmpty) {
        showToast(context.l10n.issue_edit_issue_title_not_be_null);
        return;
      }
      if (content.trim().isEmpty) {
        showToast(context.l10n.issue_edit_issue_content_not_be_null);
        return;
      }
      CommonUtils.showLoadingDialog(context);
      //提交修改
      provider
          .createIssueRequest({"title": title, "body": content}).then((result) {
        if (issueListKey.currentState != null &&
            issueListKey.currentState!.mounted) {
          issueListKey.currentState!.showRefreshLoading();
        }

        Navigator.pop(context);
        Navigator.pop(context);
      });
    },
        needTitle: true,
        titleController: TextEditingController(),
        valueController: TextEditingController());
  }

  @override
  void initState() {
    super.initState();

    ///仓库的详情数据实体
    reposDetailProvider = ReposDetailProvider(
        userName: widget.userName, reposName: widget.reposName);

    reposDetailProvider.getBranchList();

    ///悬浮按键动画控制器
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    ///跨 tab 共享状态
    ///这是只是为了展示 Provider 状态管理的 Demo，所以在应用里使用了多种不同的状态管理框架
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReposNetWorkProvider()),
        ChangeNotifierProxyProvider<ReposNetWorkProvider, ReposDetailProvider>(
          update: (context, network, previousMessages) =>
              previousMessages!..network = network,
          create: (BuildContext context) => reposDetailProvider,
        ),
      ],
      child: Consumer<ReposDetailProvider>(
          builder: (BuildContext context, provider, Widget? child) {
        Widget widgetContent = (provider.repository != null &&
                provider.repository!.htmlUrl != null)
            ? GSYCommonOptionWidget(
                url: provider.repository?.htmlUrl,
                otherList: _getMoreOtherItem(provider.repository))
            : Container();

        ///绘制顶部 tab 控件
        return GSYTabBarWidget(
          type: TabType.top,
          tabItems: _renderTabItem(),
          resizeToAvoidBottomPadding: false,
          //footerButtons: model.footerButtons,
          tabViews: [
            ReposDetailInfoPage(key: infoListKey),
            RepositoryDetailReadmePage(key: readmeKey),
            RepositoryDetailIssuePage(
              key: issueListKey,
            ),
            RepositoryDetailFileListPage(key: fileListKey),
          ],
          backgroundColor: GSYColors.primarySwatch,
          indicatorColor: GSYColors.white,
          title: GSYTitleBar(
            widget.reposName,
            rightWidget: widgetContent,
          ),
          onPageChanged: (index) {
            reposDetailProvider.currentIndex = index;
          },

          ///悬浮按键，增加出现动画
          floatingActionButton: ScaleTransition(
            //scale: CurvedAnimation(parent: animationController, curve: Curves.bounceInOut),
            scale: CurvedAnimation(
                parent: animationController, curve: Curves.decelerate),
            child: FloatingActionButton(
              onPressed: () {
                if (provider.repository?.hasIssuesEnabled == false) {
                  showToast(context.l10n.repos_no_support_issue);
                  return;
                }
                _createIssue(provider);
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            ),
          ),

          ///悬浮按键位置
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

          ///底部bar，增加对悬浮按键的缺省容器处理
          bottomBar: GSYBottomAppBar(
              color: GSYColors.white,
              fabLocation: FloatingActionButtonLocation.endDocked,
              shape: const CircularNotchedRectangle(),
              rowContents: (provider.footerButtons == null)
                  ? [
                      SizedBox.fromSize(
                        size: const Size(0, 0),
                      )
                    ]
                  : provider.footerButtons!.isEmpty == true
                      ? [
                          SizedBox.fromSize(
                            size: const Size(0, 0),
                          )
                        ]
                      : provider.footerButtons),
        );
      }),
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
