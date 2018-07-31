import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:url_launcher/url_launcher.dart';
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

  _launchURL() async {
    if (await canLaunch(control.url)) {
      await launch(control.url);
    } else {
      Fluttertoast.showToast(msg: GSYStrings.option_web_launcher_error + ": " + control.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    String text = GSYStrings.option_share_title + control.url ?? "";
    List<GSYOptionModel> list = [
      new GSYOptionModel(GSYStrings.option_web, GSYStrings.option_web, (model) {
        _launchURL();
      }),
      new GSYOptionModel(GSYStrings.option_copy, GSYStrings.option_copy, (model) {
        Clipboard.setData(new ClipboardData(text: control.url ?? ""));
        Fluttertoast.showToast(msg: GSYStrings.option_share_copy_success);
      }),
      new GSYOptionModel(GSYStrings.option_share, GSYStrings.option_share, (model) {
        Share.share(text);
      }),
    ];
    if (otherList != null && otherList.length > 0) {
      list.addAll(otherList);
    }
    return _renderHeaderPopItem(list);
  }
}

class OptionControl {
  String url = GSYStrings.app_default_share_url;
}

class GSYOptionModel {
  final String name;
  final String value;
  final PopupMenuItemSelected<GSYOptionModel> selected;

  GSYOptionModel(this.name, this.value, this.selected);
}
