import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/model/push_commit.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// 提交详情的头
/// Created by guoshuyu
/// Date: 2018-07-27
class PushHeader extends StatelessWidget {
  final PushHeaderViewModel pushHeaderViewModel;

  const PushHeader(this.pushHeaderViewModel, {super.key});

  /// 头部变化数量图标
  _getIconItem(IconData icon, String text) {
    return GSYIConText(
      icon,
      text,
      GSYConstant.smallSubLightText,
      GSYColors.subLightTextColor,
      15.0,
      padding: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GSYCardItem(
      color: Theme.of(context).primaryColor,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.all(0.0)),
        onPressed: () {},
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ///用户头像
                  GSYUserIconWidget(
                      padding: const EdgeInsets.only(
                          top: 0.0, right: 5.0, left: 0.0),
                      width: 40.0,
                      height: 40.0,
                      image: pushHeaderViewModel.actionUserPic,
                      onPressed: () {
                        NavigatorUtils.goPerson(
                            context, pushHeaderViewModel.actionUser);
                      }),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ///变化状态
                        Row(
                          children: <Widget>[
                            _getIconItem(GSYICons.PUSH_ITEM_EDIT,
                                pushHeaderViewModel.editCount),
                            Container(width: 8.0),
                            _getIconItem(GSYICons.PUSH_ITEM_ADD,
                                pushHeaderViewModel.addCount),
                            Container(width: 8.0),
                            _getIconItem(GSYICons.PUSH_ITEM_MIN,
                                pushHeaderViewModel.deleteCount),
                            Container(width: 8.0),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.all(2.0)),

                        ///修改时间
                        Container(
                            margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft,
                            child: Text(
                              pushHeaderViewModel.pushTime,
                              style: GSYConstant.smallTextWhite,
                              maxLines: 2,
                            )),

                        ///修改的commit内容
                        Container(
                            margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                            alignment: Alignment.topLeft,
                            child: Text(
                              pushHeaderViewModel.pushDes,
                              style: GSYConstant.smallTextWhite,
                              maxLines: 2,
                            )),
                        const Padding(
                          padding: EdgeInsets.only(
                              left: 0.0, top: 2.0, right: 0.0, bottom: 0.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PushHeaderViewModel {
  String? actionUser = "---";
  String? actionUserPic;
  String pushDes = "---";
  String pushTime = "---";
  String editCount = "---";
  String addCount = "---";
  String deleteCount = "---";
  String? htmlUrl = GSYConstant.app_default_share_url;

  PushHeaderViewModel();

  PushHeaderViewModel.forMap(PushCommit pushMap) {
    String? name = "---";
    String? pic;
    if (pushMap.committer != null) {
      name = pushMap.committer!.login;
    } else if (pushMap.commit != null && pushMap.commit!.author != null) {
      name = pushMap.commit!.author!.name;
    }
    if (pushMap.committer != null && pushMap.committer!.avatar_url != null) {
      pic = pushMap.committer!.avatar_url;
    }
    actionUser = name;
    actionUserPic = pic;
    pushDes = "Push at ${pushMap.commit!.message!}";
    pushTime = CommonUtils.getNewsTimeStr(pushMap.commit!.committer!.date!);
    editCount = "${pushMap.files!.length}";
    addCount = "${pushMap.stats!.additions}";
    deleteCount = "${pushMap.stats!.deletions}";
    htmlUrl = pushMap.htmlUrl;
  }
}
