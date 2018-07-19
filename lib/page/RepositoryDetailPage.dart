import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailReadmePage.dart';
import 'package:gsy_github_app_flutter/page/RepostoryDetailInfoPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYIConText.dart';
import 'package:gsy_github_app_flutter/widget/GSYTabBarWidget.dart';
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

  _RepositoryDetailPageState(this.userName, this.reposName);

  _getReposDetail() async {
    var result = await ReposDao.getRepositoryDetailDao(userName, reposName);
    if (result != null && result.result) {
      setState(() {
        reposDetailInfoPageControl.reposHeaderViewModel = result.data;
      });
    }
  }

  _getReposStatus() async {
    var result = await ReposDao.getRepositoryStatusDao(userName, reposName);
    print(result.data["star"]);
    print(result.data["watch"]);
    String watchText = result.data["watch"] ? "UnWatch" : "Watch";
    String starText = result.data["star"] ? "UnStar" : "Star";
    IconData watchIcon = result.data["watch"] ? GSYICons.REPOS_ITEM_WATCHED : GSYICons.REPOS_ITEM_WATCH;
    IconData starIcon = result.data["star"] ? GSYICons.REPOS_ITEM_STARED : GSYICons.REPOS_ITEM_STAR;
    BottomStatusModel model = new BottomStatusModel(watchText, starText, watchIcon, starIcon, result.data["watch"], result.data["star"]);
    bottomStatusModel = model;
    setState(() {
      tarBarControl.footerButton = _getBottomWidget();
    });
  }

  _getBottomWidget() {
    List<Widget> bottomWidget = (bottomStatusModel == null)
        ? []
        : <Widget>[
            new FlatButton(
                onPressed: () => {},
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
                onPressed: () {},
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
                onPressed: () {},
                child: new GSYIConText(
                  GSYICons.REPOS_ITEM_FORK,
                  "fork",
                  GSYConstant.smallText,
                  Color(GSYColors.primaryValue),
                  15.0,
                  padding: 5.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                )),
            new FlatButton(
                onPressed: () {},
                color: Color(GSYColors.primaryValue),
                child: new GSYIConText(
                  Icons.arrow_drop_up,
                  "master",
                  GSYConstant.smallTextWhite,
                  Color(GSYColors.white),
                  30.0,
                  padding: 3.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                ))
          ];
    return bottomWidget;
  }

  @override
  void initState() {
    super.initState();
    this._getReposDetail();
    this._getReposStatus();
  }

  @override
  Widget build(BuildContext context) {
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.TOP_TAB,
        tarWidgetControl: tarBarControl,
        tabItems: [
          new Tab(text: GSYStrings.repos_tab_readme),
          new Tab(text: GSYStrings.repos_tab_info),
          new Tab(text: GSYStrings.repos_tab_file),
          new Tab(text: GSYStrings.repos_tab_issue),
        ],
        tabViews: [
          new RepositoryDetailReadmePage(),
          new ReposDetailInfoPage(reposDetailInfoPageControl, userName, reposName),
          new Icon(GSYICons.MAIN_DT),
          new Icon(GSYICons.MAIN_DT),
        ],
        backgroundColor: GSYColors.primarySwatch,
        indicatorColor: Colors.white,
        title: reposName);
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
