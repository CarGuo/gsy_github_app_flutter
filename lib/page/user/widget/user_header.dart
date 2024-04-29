import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gsy_github_app_flutter/common/localization/default_localizations.dart';
import 'package:gsy_github_app_flutter/model/CommonListDataType.dart';
import 'package:gsy_github_app_flutter/model/User.dart';
import 'package:gsy_github_app_flutter/model/UserOrg.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_icon_text.dart';
import 'package:gsy_github_app_flutter/widget/gsy_user_icon_widget.dart';

/// 用户详情头部
/// Created by guoshuyu
/// Date: 2018-07-17
class UserHeaderItem extends StatelessWidget {
  final User userInfo;

  final String beStaredCount;

  final Color? notifyColor;

  final Color themeColor;

  final VoidCallback? refreshCallBack;

  final List<UserOrg>? orgList;

  UserHeaderItem(this.userInfo, this.beStaredCount, this.themeColor,
      {this.notifyColor, this.refreshCallBack, this.orgList});

  ///通知Icon
  _getNotifyIcon(BuildContext context, Color? color) {
    if (notifyColor == null) {
      return Container();
    }
    return RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.only(top: 0.0, right: 5.0, left: 5.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        child: ClipOval(
          child: Icon(
            GSYICons.USER_NOTIFY,
            color: color,
            size: 18.0,
          ),
        ),
        onPressed: () {
          NavigatorUtils.goNotifyPage(context).then((res) {
            refreshCallBack?.call();
          });
        });
  }

  ///用户组织
  _renderOrgs(BuildContext context, List<UserOrg>? orgList) {
    if (orgList == null || orgList.isEmpty) {
      return Container();
    }
    List<Widget> list = [];

    renderOrgsItem(UserOrg orgs) {
      return GSYUserIconWidget(
          padding: const EdgeInsets.only(right: 5.0, left: 5.0),
          width: 30.0,
          height: 30.0,
          image: orgs.avatarUrl ?? GSYICons.DEFAULT_REMOTE_PIC,
          onPressed: () {
            NavigatorUtils.goPerson(context, orgs.login);
          });
    }

    int length = orgList.length > 3 ? 3 : orgList.length;

    list.add(Text("${GSYLocalizations.i18n(context)!.user_orgs_title}:",
        style: GSYConstant.smallSubLightText));

    for (int i = 0; i < length; i++) {
      list.add(renderOrgsItem(orgList[i]));
    }
    if (orgList.length > 3) {
      list.add(RawMaterialButton(
          onPressed: () {
            NavigatorUtils.gotoCommonList(
                context,
                "${userInfo.login!} ${GSYLocalizations.i18n(context)!.user_orgs_title}",
                "org",
                CommonListDataType.userOrgs,
                userName: userInfo.login);
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.only(right: 5.0, left: 5.0),
          constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
          child: const Icon(
            Icons.more_horiz,
            color: GSYColors.white,
            size: 18.0,
          )));
    }
    return Row(children: list);
  }

  _renderImg(context) {
    return RawMaterialButton(
        onPressed: () {
          if (userInfo.avatar_url != null) {
            NavigatorUtils.gotoPhotoViewPage(context, userInfo.avatar_url);
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(0.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        child: ClipOval(
          child: FadeInImage.assetNetwork(
            placeholder: GSYICons.DEFAULT_USER_ICON,
            //预览图
            fit: BoxFit.fitWidth,
            image: userInfo.avatar_url ?? GSYICons.DEFAULT_REMOTE_PIC,
            width: 80.0,
            height: 80.0,
          ),
        ));
  }

  _renderUserInfo(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            ///用户名
            Text(userInfo.login ?? "",
                style: GSYConstant.largeTextWhiteBold),
            _getNotifyIcon(context, notifyColor),
          ],
        ),
        Text(userInfo.name == null ? "" : userInfo.name!,
            style: GSYConstant.smallSubLightText),

        ///用户组织
        GSYIConText(
          GSYICons.USER_ITEM_COMPANY,
          userInfo.company ?? GSYLocalizations.i18n(context)!.nothing_now,
          GSYConstant.smallSubLightText,
          GSYColors.subLightTextColor,
          10.0,
          padding: 3.0,
        ),

        ///用户位置
        GSYIConText(
          GSYICons.USER_ITEM_LOCATION,
          userInfo.location ?? GSYLocalizations.i18n(context)!.nothing_now,
          GSYConstant.smallSubLightText,
          GSYColors.subLightTextColor,
          10.0,
          padding: 3.0,
        ),
      ],
    );
  }

  _renderBlog(context) {
    return Container(

        ///用户博客
        child: RawMaterialButton(
          onPressed: () {
            if (userInfo.blog != null) {
              CommonUtils.launchOutURL(userInfo.blog!, context);
            }
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(0.0),
          constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
          child: GSYIConText(
            GSYICons.USER_ITEM_LINK,
            userInfo.blog ?? GSYLocalizations.i18n(context)!.nothing_now,
            (userInfo.blog == null)
                ? GSYConstant.smallSubLightText
                : GSYConstant.smallActionLightText,
            GSYColors.subLightTextColor,
            10.0,
            padding: 3.0,
            textWidth: MediaQuery.sizeOf(context).width - 50,
          ),
        ),
        margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
        alignment: Alignment.topLeft);
  }

  @override
  Widget build(BuildContext context) {
    return GSYCardItem(
        color: themeColor,
        elevation: 0,
        margin: const EdgeInsets.all(0.0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0.0),
                bottomRight: Radius.circular(0.0))),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 10.0, top: 10.0, right: 10.0, bottom: 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ///用户头像
                  _renderImg(context),
                  const Padding(padding: EdgeInsets.all(10.0)),
                  Expanded(
                    child: _renderUserInfo(context),
                  ),
                ],
              ),
              _renderBlog(context),

              ///组织
              _renderOrgs(context, orgList),

              ///用户描述
              Container(
                  child: Text(
                    userInfo.bio == null ? "" : userInfo.bio!,
                    style: GSYConstant.smallSubLightText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  alignment: Alignment.topLeft),

              ///用户创建时长
              Container(
                  child: Text(
                    GSYLocalizations.i18n(context)!.user_create_at +
                        CommonUtils.getDateStr(userInfo.created_at),
                    style: GSYConstant.smallSubLightText,
                    overflow: TextOverflow.ellipsis,
                  ),
                  margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                  alignment: Alignment.topLeft),
              const Padding(padding: EdgeInsets.only(bottom: 5.0)),
            ],
          ),
        ));
  }
}

class UserHeaderBottom extends StatelessWidget {
  final User userInfo;
  final String beStaredCount;
  final Radius radius;
  final List? honorList;

  UserHeaderBottom(
      this.userInfo, this.beStaredCount, this.radius, this.honorList);

  ///底部状态栏
  _getBottomItem(String? title, var value, onPressed) {
    String data = value == null ? "" : value.toString();
    TextStyle valueStyle = (value != null && value.toString().length > 6)
        ? GSYConstant.minText
        : GSYConstant.smallSubLightText;
    TextStyle titleStyle = (title != null && title.toString().length > 6)
        ? GSYConstant.minText
        : GSYConstant.smallSubLightText;
    return Expanded(
      child: Center(
          child: RawMaterialButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(top: 5.0),
              constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(text: title, style: titleStyle),
                    TextSpan(text: "\n", style: valueStyle),
                    TextSpan(text: data, style: valueStyle)
                  ],
                ),
              ),
              onPressed: onPressed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ///用户底部状态
    return GSYCardItem(
      color: Theme.of(context).primaryColor,
      margin: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.only(bottomLeft: radius, bottomRight: radius)),
      child: Container(
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _getBottomItem(
              GSYLocalizations.of(context)!.currentLocalized!.user_tab_repos,
              userInfo.public_repos,
              () {
                NavigatorUtils.gotoCommonList(
                    context, userInfo.login, "repository", CommonListDataType.userRepos,
                    userName: userInfo.login);
              },
            ),
            Container(
                width: 0.3,
                height: 40.0,
                alignment: Alignment.center,
                color: GSYColors.subLightTextColor),
            _getBottomItem(
              GSYLocalizations.i18n(context)!.user_tab_fans,
              userInfo.followers,
              () {
                NavigatorUtils.gotoCommonList(
                    context, userInfo.login, "user", CommonListDataType.follower,
                    userName: userInfo.login);
              },
            ),
            Container(
                width: 0.3,
                height: 40.0,
                alignment: Alignment.center,
                color: GSYColors.subLightTextColor),
            _getBottomItem(
              GSYLocalizations.i18n(context)!.user_tab_focus,
              userInfo.following,
              () {
                NavigatorUtils.gotoCommonList(
                    context, userInfo.login, "user", CommonListDataType.followed,
                    userName: userInfo.login);
              },
            ),
            Container(
                width: 0.3,
                height: 40.0,
                alignment: Alignment.center,
                color: GSYColors.subLightTextColor),
            _getBottomItem(
              GSYLocalizations.i18n(context)!.user_tab_star,
              userInfo.starred,
              () {
                NavigatorUtils.gotoCommonList(
                    context, userInfo.login, "repository", CommonListDataType.userStar,
                    userName: userInfo.login);
              },
            ),
            Container(
                width: 0.3,
                height: 40.0,
                alignment: Alignment.center,
                color: GSYColors.subLightTextColor),
            _getBottomItem(
              GSYLocalizations.i18n(context)!.user_tab_honor,
              beStaredCount,
              () {
                if (honorList != null) {
                  NavigatorUtils.goHonorListPage(context, honorList);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UserHeaderChart extends StatelessWidget {
  final User userInfo;

  UserHeaderChart(this.userInfo);

  _renderChart(context) {
    double height = 140.0;
    double width = 3 * MediaQuery.sizeOf(context).width / 2;
    if (userInfo.login != null && userInfo.type == "Organization") {
      return Container();
    }
    return (userInfo.login != null)
        ? Card(
            margin:
                const EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0, bottom: 0.0),
            color: GSYColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                width: width,
                height: height,

                ///svg chart
                child: SvgPicture.network(
                  CommonUtils.getUserChartAddress(userInfo.login!),
                  width: width,
                  height: height - 10,
                  allowDrawingOutsideViewBox: true,
                  placeholderBuilder: (BuildContext context) => SizedBox(
                    height: height,
                    width: width,
                    child: Center(
                      child:
                          SpinKitRipple(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ),
            ),
          )
        : SizedBox(
            height: height,
            child: Center(
              child: SpinKitRipple(color: Theme.of(context).primaryColor),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            child: Text(
              (userInfo.type == "Organization")
                  ? GSYLocalizations.i18n(context)!.user_dynamic_group
                  : GSYLocalizations.i18n(context)!.user_dynamic_title,
              style: GSYConstant.normalTextBold,
              overflow: TextOverflow.ellipsis,
            ),
            margin: const EdgeInsets.only(top: 15.0, bottom: 15.0, left: 12.0),
            alignment: Alignment.topLeft),
        _renderChart(context),
      ],
    );
  }
}
