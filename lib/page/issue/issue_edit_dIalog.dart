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

  /// Optional caller-owned controllers. The caller must keep them alive until
  /// the dialog subtree is unmounted; this form never disposes supplied ones.
  /// Omit them for form-owned editing state.
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

  // 2026-10 FPR-117: route.popped can finish before its reverse transition.
  // Own temporary controllers with the form State, not a caller's pop Future.
  TextEditingController? _ownedTitleController;
  TextEditingController? _ownedValueController;

  TextEditingController get _titleController =>
      widget.titleController ??
      (_ownedTitleController ??= TextEditingController());
  TextEditingController get _valueController =>
      widget.valueController ??
      (_ownedValueController ??= TextEditingController());

  @override
  void dispose() {
    _ownedTitleController?.dispose();
    _ownedValueController?.dispose();
    super.dispose();
  }

  ///标题输入框
  renderTitleInput() {
    return (widget.needTitle)
        ? Padding(
            padding: const EdgeInsets.all(5.0),
            child: GSYInputWidget(
              onChanged: widget.onTitleChanged,
              controller: _titleController,
              hintText: context.l10n.issue_edit_issue_title_tip,
              obscureText: false,
            ),
          )
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
              left: 8.0,
              right: 8.0,
              top: 5.0,
              bottom: 5.0,
            ),
            constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
            child: Icon(FAST_INPUT_LIST[index].iconData, size: 16.0),
            onPressed: () {
              final newText =
                  _valueController.text + FAST_INPUT_LIST[index].content;
              _valueController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
              widget.onContentChanged.call(newText);
            },
          );
        },
        itemCount: FAST_INPUT_LIST.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).shortestSide
        .clamp(280.0, 520.0);
    // 2026-10 FPR-117: showDialog routes do not apply Dialog's IME insets to a
    // bare Card. Dialog handles viewInsets; the scroll view below is bounded by
    // the actual remaining pane constraints, including a short keyboard viewport.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight = (constraints.maxHeight * 0.35).clamp(
              180.0,
              360.0,
            );
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: GSYCardItem(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ///dialog标题
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                            bottom: 15.0,
                          ),
                          child: Center(
                            child: Text(
                              widget.dialogTitle,
                              style: GSYConstant.normalTextBold,
                            ),
                          ),
                        ),

                        ///标题输入框
                        renderTitleInput(),

                        ///内容输入框：保持可读的编辑区域，短视口由表单整体滚动。
                        Container(
                          height: contentHeight,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4.0),
                            ),
                            color: GSYColors.white,
                            border: Border.all(
                              color: GSYColors.subTextColor,
                              width: .3,
                            ),
                          ),
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            top: 12.0,
                            right: 20.0,
                            bottom: 12.0,
                          ),
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  autofocus: false,
                                  maxLines: 999,
                                  onChanged: widget.onContentChanged,
                                  controller: _valueController,
                                  decoration: InputDecoration(
                                    hintText:
                                        widget.hintText ??
                                        context.l10n.issue_edit_issue_title_tip,
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
                                  minWidth: 0.0,
                                  minHeight: 0.0,
                                ),
                                child: Text(
                                  context.l10n.app_cancel,
                                  style: GSYConstant.normalSubText,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Container(
                              width: 0.3,
                              height: 25.0,
                              color: GSYColors.subTextColor,
                            ),

                            ///确定
                            Expanded(
                              child: RawMaterialButton(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.all(4.0),
                                constraints: const BoxConstraints(
                                  minWidth: 0.0,
                                  minHeight: 0.0,
                                ),
                                onPressed: widget.onPressed,
                                child: Text(
                                  context.l10n.app_ok,
                                  style: GSYConstant.normalTextBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
