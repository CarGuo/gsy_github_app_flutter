import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailReadmePage.dart';
import 'package:gsy_github_app_flutter/page/RepostoryDetailInfoPage.dart';
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
class _RepositoryDetailPageState extends State<RepositoryDetailPage> with AutomaticKeepAliveClientMixin {
  ReposHeaderViewModel reposHeaderViewModel = new ReposHeaderViewModel();

  final String userName;

  final String reposName;

  final ReposDetailInfoPageControl reposDetailInfoPageControl = new ReposDetailInfoPageControl();

  _RepositoryDetailPageState(this.userName, this.reposName);

  _getReposDetail() async {
    var result = await ReposDao.getRepositoryDetailDao(userName, reposName);
    if (result != null && result.result) {
      setState(() {
        reposDetailInfoPageControl.reposHeaderViewModel = result.data;
      });
    }
  }

  @override
  void didChangeDependencies() {
    this._getReposDetail();
    super.didChangeDependencies();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.TOP_TAB,
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
