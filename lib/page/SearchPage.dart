import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/NavigatorUtils.dart';
import 'package:gsy_github_app_flutter/widget/GSYListState.dart';
import 'package:gsy_github_app_flutter/widget/GSYPullLoadWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYSearchDrawer.dart';
import 'package:gsy_github_app_flutter/widget/GSYSearchInputWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYSelectItemWidget.dart';
import 'package:gsy_github_app_flutter/widget/ReposItem.dart';
import 'package:gsy_github_app_flutter/widget/UserItem.dart';

/**
 * Created by guoshuyu
 * on 2018/7/24.
 */
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends GSYListState<SearchPage> {
  int selectIndex = 0;

  String searchText;
  String type = searchFilterType[0].value;
  String sort = sortType[0].value;
  String language = searchLanguageType[0].value;

  _renderEventItem(index) {
    var data = pullLoadWidgetControl.dataList[index];
    if (selectIndex == 0) {
      return new ReposItem(data, onPressed: () {
        NavigatorUtils.goReposDetail(context, data.ownerName, data.repositoryName);
      });
    } else if (selectIndex == 1) {
      return new UserItem(data, onPressed: () {
        NavigatorUtils.goPerson(context, data.userName);
      });
    }
  }

  _resolveSelectIndex() {
    clearData();
    showRefreshLoading();
  }

  _getDataLogic() async {
    return await ReposDao.searchRepositoryDao(searchText, language, type, sort, selectIndex == 0 ? null : 'user', page, Config.PAGE_SIZE);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  bool get needHeader => false;

  @override
  bool get isRefreshFirst => false;

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  requestRefresh() async {
    return await _getDataLogic();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return new Scaffold(
      endDrawer: new GSYSearchDrawer(
        (String type) {
          this.type = type;
          Navigator.pop(context);
          _resolveSelectIndex();
        },
        (String sort) {
          this.sort = sort;
          Navigator.pop(context);
          _resolveSelectIndex();
        },
        (String language) {
          this.language = language;
          Navigator.pop(context);
          _resolveSelectIndex();
        },
      ),
      backgroundColor: Color(GSYColors.mainBackgroundColor),
      appBar: new AppBar(
          title: new Text(GSYStrings.search_title),
          bottom: new SearchBottom((value) {}, (value) {
            searchText = value;
            if (searchText == null || searchText.trim().length == 0) {
              return;
            }
            _resolveSelectIndex();
          }, (selectIndex) {
            this.selectIndex = selectIndex;
            _resolveSelectIndex();
          })),
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

class SearchBottom extends StatelessWidget implements PreferredSizeWidget {
  final SelectItemChanged onChanged;

  final SelectItemChanged onSubmitted;

  final SelectItemChanged selectItemChanged;

  SearchBottom(this.onChanged, this.onSubmitted, this.selectItemChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GSYSearchInputWidget(onChanged, onSubmitted),
        new GSYSelectItemWidget(
          [
            GSYStrings.search_tab_repos,
            GSYStrings.search_tab_user,
          ],
          selectItemChanged,
          margin: const EdgeInsets.only(top: 0.0),
        )
      ],
    );
  }

  @override
  Size get preferredSize {
    return new Size.fromHeight(100.0);
  }
}
