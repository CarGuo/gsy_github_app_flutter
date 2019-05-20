import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/dao/repos_dao.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_markdown_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';

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

  final String htmlUrl;

  CodeDetailPage({this.title, this.userName, this.reposName, this.path, this.data, this.branch, this.htmlUrl});

  @override
  _CodeDetailPageState createState() => _CodeDetailPageState();
}

class _CodeDetailPageState extends State<CodeDetailPage> {

  final OptionControl titleOptionControl = new OptionControl();

  String data;

  @override
  void initState() {
    super.initState();
    if (data == null) {
      ReposDao.getReposFileDirDao(widget.userName, widget.reposName, path: widget.path, branch: widget.branch, text: true).then((res) {
        if (res != null && res.result) {
          setState(() {
            data = res.data;
            titleOptionControl.url = widget.htmlUrl ?? "";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget widgetContent = (data == null)
        ? new Center(
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
        : new GSYMarkdownWidget(
            markdownData: data,
            style: GSYMarkdownWidget.DARK_LIGHT,
          );

    return new Scaffold(
      appBar: new AppBar(
        title: GSYTitleBar(
          widget.title,
          rightWidget: new GSYCommonOptionWidget(titleOptionControl),
          needRightLocalIcon: false,
        ),
      ),
      body: widgetContent,
    );
  }
}
