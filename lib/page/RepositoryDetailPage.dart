import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailIssueListPage.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailReadmePage.dart';
import 'package:gsy_github_app_flutter/page/RepositoryFileListPage.dart';
import 'package:gsy_github_app_flutter/page/RepostoryDetailInfoPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYCommonOptionWidget.dart';
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

class _RepositoryDetailPageState extends State<RepositoryDetailPage> {
  ReposHeaderViewModel reposHeaderViewModel = new ReposHeaderViewModel();

  BottomStatusModel bottomStatusModel;

  final String userName;

  final String reposName;

  final ReposDetailInfoPageControl reposDetailInfoPageControl = new ReposDetailInfoPageControl();

  final TarWidgetControl tarBarControl = new TarWidgetControl();

  final ReposDetailParentControl reposDetailParentControl = new ReposDetailParentControl("master");

  final PageController topPageControl = new PageController();

  final OptionControl titleOptionControl = new OptionControl();

  GlobalKey<RepositoryDetailFileListPageState> fileListKey = new GlobalKey<RepositoryDetailFileListPageState>();

  GlobalKey<ReposDetailInfoPageState> infoListKey = new GlobalKey<ReposDetailInfoPageState>();

  GlobalKey<RepositoryDetailReadmePageState> readmeKey = new GlobalKey<RepositoryDetailReadmePageState>();

  List<String> branchList = new List();

  _RepositoryDetailPageState(this.userName, this.reposName);

  _getReposDetail() async {
    var result = await ReposDao.getRepositoryDetailDao(userName, reposName, reposDetailParentControl.currentBranch);
    if (result != null && result.result) {
      setState(() {
        reposDetailInfoPageControl.repository = result.data;
        print("==========================");
        print(result.data.htmlUrl);
        titleOptionControl.url = reposDetailInfoPageControl.repository.htmlUrl;
      });
    }
  }

  _getReposStatus() async {
    var result = await ReposDao.getRepositoryStatusDao(userName, reposName);
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

  _getBottomWidget() {
    List<Widget> bottomWidget = (bottomStatusModel == null)
        ? []
        : <Widget>[
            _renderBottomItem(bottomStatusModel.starText, bottomStatusModel.starIcon, () {
              CommonUtils.showLoadingDialog(context);
              return ReposDao.doRepositoryStarDao(userName, reposName, bottomStatusModel.star).then((result) {
                _refresh();
                Navigator.pop(context);
              });
            }),
            _renderBottomItem(bottomStatusModel.watchText, bottomStatusModel.watchIcon, () {
              CommonUtils.showLoadingDialog(context);
              return ReposDao.doRepositoryWatchDao(userName, reposName, bottomStatusModel.watch).then((result) {
                _refresh();
                Navigator.pop(context);
              });
            }),
            _renderBottomItem("fork", GSYICons.REPOS_ITEM_FORK, () {
              CommonUtils.showLoadingDialog(context);
              return ReposDao.createForkDao(userName, reposName).then((result) {
                _refresh();
                Navigator.pop(context);
              });
            }),
            _renderBranchPopItem(reposDetailParentControl.currentBranch, branchList, (value) {
              setState(() {
                reposDetailParentControl.currentBranch = value;
                tarBarControl.footerButton = _getBottomWidget();
              });
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

  ///无奈之举，只能pageView配合tabbar，通过control同步
  ///TabView 配合tabbar 在四个页面上问题太多
  _renderTabItem() {
    var itemList = [
      GSYStrings.repos_tab_info,
      GSYStrings.repos_tab_readme,
      GSYStrings.repos_tab_issue,
      GSYStrings.repos_tab_file,
    ];
    renderItem(String item, int i) {
      return new FlatButton(
          padding: EdgeInsets.all(0.0),
          onPressed: () {
            reposDetailParentControl.currentIndex = i;
            topPageControl.jumpTo(MediaQuery.of(context).size.width * i);
          },
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

  _getMoreOtherItem() {
    return [
      ///Release Page
      new GSYOptionModel(GSYStrings.repos_option_release, GSYStrings.repos_option_release, (model) {
        String releaseUrl =
            reposDetailInfoPageControl.repository == null ? GSYStrings.app_default_share_url : reposDetailInfoPageControl.repository.htmlUrl + "/releases";
        String tagUrl =
            reposDetailInfoPageControl.repository == null ? GSYStrings.app_default_share_url : reposDetailInfoPageControl.repository.htmlUrl + "/tags";
        NavigatorUtils.goReleasePage(context, userName, reposName, releaseUrl, tagUrl);
      }),
    ];
  }

  @override
  void initState() {
    super.initState();
    _getBranchList();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    Widget widget = new GSYCommonOptionWidget(titleOptionControl, otherList: _getMoreOtherItem());
    return new GSYTabBarWidget(
      type: GSYTabBarWidget.TOP_TAB,
      tarWidgetControl: tarBarControl,
      tabItems: _renderTabItem(),
      tabViews: [
        new ReposDetailInfoPage(reposDetailInfoPageControl, userName, reposName, reposDetailParentControl, key: infoListKey),
        new RepositoryDetailReadmePage(userName, reposName, reposDetailParentControl, key: readmeKey),
        new RepositoryDetailIssuePage(userName, reposName),
        new RepositoryDetailFileListPage(userName, reposName, reposDetailParentControl, key: fileListKey),
      ],
      topPageControl: topPageControl,
      backgroundColor: GSYColors.primarySwatch,
      indicatorColor: Colors.white,
      title: new GSYTitleBar(
        reposName,
        rightWidget: widget,
      ),
      onPageChanged: (index) {
        reposDetailParentControl.currentIndex = index;
      },
    );
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

class ReposDetailParentControl {
  int currentIndex = 0;

  String currentBranch;

  ReposDetailParentControl(this.currentBranch);
}
