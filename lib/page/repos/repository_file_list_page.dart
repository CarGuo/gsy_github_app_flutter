import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/common/scoped_model/scoped_model.dart';
import 'package:gsy_github_app_flutter/model/FileModel.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/page/repos/scope/repos_detail_model.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';

/**
 * 仓库文件列表
 * Created by guoshuyu
 * on 2018/7/20.
 */

class RepositoryDetailFileListPage extends StatefulWidget {
  final String? userName;

  final String? reposName;

  RepositoryDetailFileListPage(this.userName, this.reposName, {Key? super.key});

  @override
  RepositoryDetailFileListPageState createState() =>
      RepositoryDetailFileListPageState();
}

class RepositoryDetailFileListPageState
    extends State<RepositoryDetailFileListPage>
    with
        AutomaticKeepAliveClientMixin<RepositoryDetailFileListPage>,
        GSYListState<RepositoryDetailFileListPage> {
  String path = '';

  String? searchText;
  String? issueState;

  List<String?> headerList = ["."];

  ///渲染文件item
  _renderEventItem(index) {
    FileItemViewModel fileItemViewModel =
        FileItemViewModel.fromMap(pullLoadWidgetControl.dataList[index]);
    IconData iconData = (fileItemViewModel.type == "file")
        ? GSYICons.REPOS_ITEM_FILE
        : GSYICons.REPOS_ITEM_DIR;
    Widget? trailing = (fileItemViewModel.type == "file")
        ? null
        : new Icon(GSYICons.REPOS_ITEM_NEXT, size: 12.0);
    return new GSYCardItem(
      margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
      child: new ListTile(
        title:
            new Text(fileItemViewModel.name!, style: GSYConstant.smallSubText),
        leading: new Icon(
          iconData,
          size: 16.0,
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
            child: new Text(headerList[index]! + " > ",
                style: GSYConstant.smallText),
          );
        },
        itemCount: headerList.length,
      ),
    );
  }

  ///头部列表点击
  _resolveHeaderClick(index) {
    if (isLoading) {
      Fluttertoast.showToast(msg: GSYLocalizations.i18n(context)!.loading_text);
      return;
    }
    if (headerList[index] != ".") {
      List<String?> newHeaderList = headerList.sublist(0, index + 1);
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
      if (isLoading) {
        Fluttertoast.showToast(
            msg: GSYLocalizations.i18n(context)!.loading_text);
        return;
      }
      this.setState(() {
        headerList.add(fileItemViewModel.name);
      });
      String path = headerList.sublist(1, headerList.length).join("/");
      this.setState(() {
        this.path = path;
      });
      this.showRefreshLoading();
    } else {
      String path = headerList.sublist(1, headerList.length).join("/") +
          "/" +
          fileItemViewModel.name!;
      if (CommonUtils.isImageEnd(fileItemViewModel.name)) {
        NavigatorUtils.gotoPhotoViewPage(
            context, fileItemViewModel.htmlUrl! + "?raw=true");
      } else {
        NavigatorUtils.gotoCodeDetailPlatform(
          context,
          title: fileItemViewModel.name,
          reposName: widget.reposName,
          userName: widget.userName,
          path: path,
          branch: ReposDetailModel.of(context).currentBranch,
        );
      }
    }
  }

  _getDataLogic(String? searchString) async {
    return await ReposDao.getReposFileDirDao(widget.userName, widget.reposName,
        path: path, branch: ReposDetailModel.of(context).currentBranch);
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
      backgroundColor: GSYColors.mainBackgroundColor,
      appBar: new AppBar(
        flexibleSpace: _renderHeader(),
        backgroundColor: GSYColors.mainBackgroundColor,
        leading: new Container(),
        elevation: 0.0,
      ),
      body: PopScope(
        canPop: ReposDetailModel.of(context).currentIndex != 3 &&
            headerList.length == 1,
        onPopInvoked: (didPop) {
          if (didPop == false) {
            _resolveHeaderClick(headerList.length - 2);
          }
        },
        child: ScopedModelDescendant<ReposDetailModel>(
          builder: (context, child, model) {
            return GSYPullLoadWidget(
              pullLoadWidgetControl,
              (BuildContext context, int index) => _renderEventItem(index),
              handleRefresh,
              onLoadMore,
              refreshKey: refreshIndicatorKey,
            );
          },
        ),
      ),
    );
  }
}

class FileItemViewModel {
  String? type;
  String? name;
  String? htmlUrl;

  FileItemViewModel();

  FileItemViewModel.fromMap(FileModel map) {
    name = map.name;
    type = map.type;
    htmlUrl = map.htmlUrl;
  }
}
