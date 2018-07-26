import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/dao/ReposDao.dart';
import 'package:gsy_github_app_flutter/common/net/Address.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCommonOptionWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYMarkdownWidget.dart';
import 'package:gsy_github_app_flutter/widget/GSYTitleBar.dart';

/**
 * 文件代码详情
 * Created by guoshuyu
 * Date: 2018-07-24
 */

class CodeDetailPage extends StatefulWidget {
  final String userName;

  final String reposName;

  final String path;

  final String data;

  final String title;

  final String branch;

  CodeDetailPage({this.title, this.userName, this.reposName, this.path, this.data, this.branch});

  @override
  _CodeDetailPageState createState() => _CodeDetailPageState(this.title, this.userName, this.reposName, this.path, this.data, this.branch);
}

class _CodeDetailPageState extends State<CodeDetailPage> {
  final String userName;

  final String reposName;

  final String path;

  final String branch;

  String data;

  final String title;

  _CodeDetailPageState(this.title, this.userName, this.reposName, this.path, this.data, this.branch);

  @override
  void initState() {
    super.initState();
    if (data == null) {
      ReposDao.getReposFileDirDao(userName, reposName, path: path, branch: branch, text: true).then((res) {
        if (res != null && res.result) {
          setState(() {
            data = res.data;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentBranch = ((branch == null) ? "" : ("/" + branch));
    String url = Address.hostWeb + userName + "/" + reposName  + "/blob" + currentBranch + path;
    Widget widget = (data == null)
        ? new Center(
            child: new Container(
              width: 140.0,
              height: 140.0,
              padding: new EdgeInsets.all(4.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new CircularProgressIndicator(),
                  new Container(width: 10.0),
                  new Container(child: new Text(GSYStrings.loading_text, style: GSYConstant.middleText)),
                ],
              ),
            ),
          )
        : new GSYMarkdownWidget(markdownData: data);

    return new Scaffold(
      appBar: new AppBar(
        title:  GSYTitleBar(
          title,
          rightWidget: new GSYCommonOptionWidget(url),
          needRightLocalIcon: false,
        ),
      ),
      body: widget,
    );
  }
}
