import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/config/Config.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
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

// ignore: mixin_inherits_from_not_object
class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin<SearchPage>, GSYListState<SearchPage> {
  int selectIndex = 0;

  String searchText;
  String type = searchFilterType[0].value;
  String sort = sortType[0].value;
  String language = searchLanguageType[0].value;

  _renderEventItem(index) {
    var data = pullLoadWidgetControl.dataList[index];
    if (selectIndex == 0) {
      ReposViewModel reposViewModel = ReposViewModel.fromMap(data);
      return new ReposItem(reposViewModel, onPressed: () {
        NavigatorUtils.goReposDetail(context, reposViewModel.ownerName, reposViewModel.repositoryName);
      });
    } else if (selectIndex == 1) {
      return new UserItem(UserItemViewModel.fromMap(data), onPressed: () {
        NavigatorUtils.goPerson(context, UserItemViewModel.fromMap(data).userName);
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

  _clearSelect(List<FilterModel> list) {
    for (FilterModel model in list) {
      model.select = false;
    }
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
  void dispose() {
    super.dispose();
    _clearSelect(sortType);
    sortType[0].select = true;
    _clearSelect(searchLanguageType);
    searchLanguageType[0].select = true;
    _clearSelect(searchFilterType);
    searchFilterType[0].select = true;
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
          title: new Text(CommonUtils.getLocale(context).search_title),
          bottom: new SearchBottom((value) {
            searchText = value;
          }, (value) {
            searchText = value;
            if (searchText == null || searchText.trim().length == 0) {
              return;
            }
            _resolveSelectIndex();
          }, () {
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

  final VoidCallback onSubmitPressed;

  SearchBottom(this.onChanged, this.onSubmitted, this.onSubmitPressed, this.selectItemChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GSYSearchInputWidget(onChanged, onSubmitted, onSubmitPressed),
        new GSYSelectItemWidget(
          [
            CommonUtils.getLocale(context).search_tab_repos,
            CommonUtils.getLocale(context).search_tab_user,
          ],
          selectItemChanged,
          elevation: 0.0,
          margin: const EdgeInsets.all(5.0),
        )
      ],
    );
  }

  @override
  Size get preferredSize {
    return new Size.fromHeight(100.0);
  }
}
