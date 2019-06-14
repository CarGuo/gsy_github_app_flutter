import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/dao/user_dao.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/state/base_person_state.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/repos_item.dart';
import 'package:gsy_github_app_flutter/widget/user_item.dart';
import 'package:provider/provider.dart';

/**
 * 荣耀list
 * Created by guoshuyu
 * on 2018/7/22.
 */
class HonorListPage extends StatefulWidget {

  final List list;

  HonorListPage(this.list);

  @override
  _HonorListPageState createState() => _HonorListPageState();
}

class _HonorListPageState extends State<HonorListPage> {
  _renderItem(item) {
    ReposViewModel reposViewModel = ReposViewModel.fromMap(item);
    return new ReposItem(reposViewModel, onPressed: () {
      NavigatorUtils.goReposDetail(
          context, reposViewModel.ownerName, reposViewModel.repositoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text(
            CommonUtils
                .getLocale(context)
                .user_tab_honor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return _renderItem(widget.list[index]);
        },
        itemCount: widget.list.length,
      ),);
  }
}
