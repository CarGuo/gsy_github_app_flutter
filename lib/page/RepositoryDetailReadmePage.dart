import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gsy_github_app_flutter/page/RepositoryDetailPage.dart';

/**
 * Readme
 * Created by guoshuyu
 * Date: 2018-07-18
 */

class RepositoryDetailReadmePage extends StatefulWidget {
  final String userName;

  final String reposName;

  final BranchControl branchControl;

  RepositoryDetailReadmePage(this.userName, this.reposName, this.branchControl, { Key key }) : super(key: key);

  @override
  RepositoryDetailReadmePageState createState() => RepositoryDetailReadmePageState(userName, reposName, branchControl);
}

class RepositoryDetailReadmePageState extends State<RepositoryDetailReadmePage> {
  final String userName;

  final String reposName;

  final BranchControl branchControl;

  bool isShow = false;

  String markdownData = "";

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
    return Container(
        child: SingleChildScrollView(
            child: new MarkdownBody(data: markdownData),
        )
    );
  }
}
