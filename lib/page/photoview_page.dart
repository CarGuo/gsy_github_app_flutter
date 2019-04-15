import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';
import 'package:photo_view/photo_view.dart';

/**
 * 图片预览
 * Created by guoshuyu
 * Date: 2018-08-09
 */

class PhotoViewPage extends StatelessWidget {
  final String url;

  PhotoViewPage(this.url);

  @override
  Widget build(BuildContext context) {
    OptionControl optionControl = new OptionControl();
    optionControl.url = url;
    return new Scaffold(
        floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.file_download),
          onPressed: () {
            CommonUtils.saveImage(url).then((res) {
              if (res != null) {
                Fluttertoast.showToast(msg: res);
                if (Platform.isAndroid) {
                  const updateAlbum = const MethodChannel('com.shuyu.gsygithub.gsygithubflutter/UpdateAlbumPlugin');
                  updateAlbum.invokeMethod('updateAlbum', { 'path': res, 'name': CommonUtils.splitFileNameByPath(res)});
                }
              }
            });
          },
        ),
        appBar: new AppBar(
          title: GSYTitleBar("", rightWidget: new GSYCommonOptionWidget(optionControl)),
        ),
        body: new Container(
          color: Colors.black,
          child: new PhotoView(
            imageProvider: new NetworkImage(url ?? GSYICons.DEFAULT_REMOTE_PIC),
            loadingChild: Container(
              child: new Stack(
                children: <Widget>[
                  new Center(child: new Image.asset(GSYICons.DEFAULT_IMAGE, height: 180.0, width: 180.0)),
                  new Center(child: new SpinKitFoldingCube(color: Colors.white30, size: 60.0)),
                ],
              ),
            ),
          ),
        ));
  }
}
