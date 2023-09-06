import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:gsy_github_app_flutter/common/dao/user_dao.dart';
import 'package:gsy_github_app_flutter/redux/gsy_state.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/widget/diff_scale_text.dart';
import 'package:gsy_github_app_flutter/widget/mole_widget.dart';
import 'package:redux/redux.dart';
import 'package:rive/rive.dart';

/**
 * 欢迎页
 * Created by guoshuyu
 * Date: 2018-07-16
 */

class WelcomePage extends StatefulWidget {
  static final String sName = "/";

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool hadInit = false;

  String text = "";
  double fontSize = 76;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (hadInit) {
      return;
    }
    hadInit = true;

    ///防止多次进入
    Store<GSYState> store = StoreProvider.of(context);
    new Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        text = "Welcome";
        fontSize = 60;
      });
    });
    new Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      setState(() {
        text = "GSYGithubApp";
        fontSize = 60;
      });
    });
    new Future.delayed(const Duration(seconds: 3, milliseconds: 500), () {
      UserDao.initUserInfo(store).then((res) {
        if (res != null && res.result) {
          NavigatorUtils.goHome(context);
        } else {
          NavigatorUtils.goLogin(context);
        }
        return true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<GSYState>(
      builder: (context, store) {
        double size = 200;
        return Material(
          child: new Container(
            color: GSYColors.white,
            child: Stack(
              children: <Widget>[
                new Center(
                  child: new Image(
                      image: new AssetImage('static/images/welcome.png')),
                ),
                Align(
                  alignment: Alignment(0.0, 0.3),
                  child: DiffScaleText(
                    text: text,
                    textStyle: GoogleFonts.akronim().copyWith(
                      color: GSYColors.primaryDarkValue,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0.0, 0.8),
                  child: Mole(),
                ),
                new Align(
                  alignment: Alignment(0.0, .9),
                  child: new Container(
                    width: size,
                    height: size,
                    child: RiveAnimation.asset(
                      'static/file/launch.riv',
                      animations: ["lookUp"],
                      onInit: (arb) {
                        var controller =
                            StateMachineController.fromArtboard(arb, "birb");
                        var smi = controller?.findInput<bool>("dance");
                        arb.addController(controller!);
                        smi?.value == true;
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
