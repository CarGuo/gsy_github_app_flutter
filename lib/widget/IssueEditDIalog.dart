import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';
import 'package:gsy_github_app_flutter/widget/GSYInputWidget.dart';

/**
 * issue 编辑输入框
 * Created by guoshuyu
 * on 2018/7/21.
 */
class IssueEditDialog extends StatefulWidget {
  @override
  _IssueEditDialogState createState() => _IssueEditDialogState();
}

class _IssueEditDialogState extends State<IssueEditDialog> {
  @override
  Widget build(BuildContext context) {
    return new GSYCardItem(
      margin: EdgeInsets.all(30.0),
      shape: new RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
      child: new Padding(
        padding: new EdgeInsets.all(12.0),
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Container(height: 10.0),
            new Center(child: new Text("Title")),
            new GSYInputWidget(
              hintText: GSYStrings.login_password_hint_text,
              obscureText: false,
            ),
            new Container(height: 10.0),
            new Container(
              height: 300.0,
              decoration: new BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                color: Colors.white,
                border: new Border.all(color: Color(GSYColors.subTextColor), width: 1.0),
              ),
              padding: new EdgeInsets.only(left: 20.0, top: 12.0, right: 20.0, bottom: 12.0),
              child: new TextField(
                autofocus: false,
                decoration: new InputDecoration.collapsed(
                  hintText: GSYStrings.repos_issue_search,
                  hintStyle: GSYConstant.middleSubText,
                ),
                style: GSYConstant.middleText,
              ),
            ),
            new Container(height: 10.0),
            new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Expanded(child: new FlatButton(child: new Text("FFF"), onPressed: () {})),
                new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subTextColor)),
                new Expanded(child: new FlatButton(child: new Text("FFF"), onPressed: () {})),
              ],
            )
          ],
        ),
      ),
    );
  }
}
