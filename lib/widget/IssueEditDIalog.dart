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
  final String dialogTitle;

  final ValueChanged<String> onTitleChanged;

  final ValueChanged<String> onContentChanged;

  final VoidCallback onPressed;

  final TextEditingController titleController;

  final TextEditingController valueController;

  final bool needTitle;

  IssueEditDialog(this.dialogTitle, this.onContentChanged, this.onTitleChanged, this.onPressed,
      {this.titleController, this.valueController, this.needTitle = true});

  @override
  _IssueEditDialogState createState() =>
      _IssueEditDialogState(this.dialogTitle, this.onContentChanged, this.onTitleChanged, this.onPressed, titleController, valueController, needTitle);
}

class _IssueEditDialogState extends State<IssueEditDialog> {
  final String dialogTitle;

  final ValueChanged<String> onTitleChanged;

  final ValueChanged<String> onContentChanged;

  final VoidCallback onPressed;

  final TextEditingController titleController;

  final TextEditingController valueController;

  final bool needTitle;

  _IssueEditDialogState(
      this.dialogTitle, this.onContentChanged, this.onTitleChanged, this.onPressed, this.titleController, this.valueController, this.needTitle);

  @override
  Widget build(BuildContext context) {
    Widget title = (needTitle)
        ? new Padding(
            padding: new EdgeInsets.all(5.0),
            child: new GSYInputWidget(
              onChanged: onTitleChanged,
              controller: titleController,
              hintText: GSYStrings.login_password_hint_text,
              obscureText: false,
            ))
        : new Container();

    return new GSYCardItem(
      margin: EdgeInsets.all(30.0),
      shape: new RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
      child: new Padding(
        padding: new EdgeInsets.all(12.0),
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Padding(
                padding: new EdgeInsets.all(5.0),
                child: new Center(
                  child: new Text(dialogTitle, style: GSYConstant.smallTextBold),
                )),
            title,
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
                maxLines: 999,
                onChanged: onContentChanged,
                controller: valueController,
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
                new Expanded(
                    child: new FlatButton(
                        child: new Text(GSYStrings.app_cancel),
                        onPressed: () {
                          Navigator.pop(context);
                        })),
                new Container(width: 0.3, height: 30.0, color: Color(GSYColors.subTextColor)),
                new Expanded(child: new FlatButton(child: new Text(GSYStrings.app_cancel), onPressed: () {})),
              ],
            )
          ],
        ),
      ),
    );
  }
}
