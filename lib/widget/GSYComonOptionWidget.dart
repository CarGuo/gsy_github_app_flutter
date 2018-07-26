import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-26
 */
class GSYCommonOptionWidget extends StatelessWidget {

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
      new GSYOptionModel("浏览器打开", "浏览器打开", (model) {
        print("浏览器打开");
      }),
      new GSYOptionModel("复制链接", "复制链接", (model) {
        print("复制链接");
      }),
      new GSYOptionModel("分享", "分享", (model) {
        print("分享");
      }),
    ];
    return _renderHeaderPopItem(list);
  }
}

class GSYOptionModel {
  final String name;
  final String value;
  final PopupMenuItemSelected<GSYOptionModel> selected;

  GSYOptionModel(this.name, this.value, this.selected);
}
