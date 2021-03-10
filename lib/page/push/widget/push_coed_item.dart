import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/model/CommitFile.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';

/**
 * 推送修改代码Item
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
        ///修改文件路径
        margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 0.0),
        child: new Text(
          pushCodeItemViewModel.path,
          style: GSYConstant.smallSubLightText,
        ),
      ),
      new GSYCardItem(
        ///修改文件名
        margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
        child: new ListTile(
          title: new Text(pushCodeItemViewModel.name!, style: GSYConstant.smallSubText),
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
  late String path;
  String? name;
  String? patch;

  String? blob_url;

  PushCodeItemViewModel();

  PushCodeItemViewModel.fromMap(CommitFile map) {
    String filename = map.fileName!;
    List<String> nameSplit = filename.split("/");
    name = nameSplit[nameSplit.length - 1];
    path = filename;
    patch = map.patch;
    blob_url = map.blobUrl;
  }
}
