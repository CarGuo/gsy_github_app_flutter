import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/config/config.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/repositories/repos_repository.dart';
import 'package:gsy_github_app_flutter/common/local/local_storage.dart';
import 'package:gsy_github_app_flutter/model/common_list_datatype.dart';
import 'package:gsy_github_app_flutter/model/user.dart';
import 'package:gsy_github_app_flutter/provider/app_state_provider.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/redux/login_redux.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/gsy_flex_button.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 主页drawer
/// Created by guoshuyu
/// Date: 2018-07-18
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  showAboutDialog(BuildContext context, String? versionName) {
    versionName ??= "Null";
    NavigatorUtils.showGSYDialog(
        context: context,
        builder: (BuildContext context) => AboutDialog(
              applicationName: context.l10n.app_name,
              applicationVersion:
                  "${context.l10n.app_version}: ${versionName ?? ""}",
              applicationIcon: const Image(
                  image: AssetImage(GSYICons.DEFAULT_USER_ICON),
                  width: 50.0,
                  height: 50.0),
              applicationLegalese: "http://github.com/CarGuo",
            ));
  }

  showThemeDialog(BuildContext context, WidgetRef ref) {
    StringList list = [
      context.l10n.home_theme_default,
      context.l10n.home_theme_1,
      context.l10n.home_theme_2,
      context.l10n.home_theme_3,
      context.l10n.home_theme_4,
      context.l10n.home_theme_5,
      context.l10n.home_theme_6,
    ];
    CommonUtils.showCommitOptionDialog(context, list, (index) {
      ref.read(appThemeStateProvider.notifier).pushTheme(index.toString());
      LocalStorage.save(Config.THEME_COLOR, index.toString());
    }, colorList: CommonUtils.getThemeListColor());
  }

  @override
  Widget build(BuildContext context) {
    return Material(child:
        Consumer(builder: (BuildContext context, WidgetRef ref, Widget? child) {
      var themeData = ref.watch(appThemeStateProvider);
      return StoreBuilder<GSYState>(
        builder: (context, store) {
          User user = store.state.userInfo!;
          return Drawer(
            ///侧边栏按钮Drawer
            child: Container(
              ///默认背景
              color: themeData.primaryColor,
              child: SingleChildScrollView(
                ///item 背景
                child: Container(
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height),
                  child: Material(
                    color: GSYColors.white,
                    child: Column(
                      children: <Widget>[
                        UserAccountsDrawerHeader(
                          //Material内置控件
                          accountName: Text(
                            user.login ?? "---",
                            style: GSYConstant.largeTextWhite,
                          ),
                          accountEmail: Text(
                            user.email ?? user.name ?? "---",
                            style: GSYConstant.normalTextLight,
                          ),
                          //用户名
                          //用户邮箱
                          currentAccountPicture: GestureDetector(
                            //用户头像
                            onTap: () {},
                            child: CircleAvatar(
                              //圆形图标控件
                              backgroundImage: NetworkImage(user.avatar_url ??
                                  GSYICons.DEFAULT_REMOTE_PIC),
                            ),
                          ),
                          decoration: BoxDecoration(
                            //用一个BoxDecoration装饰器提供背景图片
                            color: themeData.primaryColor,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            context.l10n.home_reply,
                            style: GSYConstant.normalText,
                          ),
                          onTap: () {
                            String content = "";
                            CommonUtils.showEditDialog(
                              context,
                              context.l10n.home_reply,
                              (title) {},
                              (res) {
                                content = res;
                              },
                              () {
                                if (content.isEmpty) {
                                  return;
                                }
                                CommonUtils.showLoadingDialog(context);
                                IssueRepository.createIssueRequest(
                                    "CarGuo", "gsy_github_app_flutter", {
                                  "title": context.l10n.home_reply,
                                  "body": content
                                }).then((result) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                              },
                              titleController: TextEditingController(),
                              valueController: TextEditingController(),
                              needTitle: false,
                              hintText: context.l10n.feed_back_tip,
                            );
                          },
                        ),
                        ListTile(
                            title: Text(
                              context.l10n.home_history,
                              style: GSYConstant.normalText,
                            ),
                            onTap: () {
                              NavigatorUtils.gotoCommonList(
                                  context,
                                  context.l10n.home_history,
                                  "repositoryql",
                                  CommonListDataType.history,
                                  userName: "",
                                  reposName: "");
                            }),
                        ListTile(
                            title: Hero(
                                tag: "home_user_info",
                                child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      context.l10n.home_user_info,
                                      style: GSYConstant.normalTextBold,
                                    ))),
                            onTap: () {
                              NavigatorUtils.gotoUserProfileInfo(context);
                            }),
                        ListTile(
                            title: Text(
                              context.l10n.home_change_theme,
                              style: GSYConstant.normalText,
                            ),
                            onTap: () {
                              showThemeDialog(context, ref);
                            }),
                        ListTile(
                            title: Text(
                              context.l10n.home_change_language,
                              style: GSYConstant.normalText,
                            ),
                            onTap: () {
                              CommonUtils.showLanguageDialog(ref);
                            }),
                        ListTile(
                            title: Text(
                              context.l10n.home_change_grey,
                              style: GSYConstant.normalText,
                            ),
                            onTap: () {
                              ref
                                  .read(appGrepStateProvider.notifier)
                                  .changeGrey();
                            }),
                        ListTile(
                            title: Text(
                              context.l10n.home_check_update,
                              style: GSYConstant.normalText,
                            ),
                            onTap: () {
                              ReposRepository.getNewsVersion(context, true);
                            }),
                        ListTile(
                            title: Text(
                              context.l10n.home_about,
                              style: GSYConstant.normalText,
                            ),
                            onLongPress: () {
                              NavigatorUtils.goDebugDataPage(context);
                            },
                            onTap: () {
                              PackageInfo.fromPlatform().then((value) {
                                if (kDebugMode) {
                                  print(value);
                                }
                                if (!context.mounted) return;
                                showAboutDialog(context, value.version);
                              });
                            }),
                        ListTile(
                            title: GSYFlexButton(
                              text: context.l10n.login_out,
                              color: Colors.redAccent,
                              textColor: GSYColors.textWhite,
                              onPress: () {
                                store.dispatch(LogoutAction(context));
                              },
                            ),
                            onTap: () {}),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }));
  }
}
