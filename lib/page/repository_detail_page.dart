import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/issue_dao.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/model/Repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/repository_detail_issue_list_page.dart';
import 'package:gsy_github_app_flutter/page/repository_detail_readme_page.dart';
import 'package:gsy_github_app_flutter/page/repository_file_list_page.dart';
import 'package:gsy_github_app_flutter/page/repostory_detail_info_page.dart';
import 'package:gsy_github_app_flutter/widget/anima/curves_bezier.dart';
import 'package:gsy_github_app_flutter/widget/gsy_bottom_action_bar.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:scoped_model/scoped_model.dart';

/**
 * 仓库详情
 * Created by guoshuyu
 * Date: 2018-07-18
 */
class RepositoryDetailPage extends StatefulWidget {
  ///用户名
  final String userName;

  ///仓库名
  final String reposName;

  RepositoryDetailPage(this.userName, this.reposName);

  @override
  _RepositoryDetailPageState createState() => _RepositoryDetailPageState();
}

class _RepositoryDetailPageState extends State<RepositoryDetailPage>

    ///混入动画需求的 Ticker
    with
        SingleTickerProviderStateMixin {
  /// 仓库底部状态，如 star、watch 等等
  BottomStatusModel bottomStatusModel;

  /// 仓库底部状态，如 star、watch 控件的显示
  final TarWidgetControl tarBarControl = new TarWidgetControl();

  ///仓库的详情数据实体
  final ReposDetailModel reposDetailModel = new ReposDetailModel();

  ///配置标题栏右侧控件显示
  final OptionControl titleOptionControl = new OptionControl();

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
  AnimationController animationController;

  ///分支数据列表
  List<String> branchList = new List();

  ///获取网络端仓库的star等状态
  _getReposStatus() async {
    var result = await ReposDao.getRepositoryStatusDao(
        widget.userName, widget.reposName);
    String watchText = result.data["watch"] ? "UnWatch" : "Watch";
    String starText = result.data["star"] ? "UnStar" : "Star";
    IconData watchIcon = result.data["watch"]
        ? GSYICons.REPOS_ITEM_WATCHED
        : GSYICons.REPOS_ITEM_WATCH;
    IconData starIcon = result.data["star"]
        ? GSYICons.REPOS_ITEM_STARED
        : GSYICons.REPOS_ITEM_STAR;
    BottomStatusModel model = new BottomStatusModel(watchText, starText,
        watchIcon, starIcon, result.data["watch"], result.data["star"]);
    setState(() {
      bottomStatusModel = model;
      tarBarControl.footerButton = _getBottomWidget();
    });
  }

  ///获取分支数据
  _getBranchList() async {
    var result =
        await ReposDao.getBranchesDao(widget.userName, widget.reposName);
    if (result != null && result.result) {
      setState(() {
        branchList = result.data;
      });
    }
  }

  _refresh() {
    this._getReposStatus();
  }

  ///绘制底部状态 item
  _renderBottomItem(var text, var icon, var onPressed) {
    return new FlatButton(
        onPressed: onPressed,
        child: new GSYIConText(
          icon,
          text,
          GSYConstant.smallText,
          Color(GSYColors.primaryValue),
          15.0,
          padding: 5.0,
          mainAxisAlignment: MainAxisAlignment.center,
        ));
  }

  ///绘制底部状态
  _getBottomWidget() {
    ///根据网络返回数据，返回底部状态数据
    List<Widget> bottomWidget = (bottomStatusModel == null)
        ? []
        : <Widget>[
            /// star
            _renderBottomItem(
                bottomStatusModel.starText, bottomStatusModel.starIcon, () {
              CommonUtils.showLoadingDialog(context);
              return ReposDao.doRepositoryStarDao(
                      widget.userName, widget.reposName, bottomStatusModel.star)
                  .then((result) {
                _refresh();
                Navigator.pop(context);
              });
            }),

            /// watch
            _renderBottomItem(
                bottomStatusModel.watchText, bottomStatusModel.watchIcon, () {
              CommonUtils.showLoadingDialog(context);
              return ReposDao.doRepositoryWatchDao(widget.userName,
                      widget.reposName, bottomStatusModel.watch)
                  .then((result) {
                _refresh();
                Navigator.pop(context);
              });
            }),

            ///fork
            _renderBottomItem("fork", GSYICons.REPOS_ITEM_FORK, () {
              CommonUtils.showLoadingDialog(context);
              return ReposDao.createForkDao(widget.userName, widget.reposName)
                  .then((result) {
                _refresh();
                Navigator.pop(context);
              });
            }),
          ];
    return bottomWidget;
  }

  ///渲染 Tab 的 Item
  _renderTabItem() {
    var itemList = [
      CommonUtils.getLocale(context).repos_tab_info,
      CommonUtils.getLocale(context).repos_tab_readme,
      CommonUtils.getLocale(context).repos_tab_issue,
      CommonUtils.getLocale(context).repos_tab_file,
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

    List<Widget> list = new List();
    for (int i = 0; i < itemList.length; i++) {
      list.add(renderItem(itemList[i], i));
    }
    return list;
  }

  ///title 显示更多弹出item
  _getMoreOtherItem(Repository repository) {
    return [
      ///Release Page
      new GSYOptionModel(CommonUtils.getLocale(context).repos_option_release,
          CommonUtils.getLocale(context).repos_option_release, (model) {
        String releaseUrl = "";
        String tagUrl = "";
        if (infoListKey == null || infoListKey.currentState == null) {
          releaseUrl = GSYConstant.app_default_share_url;
          tagUrl = GSYConstant.app_default_share_url;
        } else {
          releaseUrl = repository == null
              ? GSYConstant.app_default_share_url
              : repository.htmlUrl + "/releases";
          tagUrl = repository == null
              ? GSYConstant.app_default_share_url
              : repository.htmlUrl + "/tags";
        }
        NavigatorUtils.goReleasePage(
            context, widget.userName, widget.reposName, releaseUrl, tagUrl);
      }),

      ///Branch Page
      new GSYOptionModel(CommonUtils.getLocale(context).repos_option_branch,
          CommonUtils.getLocale(context).repos_option_branch, (model) {
        if (branchList.length == 0) {
          return;
        }
        CommonUtils.showCommitOptionDialog(context, branchList, (value) {
          setState(() {
            reposDetailModel.setCurrentBranch(branchList[value]);
          });
          if (infoListKey.currentState != null &&
              infoListKey.currentState.mounted) {
            infoListKey.currentState.showRefreshLoading();
          }
          if (fileListKey.currentState != null &&
              fileListKey.currentState.mounted) {
            fileListKey.currentState.showRefreshLoading();
          }
          if (readmeKey.currentState != null &&
              readmeKey.currentState.mounted) {
            readmeKey.currentState.refreshReadme();
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
        context, CommonUtils.getLocale(context).issue_edit_issue, (titleValue) {
      title = titleValue;
    }, (contentValue) {
      content = contentValue;
    }, () {
      if (title == null || title.trim().length == 0) {
        Fluttertoast.showToast(
            msg: CommonUtils.getLocale(context)
                .issue_edit_issue_title_not_be_null);
        return;
      }
      if (content == null || content.trim().length == 0) {
        Fluttertoast.showToast(
            msg: CommonUtils.getLocale(context)
                .issue_edit_issue_content_not_be_null);
        return;
      }
      CommonUtils.showLoadingDialog(context);
      //提交修改
      IssueDao.createIssueDao(widget.userName, widget.reposName,
          {"title": title, "body": content}).then((result) {
        if (issueListKey.currentState != null &&
            issueListKey.currentState.mounted) {
          issueListKey.currentState.showRefreshLoading();
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
    _getBranchList();
    _refresh();

    ///悬浮按键动画控制器
    animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    ///跨 tab 共享状态
    return new ScopedModel<ReposDetailModel>(
      model: reposDetailModel,
      child: new ScopedModelDescendant<ReposDetailModel>(
        builder: (context, child, model) {
          Widget widgetContent = (model.repository != null && model.repository.htmlUrl != null)
              ? new GSYCommonOptionWidget(titleOptionControl,
                  otherList: _getMoreOtherItem(model.repository))
              : Container();

          print(widgetContent);
          ///绘制顶部 tab 控件
          return new GSYTabBarWidget(
            type: GSYTabBarWidget.TOP_TAB,
            tabItems: _renderTabItem(),
            resizeToAvoidBottomPadding: false,
            tabViews: [
              new ReposDetailInfoPage(
                  widget.userName, widget.reposName, titleOptionControl,
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
            indicatorColor: Color(GSYColors.white),
            title: new GSYTitleBar(
              widget.reposName,
              rightWidget: widgetContent,
            ),
            onPageChanged: (index) {
              reposDetailModel.setCurrentIndex(index);
            },

            ///悬浮按键，增加出现动画
            floatingActionButton: ScaleTransition(
              //scale: CurvedAnimation(parent: animationController, curve: Curves.bounceInOut),
              scale: CurvedAnimation(
                  parent: animationController, curve: CurveBezier()),
              child: FloatingActionButton(
                onPressed: () {
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
                color: Color(GSYColors.white),
                fabLocation: FloatingActionButtonLocation.endDocked,
                shape: CircularNotchedRectangle(),
                rowContents: (tarBarControl.footerButton == null)
                    ? [Container()]
                    : tarBarControl.footerButton.length == 0
                        ? [
                            SizedBox.fromSize(
                              size: Size(100, 50),
                            )
                          ]
                        : tarBarControl.footerButton),
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
  final bool star;
  final bool watch;

  BottomStatusModel(this.watchText, this.starText, this.watchIcon,
      this.starIcon, this.watch, this.star);
}

///仓库详情数据实体，包含有当前index，仓库数据，分支等等
class ReposDetailModel extends Model {
  static ReposDetailModel of(BuildContext context) =>
      ScopedModel.of<ReposDetailModel>(context);

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  String _currentBranch = "master";

  String get currentBranch => _currentBranch;

  Repository _repository = Repository.empty();

  Repository get repository => _repository;

  set repository(Repository data) {
    _repository = data;
    notifyListeners();
  }

  void setCurrentBranch(String branch) {
    _currentBranch = branch;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
