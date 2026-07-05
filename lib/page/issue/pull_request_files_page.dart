import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/repositories/issue_repository.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/html_utils.dart';
import 'package:gsy_github_app_flutter/common/utils/navigator_utils.dart';
import 'package:gsy_github_app_flutter/model/commitFile.dart';
import 'package:gsy_github_app_flutter/page/push/widget/push_coed_item.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/state/gsy_list_state.dart';

/// PR 变更文件页
///
/// 复用 push detail 里已经跑成熟的 [PushCodeItem]，因为 GitHub
/// `/repos/:o/:r/pulls/:n/files` 与 commit files payload 是同一个 schema
/// （filename/status/additions/deletions/patch/blob_url），
/// 我们把响应体映射成 [CommitFile]，再交给 [PushCodeItem] 渲染 patch，
/// 点击后走 `HtmlUtils.parseDiffSource` + `NavigatorUtils.gotoCodeDetailPlatform`
/// 打开 web view 高亮 diff。
class PullRequestFilesPage extends StatefulWidget {
  final String userName;
  final String reposName;
  final int number;

  const PullRequestFilesPage(this.userName, this.reposName, this.number,
      {super.key});

  @override
  State<PullRequestFilesPage> createState() => _PullRequestFilesPageState();
}

class _PullRequestFilesPageState extends State<PullRequestFilesPage>
    with
        AutomaticKeepAliveClientMixin<PullRequestFilesPage>,
        GSYListState<PullRequestFilesPage> {
  @override
  requestRefresh() async {
    return await IssueRepository.getPullRequestFilesRequest(
        widget.userName, widget.reposName, widget.number,
        page: 1);
  }

  @override
  requestLoadMore() async {
    return await IssueRepository.getPullRequestFilesRequest(
        widget.userName, widget.reposName, widget.number,
        page: page);
  }

  @override
  bool get isRefreshFirst => true;

  @override
  bool get needHeader => false;

  Widget _renderItem(BuildContext context, int index) {
    final CommitFile file = pullLoadWidgetControl.dataList[index] as CommitFile;
    final vm = PushCodeItemViewModel.fromMap(file);
    return PushCodeItem(vm, () {
      final html = HtmlUtils.generateCode2HTml(
          HtmlUtils.parseDiffSource(vm.patch, false),
          backgroundColor: GSYColors.webDraculaBackgroundColorString,
          lang: '',
          userBR: false);
      NavigatorUtils.gotoCodeDetailPlatform(
        context,
        title: vm.name,
        reposName: widget.reposName,
        userName: widget.userName,
        path: vm.patch,
        data: html,
        branch: '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pr_files_title(widget.number)),
      ),
      body: GSYPullLoadWidget(
        pullLoadWidgetControl,
        _renderItem,
        handleRefresh,
        onLoadMore,
        refreshKey: refreshIndicatorKey,
      ),
    );
  }
}
