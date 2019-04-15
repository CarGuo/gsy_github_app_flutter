import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/page/repository_detail_page.dart';
import 'package:gsy_github_app_flutter/widget/gsy_markdown_widget.dart';
import 'package:scoped_model/scoped_model.dart';

/**
 * Readme
 * Created by guoshuyu
 * Date: 2018-07-18
 */

class RepositoryDetailReadmePage extends StatefulWidget {
  final String userName;

  final String reposName;

  RepositoryDetailReadmePage(this.userName, this.reposName, {Key key}) : super(key: key);

  @override
  RepositoryDetailReadmePageState createState() => RepositoryDetailReadmePageState(userName, reposName);
}


class RepositoryDetailReadmePageState extends State<RepositoryDetailReadmePage> with AutomaticKeepAliveClientMixin {
  final String userName;

  final String reposName;

  bool isShow = false;

  String markdownData;

  RepositoryDetailReadmePageState(this.userName, this.reposName);

  refreshReadme() {
    ReposDao.getRepositoryDetailReadmeDao(userName, reposName, ReposDetailModel.of(context).currentBranch).then((res) {
      if (res != null && res.result) {
        if (isShow) {
          setState(() {
            markdownData = res.data;
          });
          return res.next;
        }
      }
      return new Future.value(null);
    }).then((res) {
      if (res != null && res.result) {
        if (isShow) {
          setState(() {
            markdownData = res.data;
          });
        }
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    isShow = true;
    super.initState();
    refreshReadme();
  }

  @override
  void dispose() {
    isShow = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var widget = (markdownData == null)
        ? Center(
            child: new Container(
              width: 200.0,
              height: 200.0,
              padding: new EdgeInsets.all(4.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new SpinKitDoubleBounce(color: Theme.of(context).primaryColor),
                  new Container(width: 10.0),
                  new Container(child: new Text(CommonUtils.getLocale(context).loading_text, style: GSYConstant.middleText)),
                ],
              ),
            ),
          )
        : GSYMarkdownWidget(markdownData: markdownData);

    return new ScopedModelDescendant<ReposDetailModel>(
      builder: (context, child, model) => widget,
    );
  }
}
