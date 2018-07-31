import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/model/FileModel.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailPage.dart';
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

  final BranchControl branchControl;

  RepositoryDetailFileListPage(this.userName, this.reposName, this.branchControl, {Key key}) : super(key: key);

  @override
  RepositoryDetailFileListPageState createState() => RepositoryDetailFileListPageState(userName, reposName, branchControl);
}

// ignore: mixin_inherits_from_not_object
class RepositoryDetailFileListPageState extends GSYListState<RepositoryDetailFileListPage> {
  final String userName;

  final String reposName;

  final BranchControl branchControl;

  String path = '';

  String searchText;
  String issueState;

  List<String> headerList = ["."];

  RepositoryDetailFileListPageState(this.userName, this.reposName, this.branchControl);

  ///渲染文件item
  _renderEventItem(index) {
    FileItemViewModel fileItemViewModel = FileItemViewModel.fromMap(pullLoadWidgetControl.dataList[index]);
    IconData iconData = (fileItemViewModel.type == "file") ? GSYICons.REPOS_ITEM_FILE : GSYICons.REPOS_ITEM_DIR;
    Widget trailing = (fileItemViewModel.type == "file") ? null : new Icon(GSYICons.REPOS_ITEM_NEXT, size: 14.0);
    return new GSYCardItem(
      margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
      child: new ListTile(
        title: new Text(fileItemViewModel.name, style: GSYConstant.subSmallText),
        leading: new Icon(
          iconData,
          size: 15.0,
        ),
        onTap: () {
          _resolveItemClick(fileItemViewModel);
        },
        trailing: trailing,
      ),
    );
  }

  ///渲染头部列表
  _renderHeader() {
    return new Container(
      margin: new EdgeInsets.only(left: 3.0, right: 3.0),
      child: new ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return new RawMaterialButton(
            constraints: new BoxConstraints(minWidth: 0.0, minHeight: 0.0),
            padding: new EdgeInsets.all(4.0),
            onPressed: () {
              _resolveHeaderClick(index);
            },
            child: new Text(headerList[index] + " > ", style: GSYConstant.smallText),
          );
        },
        itemCount: headerList.length,
      ),
    );
  }

  ///头部列表点击
  _resolveHeaderClick(index) {
    if (headerList[index] != ".") {
      List<String> newHeaderList = headerList.sublist(0, index + 1);
      String path = newHeaderList.sublist(1, newHeaderList.length).join("/");
      this.setState(() {
        this.path = path;
        headerList = newHeaderList;
      });
      this.showRefreshLoading();
    } else {
      setState(() {
        path = "";
        headerList = ["."];
      });
      this.showRefreshLoading();
    }
  }

  ///item文件列表点击
  _resolveItemClick(FileItemViewModel fileItemViewModel) {
    if (fileItemViewModel.type == "dir") {
      this.setState(() {
        headerList.add(fileItemViewModel.name);
      });
      String path = headerList.sublist(1, headerList.length).join("/");
      this.setState(() {
        this.path = path;
      });
      this.showRefreshLoading();
    } else {
      String path = headerList.sublist(1, headerList.length).join("/") + "/" + fileItemViewModel.name;
      if (CommonUtils.isImageEnd(fileItemViewModel.name)) {
        //todo 图片
      } else {
        NavigatorUtils.gotoCodeDetailPlatform(
          context,
          title: fileItemViewModel.name,
          reposName: reposName,
          userName: userName,
          path: path,
          branch: branchControl.currentBranch,
        );
      }
    }
  }

  _getDataLogic(String searchString) async {
    return await ReposDao.getReposFileDirDao(userName, reposName, path: path, branch: branchControl.currentBranch);
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

  FileItemViewModel.fromMap(FileModel map) {
    name = map.name;
    type = map.type;
  }
}
