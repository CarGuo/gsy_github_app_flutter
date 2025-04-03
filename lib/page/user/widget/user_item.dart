import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/model/search_user_ql.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/model/user_org.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';

/// 用户item
/// Created by guoshuyu
/// Date: 2018-07-23
class UserItem extends StatelessWidget {
  final UserItemViewModel userItemViewModel;

  final VoidCallback? onPressed;

  final bool needImage;

  const UserItem(this.userItemViewModel,
      {super.key, this.onPressed, this.needImage = true});

  @override
  Widget build(BuildContext context) {
    var me = StoreProvider.of<GSYState>(context).state.userInfo!;
    Widget userImage = IconButton(
        padding: const EdgeInsets.only(
            top: 0.0, left: 0.0, bottom: 0.0, right: 10.0),
        icon: ClipOval(
          child: FadeInImage.assetNetwork(
            placeholder: GSYICons.DEFAULT_USER_ICON,
            key: (userItemViewModel.userPic != null &&
                    userItemViewModel.userPic!.isNotEmpty)
                ? ValueKey(userItemViewModel.userPic)
                : null,
            //预览图
            fit: BoxFit.fitWidth,
            image: (userItemViewModel.userPic != null &&
                    userItemViewModel.userPic!.isNotEmpty)
                ? userItemViewModel.userPic!
                : "https://github.com/CarGuo/gsy_github_app_flutter/blob/master/logo.png?raw=true",
            width: 40.0,
            height: 40.0,
          ),
        ),
        onPressed: null);

    return GSYCardItem(
      color: me.login == userItemViewModel.login
          ? Colors.amber
          : (userItemViewModel.login == "CarGuo")
              ? Colors.pink
              : Colors.white,
      child: TextButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 0.0, top: 5.0, right: 0.0, bottom: 10.0),
          child: Row(
            children: <Widget>[
              if (userItemViewModel.index != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(userItemViewModel.index!,
                      style: GSYConstant.middleSubTextBold),
                ),
              userImage,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(userItemViewModel.userName ?? "null",
                            style: GSYConstant.smallTextBold),
                        if (userItemViewModel.followers != null)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                  "followers: ${userItemViewModel.followers}",
                                  style: GSYConstant.smallSubText),
                            ),
                          ),
                      ],
                    ),
                    if (userItemViewModel.bio != null &&
                        userItemViewModel.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(userItemViewModel.bio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GSYConstant.smallText),
                      ),
                    if (userItemViewModel.lang != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 10),
                        child: Text(userItemViewModel.lang!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GSYConstant.smallSubText),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserItemViewModel {
  String? userPic;
  String? userName;
  String? bio;
  int? followers;
  String? login;
  String? lang;
  String? index;

  UserItemViewModel.fromMap(User user) {
    userName = user.login;
    userPic = user.avatar_url;
    followers = user.followers;
  }

  UserItemViewModel.fromQL(SearchUserQL user, int? index) {
    userName = user.name;
    userPic = user.avatarUrl;
    followers = user.followers;
    bio = user.bio;
    login = user.login;
    lang = user.lang;
    this.index = index.toString();
  }

  UserItemViewModel.fromOrgMap(UserOrg org) {
    userName = org.login;
    userPic = org.avatarUrl;
  }
}
