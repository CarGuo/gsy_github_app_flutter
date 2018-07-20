import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * 详情issue列表头部，PreferredSizeWidget
 * Created by guoshuyu
 * Date: 2018-07-19
 */

typedef void SelectItemChanged<int>(int value);

class RepositoryIssueListHeader extends StatefulWidget implements PreferredSizeWidget {


  final SelectItemChanged selectItemChanged;


  RepositoryIssueListHeader(this.selectItemChanged);

  @override
  _RepositoryIssueListHeaderState createState() => _RepositoryIssueListHeaderState(selectItemChanged);

  @override
  Size get preferredSize {
    return new Size.fromHeight(50.0);
  }
}

class _RepositoryIssueListHeaderState extends State<RepositoryIssueListHeader> {

  int selectIndex = 0;

  final SelectItemChanged selectItemChanged;


  _RepositoryIssueListHeaderState(this.selectItemChanged);

  _renderItem(String name, int index) {
    var style = index == selectIndex ? GSYConstant.middleTextWhite : GSYConstant.middleSubText;
    return new FlatButton(
        child: new Text(
          name,
          style: style,
          textAlign: TextAlign.center,
        ),
        onPressed: () {
          setState(() {
            selectIndex = index;
          });
          if (selectItemChanged != null) {
            selectItemChanged(index);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
        color: Color(GSYColors.primaryValue),
        margin: EdgeInsets.all(10.0),
        shape: new RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: new Padding(
            padding: new EdgeInsets.only(left: 0.0, top: 5.0, right: 0.0, bottom: 5.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: _renderItem(GSYStrings.repos_tab_issue_all, 0),
                ),
                new Container(width: 1.0, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                new Expanded(
                  child: _renderItem(GSYStrings.repos_tab_issue_open, 1),
                ),
                new Container(width: 1.0, height: 30.0, color: Color(GSYColors.subLightTextColor)),
                new Expanded(child: _renderItem(GSYStrings.repos_tab_issue_closed, 2)),
              ],
            )));
  }
}
