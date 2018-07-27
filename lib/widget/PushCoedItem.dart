import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
import 'package:gsy_github_app_flutter/widget/GSYCardItem.dart';

/**
 * Created by guoshuyu
 * Date: 2018-07-27
 */

class PushCodeItem extends StatelessWidget {
  final PushCodeItemViewModel pushCodeItemViewModel;
  final VoidCallback onPressed;

  PushCodeItem(this.pushCodeItemViewModel, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return new Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      new Container(
        margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 0.0),
        child: new Text(
          pushCodeItemViewModel.path,
          style: GSYConstant.subLightSmallText,
        ),
      ),
      new GSYCardItem(
        margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
        child: new ListTile(
          title: new Text(pushCodeItemViewModel.name, style: GSYConstant.subSmallText),
          leading: new Icon(
            GSYICons.REPOS_ITEM_FILE,
            size: 15.0,
          ),
          onTap: () {
            onPressed();
          },
        ),
      ),
    ]);
  }
}

class PushCodeItemViewModel {
  String path;
  String name;
  String patch;

  String blob_url;

  PushCodeItemViewModel();

  PushCodeItemViewModel.fromMap(map) {
    String filename = map["filename"];
    List<String> nameSplit = filename.split("/");
    name = nameSplit[nameSplit.length - 1];
    path = filename;
    patch = map["patch"];
    blob_url = map["blob_url"];
  }
}
