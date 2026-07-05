import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/model/code_search_item.dart';
import 'package:gsy_github_app_flutter/widget/gsy_card_item.dart';

/// GitHub 代码搜索单条命中的展示。
///
/// 显示三行：
///  - 顶部：文件名（加粗）
///  - 中间：相对仓库根的完整路径（小字灰色）
///  - 底部：所属仓库全名（小字带 icon）
///
/// 点击回调由外部提供，一般是打开 [CodeSearchItem.htmlUrl] 的 WebView。
/// 之所以不做代码片段预览：GitHub `/search/code` 需要额外的
/// `Accept: application/vnd.github.v3.text-match+json` header 才返回
/// `text_matches`，为了保守稳定，先只展示文件层信息。
class CodeSearchItemWidget extends StatelessWidget {
  final CodeSearchItem item;
  final GestureTapCallback? onPressed;

  const CodeSearchItemWidget(this.item, {super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GSYCardItem(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 18.0, color: GSYColors.subTextColor),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      item.name.isEmpty ? '(unnamed)' : item.name,
                      style: GSYConstant.normalTextBold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                item.path,
                style: GSYConstant.smallSubText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 14.0, color: GSYColors.subTextColor),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      item.repositoryFullName,
                      style: GSYConstant.smallSubText,
                      overflow: TextOverflow.ellipsis,
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
