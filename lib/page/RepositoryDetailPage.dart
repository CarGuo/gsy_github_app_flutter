import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailIssueListPage.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailReadmePage.dart';
import 'package:gsy_github_app_flutter/page/RepositoryFileListPage.dart';
import 'package:gsy_github_app_flutter/page/RepostoryDetailInfoPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';
import 'package:gsy_github_app_flutter/widget/ReposHeaderItem.dart';

/**
 * 仓库详情
 * Created by guoshuyu
 * Date: 2018-07-18
 */

class RepositoryDetailPage extends StatefulWidget {
  final String userName;

  final String reposName;

  RepositoryDetailPage(this.userName, this.reposName);

  @override
  _RepositoryDetailPageState createState() => _RepositoryDetailPageState(userName, reposName);
}

// ignore: mixin_inherits_from_not_object
class _RepositoryDetailPageState extends State<RepositoryDetailPage> {
  ReposHeaderViewModel reposHeaderViewModel = new ReposHeaderViewModel();

  BottomStatusModel bottomStatusModel;

  final String userName;

  final String reposName;

  final ReposDetailInfoPageControl reposDetailInfoPageControl = new ReposDetailInfoPageControl();

  final TarWidgetControl tarBarControl = new TarWidgetControl();

  final BranchControl branchControl = new BranchControl("master");

  GlobalKey<RepositoryDetailFileListPageState> fileListKey = new GlobalKey<RepositoryDetailFileListPageState>();

  GlobalKey<ReposDetailInfoPageState> infoListKey = new GlobalKey<ReposDetailInfoPageState>();

  GlobalKey<RepositoryDetailReadmePageState> readmeKey = new GlobalKey<RepositoryDetailReadmePageState>();

  List<String> branchList = new List();

  _RepositoryDetailPageState(this.userName, this.reposName);

  _getReposDetail() async {
    var result = await ReposDao.getRepositoryDetailDao(userName, reposName, branchControl.currentBranch);
    if (result != null && result.result) {
      setState(() {
        reposDetailInfoPageControl.reposHeaderViewModel = result.data;
      });
    }
  }

  _getReposStatus() async {
    var result = await ReposDao.getRepositoryStatusDao(userName, reposName);
    if (Config.DEBUG) {
      print(result.data["star"]);
      print(result.data["watch"]);
    }
    String watchText = result.data["watch"] ? "UnWatch" : "Watch";
    String starText = result.data["star"] ? "UnStar" : "Star";
    IconData watchIcon = result.data["watch"] ? GSYICons.REPOS_ITEM_WATCHED : GSYICons.REPOS_ITEM_WATCH;
    IconData starIcon = result.data["star"] ? GSYICons.REPOS_ITEM_STARED : GSYICons.REPOS_ITEM_STAR;
    BottomStatusModel model = new BottomStatusModel(watchText, starText, watchIcon, starIcon, result.data["watch"], result.data["star"]);
    setState(() {
      bottomStatusModel = model;
      tarBarControl.footerButton = _getBottomWidget();
    });
  }

  _getBranchList() async {
    var result = await ReposDao.getBranchesDao(userName, reposName);
    if (result != null && result.result) {
      setState(() {
        branchList = result.data;
      });
    }
  }

  _refresh() {
    this._getReposDetail();
    this._getReposStatus();
  }

  _renderBranchPopItem(String data, List<String> list, onSelected) {
    if (list == null && list.length == 0) {
      return new Container(height: 0.0, width: 0.0);
    }
    return new Container(
      height: 30.0,
      child: new PopupMenuButton<String>(
        child: new FlatButton(
          onPressed: null,
          color: Color(GSYColors.primaryValue),
          disabledColor: Color(GSYColors.primaryValue),
          child: new GSYIConText(
            Icons.arrow_drop_up,
            data,
            GSYConstant.smallTextWhite,
            Color(GSYColors.white),
            30.0,
            padding: 3.0,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return _renderHeaderPopItemChild(list);
        },
      ),
    );
  }

  _renderHeaderPopItemChild(List<String> data) {
    List<PopupMenuEntry<String>> list = new List();
    for (String item in data) {
      list.add(PopupMenuItem<String>(
        value: item,
        child: new Text(item),
      ));
    }
    return list;
  }

  _getBottomWidget() {
    List<Widget> bottomWidget = (bottomStatusModel == null)
        ? []
        : <Widget>[
            new FlatButton(
                onPressed: () {
                  CommonUtils.showLoadingDialog(context);
                  return ReposDao.doRepositoryStarDao(userName, reposName, bottomStatusModel.star).then((result) {
                    _refresh();
                    Navigator.pop(context);
                  });
                },
                child: new GSYIConText(
                  bottomStatusModel.starIcon,
                  bottomStatusModel.starText,
                  GSYConstant.smallText,
                  Color(GSYColors.primaryValue),
                  15.0,
                  padding: 5.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                )),
            new FlatButton(
                onPressed: () {
                  CommonUtils.showLoadingDialog(context);
                  return ReposDao.doRepositoryWatchDao(userName, reposName, bottomStatusModel.watch).then((result) {
                    _refresh();
                    Navigator.pop(context);
                  });
                },
                child: new GSYIConText(
                  bottomStatusModel.watchIcon,
                  bottomStatusModel.watchText,
                  GSYConstant.smallText,
                  Color(GSYColors.primaryValue),
                  15.0,
                  padding: 5.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                )),
            new FlatButton(
                onPressed: () {
                  CommonUtils.showLoadingDialog(context);
                  return ReposDao.createForkDao(userName, reposName).then((result) {
                    _refresh();
                    Navigator.pop(context);
                  });
                },
                child: new GSYIConText(
                  GSYICons.REPOS_ITEM_FORK,
                  "fork",
                  GSYConstant.smallText,
                  Color(GSYColors.primaryValue),
                  15.0,
                  padding: 5.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                )),
            _renderBranchPopItem(branchControl.currentBranch, branchList, (value) {
              setState(() {
                branchControl.currentBranch = value;
              });
              _getReposDetail();
              if (infoListKey.currentState != null && infoListKey.currentState.mounted) {
                infoListKey.currentState.showRefreshLoading();
              }
              if (fileListKey.currentState != null && fileListKey.currentState.mounted) {
                fileListKey.currentState.showRefreshLoading();
              }
              if (readmeKey.currentState != null && readmeKey.currentState.mounted) {
                readmeKey.currentState.refreshReadme();
              }
            }),
          ];
    return bottomWidget;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    _getBranchList();
  }

  @override
  Widget build(BuildContext context) {
    fileListKey = new GlobalKey<RepositoryDetailFileListPageState>();
    infoListKey = new GlobalKey<ReposDetailInfoPageState>();
    readmeKey = new GlobalKey<RepositoryDetailReadmePageState>();
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.TOP_TAB,
        tarWidgetControl: tarBarControl,
        tabItems: [
          new Tab(text: GSYStrings.repos_tab_info),
          new Tab(text: GSYStrings.repos_tab_readme),
          new Tab(text: GSYStrings.repos_tab_issue),
          new Tab(text: GSYStrings.repos_tab_file),
        ],
        tabViews: [
          new ReposDetailInfoPage(reposDetailInfoPageControl, userName, reposName, branchControl, key: infoListKey),
          new RepositoryDetailReadmePage(userName, reposName, branchControl, key: readmeKey),
          new RepositoryDetailIssuePage(userName, reposName),
          new RepositoryDetailFileListPage(userName, reposName, branchControl, key: fileListKey),
        ],
        backgroundColor: GSYColors.primarySwatch,
        indicatorColor: Colors.white,
        title: new GSYTitleBar(reposName));
  }
}

class BottomStatusModel {
  final String watchText;
  final String starText;
  final IconData watchIcon;
  final IconData starIcon;
  final bool star;
  final bool watch;

  BottomStatusModel(this.watchText, this.starText, this.watchIcon, this.starIcon, this.watch, this.star);
}

class BranchControl {
  String currentBranch;

  BranchControl(this.currentBranch);
}
