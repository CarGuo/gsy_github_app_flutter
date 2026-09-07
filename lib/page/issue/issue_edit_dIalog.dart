import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_input_widget.dart';

/// issue 编辑输入框
/// Created by guoshuyu
/// on 2018/7/21.
class IssueEditDialog extends StatefulWidget {
  final String dialogTitle;

  final ValueChanged<String>? onTitleChanged;

  final ValueChanged<String> onContentChanged;

  final VoidCallback onPressed;

  final TextEditingController? titleController;

  final TextEditingController? valueController;

  final bool needTitle;
  final String? hintText;

  const new(
    this.dialogTitle,
    this.onTitleChanged,
    this.onContentChanged,
    this.onPressed, {
    super.key,
    this.titleController,
    this.valueController,
    this.needTitle = true,
    this.hintText,
  });

  @override
  _IssueEditDialogState createState() => _IssueEditDialogState();
}

class _IssueEditDialogState extends State<IssueEditDialog> {
  new();

  ///标题输入框
  renderTitleInput() {
    return (widget.needTitle)
        ? Padding(
            padding: const EdgeInsets.all(5.0),
            child: GSYInputWidget(
              onChanged: widget.onTitleChanged,
              controller: widget.titleController,
              hintText: context.l10n.issue_edit_issue_title_tip,
              obscureText: false,
            ))
        : Container();
  }

  ///快速输入框
  _renderFastInputContainer() {
    ///因为是Column下包含了ListView，所以需要设置高度
    return SizedBox(
      height: 30.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return RawMaterialButton(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(
                  left: 8.0, right: 8.0, top: 5.0, bottom: 5.0),
              constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
              child: Icon(FAST_INPUT_LIST[index].iconData, size: 16.0),
              onPressed: () {
                String text = FAST_INPUT_LIST[index].content;
                String newText = "";
                if (widget.valueController?.value != null) {
                  newText = widget.valueController!.value.text;
                }
                newText = newText + text;
                setState(() {
                  widget.valueController!.value =
                      TextEditingValue(text: newText);
                });
                widget.onContentChanged.call(newText);
              });
        },
        itemCount: FAST_INPUT_LIST.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // P2 §2 dialog 分档修正（2026-09-07）：
    // 历史实现里外层是 Scaffold + 整屏 Container(barrier + writeSize)，把自己当"整屏
    // hero 页"来渲染；配合原来的 `showGSYDialog(useRootNavigator: true, opaque:true)`
    // 场景下才不出问题。改走 `showAdaptiveGSYDialog` → `showDialog(useRootNavigator:
    // !expanded)` 之后，Flutter 自身已经负责 barrier + 尺寸约束（expanded 分档下
    // dialog barrier 只覆盖 caller 所在的 Navigator subtree，即右列 detail pane），
    // 再叠一层"整屏 Container + MediaQuery.sizeOf.width * 3/4"就会把 detail pane
    // 撑爆 —— 真机截图 dialog_step3_edit_dialog.png 直接命中
    // `RenderFlex overflowed by 92 pixels on the bottom`。
    //
    // 修正：不做整屏 barrier / 不写死屏幕尺寸；返回一个可被 dialog 排版的
    // ConstrainedBox + GSYCardItem，交给 showDialog 决定摆哪、多大。
    final media = MediaQuery.of(context);
    // dialog 最大宽度：手机竖屏尽量接近整屏，pad / expanded 分档限一个合理上限，
    // 避免在 2K 折叠屏上撑成横条。
    final maxWidth = media.size.shortestSide.clamp(280.0, 520.0);
    // 内容输入区高度：跟屏幕高度联动，避免 iPad/expanded 分档下体感缩水
    // （原逻辑 `MediaQuery.sizeOf.width * 3/4` 在整屏 barrier 场景是合理的，
    // 但迁移到 detail pane 后会把 pane 撑爆；这里改成 `height * 0.35` 再 clamp
    // 到 [180, 360]，phone 竖屏≈300、pad 竖屏≈360、compact 短屏≈180，与
    // 旧观感基本对齐且不再溢出 pane）。reviewer F3 强要求 2026-09-07。
    final contentHeight = (media.size.height * 0.35).clamp(180.0, 360.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GSYCardItem(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ///dialog标题
                Padding(
                    padding:
                        const EdgeInsets.only(top: 5.0, bottom: 15.0),
                    child: Center(
                      child: Text(widget.dialogTitle,
                          style: GSYConstant.normalTextBold),
                    )),

                ///标题输入框
                renderTitleInput(),

                ///内容输入框（高度跟屏幕联动，见 build 顶部 contentHeight 注释）
                Container(
                  height: contentHeight,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(4.0)),
                    color: GSYColors.white,
                    border: Border.all(
                        color: GSYColors.subTextColor, width: .3),
                  ),
                  padding: const EdgeInsets.only(
                      left: 20.0,
                      top: 12.0,
                      right: 20.0,
                      bottom: 12.0),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          autofocus: false,
                          maxLines: 999,
                          onChanged: widget.onContentChanged,
                          controller: widget.valueController,
                          decoration: InputDecoration(
                            hintText: widget.hintText ??
                                context
                                    .l10n.issue_edit_issue_title_tip,
                            hintStyle: GSYConstant.middleSubText,
                            isDense: true,
                            border: InputBorder.none,
                          ),
                          style: GSYConstant.middleText,
                        ),
                      ),

                      ///快速输入框
                      _renderFastInputContainer(),
                    ],
                  ),
                ),
                Container(height: 10.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ///取消
                    Expanded(
                        child: RawMaterialButton(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(4.0),
                            constraints: const BoxConstraints(
                                minWidth: 0.0, minHeight: 0.0),
                            child: Text(context.l10n.app_cancel,
                                style: GSYConstant.normalSubText),
                            onPressed: () {
                              Navigator.pop(context);
                            })),
                    Container(
                        width: 0.3,
                        height: 25.0,
                        color: GSYColors.subTextColor),

                    ///确定
                    Expanded(
                        child: RawMaterialButton(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(4.0),
                            constraints: const BoxConstraints(
                                minWidth: 0.0, minHeight: 0.0),
                            onPressed: widget.onPressed,
                            child: Text(context.l10n.app_ok,
                                style: GSYConstant.normalTextBold))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

var FAST_INPUT_LIST = [
  FastInputIconModel(GSYICons.ISSUE_EDIT_H1, "\n# "),
  FastInputIconModel(GSYICons.ISSUE_EDIT_H2, "\n## "),
  FastInputIconModel(GSYICons.ISSUE_EDIT_H3, "\n### "),
  FastInputIconModel(GSYICons.ISSUE_EDIT_BOLD, "****"),
  FastInputIconModel(GSYICons.ISSUE_EDIT_ITALIC, "__"),
  FastInputIconModel(GSYICons.ISSUE_EDIT_QUOTE, "` `"),
  FastInputIconModel(GSYICons.ISSUE_EDIT_CODE, " \n``` \n\n``` \n"),
  FastInputIconModel(GSYICons.ISSUE_EDIT_LINK, "[](url)"),
];

class FastInputIconModel {
  final IconData iconData;
  final String content;

  new(this.iconData, this.content);
}
