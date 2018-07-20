import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';

/**
 * 仓库文件列表
 * Created by guoshuyu
 * on 2018/7/20.
 */

class RepositoryDetailFileListPage extends StatefulWidget {
  final String userName;

  final String reposName;

  RepositoryDetailFileListPage(this.userName, this.reposName);

  @override
  _RepositoryDetailFileListPageState createState() => _RepositoryDetailFileListPageState(userName, reposName);
}

// ignore: mixin_inherits_from_not_object
class _RepositoryDetailFileListPageState extends GSYListState<RepositoryDetailFileListPage> {
  final String userName;

  final String reposName;

  String curBranch;
  String path = '';

  String searchText;
  String issueState;

  List<String> headerList = ["ttttt"];

  _RepositoryDetailFileListPageState(this.userName, this.reposName);

  _renderEventItem(index) {
    FileItemViewModel fileItemViewModel = pullLoadWidgetControl.dataList[index];
    IconData iconData = (fileItemViewModel.type == "file") ? GSYICons.REPOS_ITEM_FILE : GSYICons.REPOS_ITEM_DIR;
    return new GSYCardItem(
      child: new ListTile(
        title: new Text(fileItemViewModel.name, style: GSYConstant.subSmallText),
        leading: new Icon(iconData),
      ),
    );
  }

  _getDataLogic(String searchString) async {
    return await ReposDao.getReposFileDirDao(userName, reposName, path: path, branch: curBranch);
  }

  _renderHeader() {
    return new Container(
      margin: new EdgeInsets.only(left: 3.0, right: 3.0),
      child: new ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return new RawMaterialButton(
            constraints: new BoxConstraints(minWidth: 0.0, minHeight: 0.0),
            padding: new EdgeInsets.all(4.0),
            onPressed: () {},
            child: new Text(headerList[index] + " > ", style: GSYConstant.smallText),
          );
        },
        itemCount: headerList.length,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => true;

  @override
  requestLoadMore() async {
    return await _getDataLogic(this.searchText);
  }

  @override
  requestRefresh() async {
    return await _getDataLogic(this.searchText);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new Scaffold(
      backgroundColor: Color(GSYColors.mainBackgroundColor),
      appBar: new AppBar(
        flexibleSpace: _renderHeader(),
        backgroundColor: Color(GSYColors.mainBackgroundColor),
        leading: new Container(),
        elevation: 0.0,
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
            (BuildContext context, int index) => _renderEventItem(index),
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}

class FileItemViewModel {
  String type;
  String name;

  FileItemViewModel();

  FileItemViewModel.fromMap(map) {
    name = map["name"];
    type = map["type"];
  }
}
