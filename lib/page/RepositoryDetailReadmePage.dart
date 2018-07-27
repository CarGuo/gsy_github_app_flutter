import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailPage.dart';
import 'package:gsy_github_app_flutter/widget/GSYMarkdownWidget.dart';

/**
 * Readme
 * Created by guoshuyu
 * Date: 2018-07-18
 */

class RepositoryDetailReadmePage extends StatefulWidget {
  final String userName;

  final String reposName;

  final BranchControl branchControl;

  RepositoryDetailReadmePage(this.userName, this.reposName, this.branchControl, {Key key}) : super(key: key);

  @override
  RepositoryDetailReadmePageState createState() => RepositoryDetailReadmePageState(userName, reposName, branchControl);
}

// ignore: mixin_inherits_from_not_object
class RepositoryDetailReadmePageState extends State<RepositoryDetailReadmePage> with AutomaticKeepAliveClientMixin {
  final String userName;

  final String reposName;

  final BranchControl branchControl;

  bool isShow = false;

  String markdownData;

  RepositoryDetailReadmePageState(this.userName, this.reposName, this.branchControl);

  refreshReadme() {
    ReposDao.getRepositoryDetailReadmeDao(userName, reposName, branchControl.currentBranch).then((res) {
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
    if (markdownData == null) {
      return Center(
        child: new Container(
          width: 140.0,
          height: 140.0,
          padding: new EdgeInsets.all(4.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new SpinKitDoubleBounce(color: Color(GSYColors.primaryValue)),
              new Container(width: 10.0),
              new Container(child: new Text(GSYStrings.loading_text, style: GSYConstant.middleText)),
            ],
          ),
        ),
      );
    }
    return GSYMarkdownWidget(markdownData: markdownData);
  }
}
