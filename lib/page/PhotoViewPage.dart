import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';
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
    return new Scaffold(
      appBar: new AppBar(),
      body: new Container(
        child: new PhotoView(
          imageProvider: new NetworkImage(url ?? GSYICons.DEFAULT_REMOTE_PIC),
          loadingChild: Container(
            child: new Stack(
              children: <Widget>[
                new Center(child: new Image.asset(GSYICons.DEFAULT_IMAGE)),
                new Center(child: new SpinKitDoubleBounce(color: Color(GSYColors.primaryValue))),
              ],
            ),
          ),
        ),
      )
    );

  }
}
