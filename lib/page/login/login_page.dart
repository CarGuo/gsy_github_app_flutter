import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/net/address.dart';
import 'package:gsy_github_app_flutter/common/toast.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/redux/login_redux.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/widget/animated_background.dart';
import 'package:gsy_github_app_flutter/widget/gsy_flex_button.dart';
import 'package:gsy_github_app_flutter/widget/gsy_input_widget.dart';
import 'package:gsy_github_app_flutter/widget/particle/particle_widget.dart';

/// 登录页
/// Created by guoshuyu
/// Date: 2018-07-16
///
/// 2026 更新：GitHub 已于 2020-11-13 关停 basic-auth 密码 API，原账号/密码
/// 登录（[LoginBLoC.loginIn]）保留在 [LoginAction] 语义中但已不可用。
/// 主入口改为：
///   1. Token 登录（Personal Access Token 手输）
///   2. OAuth 登录（webview 授权拿 code 换 access_token）
/// 两条路径最终在 [UserRepository] 层汇聚到同一个 token 落地流程。
class LoginPage extends StatefulWidget {
  static const String sName = "login";

  const LoginPage({super.key});

  @override
  State createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> with LoginBLoC {
  @override
  Widget build(BuildContext context) {
    /// 触摸收起键盘
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
          return Container(
            color: Theme.of(context).primaryColor,
            child: Stack(children: <Widget>[
              const Positioned.fill(child: AnimatedBackground()),
              const Positioned.fill(child: ParticlesWidget(30)),
              Center(
                ///防止overFlow的现象
                child: SafeArea(
                  ///同时弹出键盘不遮挡
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 5.0,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      color: GSYColors.cardWhite,
                      margin: const EdgeInsets.only(left: 30.0, right: 30.0),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 30.0, top: 40.0, right: 30.0, bottom: 0.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Image(
                                image: AssetImage(GSYICons.DEFAULT_USER_ICON),
                                width: 90.0,
                                height: 90.0),
                            const Padding(padding: EdgeInsets.all(10.0)),
                            // Token 输入框：既支持"Personal Access Token"原文
                            // 粘贴，也兼容用户手抖带上的 "token xxx" / "Bearer xxx"
                            // 前缀（在 UserRepository.loginWithToken 内做清洗）。
                            GSYInputWidget(
                              hintText: context.l10n.token_login_hint,
                              iconData: GSYICons.LOGIN_PW,
                              obscureText: true,
                              onChanged: (String value) {
                                _token = value;
                              },
                              controller: tokenController,
                            ),
                            const Padding(padding: EdgeInsets.all(10.0)),
                            SizedBox(
                              height: 50,
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: GSYFlexButton(
                                      text: context.l10n.token_login_text,
                                      color: Theme.of(context).primaryColor,
                                      textColor: GSYColors.textWhite,
                                      fontSize: 16,
                                      onPress: tokenLogin,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: GSYFlexButton(
                                      text: context.l10n.oauth_text,
                                      color: Theme.of(context).primaryColor,
                                      textColor: GSYColors.textWhite,
                                      fontSize: 16,
                                      onPress: oauthLogin,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(15.0)),
                            InkWell(
                              onTap: () {
                                CommonUtils.showLanguageDialog(ref);
                              },
                              child: Text(
                                context.l10n.switch_language,
                                style: const TextStyle(
                                    color: GSYColors.subTextColor),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(15.0)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ]),
          );
        }),
      ),
    );
  }
}

mixin LoginBLoC on State<LoginPage> {
  final TextEditingController tokenController = TextEditingController();

  String _token = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  /// PAT 登录：把用户手输 token 派发到 [TokenLoginAction]。
  ///
  /// 校验逻辑：
  /// - 前置：输入非空（这里挡一层，避免走一趟 loading dialog 才提示为空）
  /// - 落地：由 [UserRepository.loginWithToken] 做前缀清洗 + `/user` 探活
  /// - 失败：epic 会 dispatch [LoginSuccessAction(false)]，同时 repository
  ///   已回滚不合法的 token，避免留在 LocalStorage 里污染下一次冷启动
  tokenLogin() async {
    final trimmed = _token.trim();
    if (trimmed.isEmpty) {
      showToast(context.l10n.token_login_empty);
      return;
    }
    StoreProvider.of<GSYState>(context)
        .dispatch(TokenLoginAction(context, trimmed));
  }

  oauthLogin() async {
    var st = StoreProvider.of<GSYState>(context);
    String? code = await NavigatorUtils.goLoginWebView(
        context, Address.getOAuthUrl(), context.l10n.oauth_text);

    if (code != null && code.isNotEmpty) {
      ///通过 redux 去执行登陆流程
      // ignore: use_build_context_synchronously
      st.dispatch(OAuthAction(context, code));
    }
  }
}
