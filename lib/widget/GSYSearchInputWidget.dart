import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

/**
 * 搜索输入框
 * Created by guoshuyu
 * Date: 2018-07-20
 */
class GSYSearchInputWidget extends StatelessWidget {

  final ValueChanged<String> onChanged;

  final ValueChanged<String> onSubmitted;

  GSYSearchInputWidget(this.onChanged, this.onSubmitted);

  @override
  Widget build(BuildContext context) {
    return new Container(
      decoration: new BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          color: Colors.white,
          border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)),
      padding: new EdgeInsets.only(left: 20.0, top: 12.0, right: 20.0, bottom: 12.0),
      child: new TextField(
          autofocus: false,
          decoration: new InputDecoration.collapsed(
            hintText: GSYStrings.repos_issue_search,
            hintStyle: GSYConstant.middleSubText,
          ),
          style: GSYConstant.middleText,
          onChanged: onChanged,
          onSubmitted: onSubmitted),
    );
  }
}
