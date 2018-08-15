import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/common/utils/CommonUtils.dart';
import 'package:share/share.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-26
 */
class GSYCommonOptionWidget extends StatelessWidget {
  final List<GSYOptionModel> otherList;

  final OptionControl control;

  GSYCommonOptionWidget(this.control, {this.otherList});

  _renderHeaderPopItem(List<GSYOptionModel> list) {
    return new PopupMenuButton<GSYOptionModel>(
      child: new Icon(GSYICons.MORE),
      onSelected: (model) {
        model.selected(model);
      },
      itemBuilder: (BuildContext context) {
        return _renderHeaderPopItemChild(list);
      },
    );
  }

  _renderHeaderPopItemChild(List<GSYOptionModel> data) {
    List<PopupMenuEntry<GSYOptionModel>> list = new List();
    for (GSYOptionModel item in data) {
      list.add(PopupMenuItem<GSYOptionModel>(
        value: item,
        child: new Text(item.name),
      ));
    }
    return list;
  }


  @override
  Widget build(BuildContext context) {
    List<GSYOptionModel> list = [
      new GSYOptionModel(CommonUtils.getLocale(context).option_web, CommonUtils.getLocale(context).option_web, (model) {
        CommonUtils.launchOutURL(control.url, context);
      }),
      new GSYOptionModel(CommonUtils.getLocale(context).option_copy, CommonUtils.getLocale(context).option_copy, (model) {
        CommonUtils.copy(control.url ?? "", context);
      }),
      new GSYOptionModel(CommonUtils.getLocale(context).option_share, CommonUtils.getLocale(context).option_share, (model) {
        Share.share(CommonUtils.getLocale(context).option_share_title + control.url ?? "");
      }),
    ];
    if (otherList != null && otherList.length > 0) {
      list.addAll(otherList);
    }
    return _renderHeaderPopItem(list);
  }
}

class OptionControl {
  String url = GSYConstant.app_default_share_url;
}

class GSYOptionModel {
  final String name;
  final String value;
  final PopupMenuItemSelected<GSYOptionModel> selected;

  GSYOptionModel(this.name, this.value, this.selected);
}
