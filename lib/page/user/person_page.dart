// ignore_for_file: annotate_overrides

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/event_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/user_repository.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/model/user_org.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/page/user/base_person_provider.dart';
import 'package:gsy_github_app_flutter/widget/pull/nested/gsy_nested_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/page/user/base_person_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_common_option_widget.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';

/// 个人详情
/// Created by guoshuyu
/// Date: 2018-07-18
class PersonPage extends StatefulWidget {
  static const String sName = "person";

  final String? userName;

  const PersonPage(this.userName, {super.key});

  @override
  PersonState createState() => PersonState();
}

class PersonState extends BasePersonState<PersonPage> {
  String beStaredCount = "---";

  bool focusStatus = false;

  String focus = "";

  User? userInfo = User.empty();

  // ignore: overridden_fields
  final List<UserOrg> orgList = [];

  PersonState();

  ///处理用户信息显示
  _resolveUserInfo(res) {
    if (isShow) {
      setState(() {
        userInfo = res.data;
      });
    }
  }

  @override
  Future<void> handleRefresh() async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    page = 1;

    ///获取网络用户数据
    var userResult =
        await UserRepository.getUserInfo(widget.userName, needDb: true);
    if (userResult != null && userResult.result) {
      _resolveUserInfo(userResult);
      if (userResult.next != null) {
        userResult.next().then((resNext) {
          _resolveUserInfo(resNext);
        });
      }
    } else {
      return;
    }

    ///获取用户动态或者组织成员
    var res = await _getDataLogic();
    resolveRefreshResult(res);
    resolveDataResult(res);
    if (res.next != null) {
      var resNext = await res.next();
      resolveRefreshResult(resNext);
      resolveDataResult(resNext);
    }
    isLoading = false;

    ///获取当前用户的关注状态
    _getFocusStatus();

    ///获取用户仓库前100个star统计数据
    getHonor();
    return;
  }

  ///获取当前用户的关注状态
  _getFocusStatus() async {
    var focusRes = await UserRepository.checkFollowRequest(widget.userName!);
    if (isShow) {
      setState(() {
        focus = (focusRes != null && focusRes.result)
            ? context.l10n.user_focus
            : context.l10n.user_un_focus;
        focusStatus = (focusRes != null && focusRes.result);
      });
    }
  }

  ///获取用户信息里的用户名
  _getUserName() {
    if (userInfo == null) {
      return User.empty();
    }
    return userInfo!.login;
  }

  ///获取用户动态或者组织成员
  _getDataLogic() async {
    if (userInfo!.type == "Organization") {
      return await UserRepository.getMemberRequest(_getUserName(), page);
    }
    getUserOrg(_getUserName());
    return await EventRepository.getEventRequest(_getUserName(),
        page: page, needDb: page <= 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  requestRefresh() async {}

  @override
  requestLoadMore() async {
    return await _getDataLogic();
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  @override
  Widget buildContainer(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: GSYTitleBar(
          (userInfo != null && userInfo!.login != null) ? userInfo!.login : "",
          rightWidget: GSYCommonOptionWidget(
            url: userInfo?.html_url,
          ),
        )),
        floatingActionButton: FloatingActionButton(
            child: AutoSizeText(
              focus,
              minFontSize: 8,
              maxLines: 1,
            ),
            onPressed: () {
              ///非组织成员可以关注
              if (focus == '') {
                return;
              }
              if (userInfo!.type == "Organization") {
                Fluttertoast.showToast(msg: context.l10n.user_focus_no_support);
                return;
              }
              CommonUtils.showLoadingDialog(context);
              UserRepository.doFollowRequest(widget.userName!, focusStatus)
                  .then((res) {
                Navigator.pop(context);
                _getFocusStatus();
              });
            }),
        body: GSYNestedPullLoadWidget(
          pullLoadWidgetControl,
          (BuildContext context, int index) =>
              renderItem(index, userInfo!, beStaredCount, null, null, orgList),
          handleRefresh,
          onLoadMore,
          refreshKey: refreshIKey,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return sliverBuilder(context, innerBoxIsScrolled, userInfo!, null,
                beStaredCount, null);
          },
        ));
  }

  @override
  FetchHonorDataProvider get headerProvider {
    return fetchHonorDataProvider(_getUserName());
  }
}
