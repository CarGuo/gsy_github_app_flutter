import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';

/// 搜索输入框
/// Created by guoshuyu
/// Date: 2018-07-20
class GSYSearchInputWidget extends StatelessWidget {
  final TextEditingController? controller;

  final ValueChanged<String>? onSubmitted;

  final VoidCallback? onSubmitPressed;

  const GSYSearchInputWidget(
      {super.key, this.controller, this.onSubmitted, this.onSubmitPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(0.0),
              bottomLeft: Radius.circular(0.0)),
          color: GSYColors.white,
          border:
              Border.all(color: Theme.of(context).primaryColor, width: 0.3),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).primaryColorDark, blurRadius: 4.0)
          ]),
      padding:
          const EdgeInsets.only(left: 20.0, top: 12.0, right: 20.0, bottom: 12.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
                autofocus: false,
                controller: controller,
                decoration: InputDecoration(
                  hintText: context.l10n.repos_issue_search,
                  hintStyle: GSYConstant.middleSubText,
                  border: InputBorder.none,
                  isDense: true,
                ),

                ///关闭 3.7 的放大镜
                magnifierConfiguration:
                    TextMagnifierConfiguration(magnifierBuilder: (
                  BuildContext context,
                  MagnifierController controller,
                  ValueNotifier<MagnifierInfo> magnifierInfo,
                ) {
                  return null;
                }),
                style: GSYConstant.middleText
                    .copyWith(textBaseline: TextBaseline.alphabetic),
                onSubmitted: onSubmitted),
          ),
          RawMaterialButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(right: 5.0, left: 10.0),
              constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
              onPressed: onSubmitPressed,
              child: Icon(
                GSYICons.SEARCH,
                size: 15.0,
                color: Theme.of(context).primaryColorDark,
              ))
        ],
      ),
    );
  }
}
