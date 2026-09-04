import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/common/utils/common_utils.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_detail_provider.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:provider/provider.dart';

/// Readme
/// Created by guoshuyu
/// Date: 2018-07-18

class RepositoryDetailReadmePage extends StatefulWidget {
  const new({super.key});

  @override
  RepositoryDetailReadmePageState createState() =>
      RepositoryDetailReadmePageState();
}

class RepositoryDetailReadmePageState extends State<RepositoryDetailReadmePage>
    with AutomaticKeepAliveClientMixin {
  new();

  Future? request;

  refreshReadme() {
    context.read<ReposDetailProvider>().refreshReadme();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    refreshReadme();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ///展示 select
    var markdownData =
        context.select<ReposDetailProvider, String?>((p) => p.markdownData);
    var rp = context.read<ReposDetailProvider>();
    var widget = (markdownData == null)
        ? Center(
            child: Container(
              width: 200.0,
              height: 200.0,
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SpinKitDoubleBounce(color: Theme.of(context).primaryColor),
                  Container(width: 10.0),
                  Text(context.l10n.loading_text,
                      style: GSYConstant.middleText),
                ],
              ),
            ),
          )
        : GSYMarkdownWidget(
            markdownData: markdownData,
            baseUrl: getRawBaseUrl(
                repoName: rp.reposName,
                userName: rp.userName,
                branch: rp.currentBranch));

    /// P0-3（ADR-0005 §"演进/wrapListChild"）：Readme 主体是纯 Markdown，
    /// 未经限宽在 medium / expanded 上会一路拉到 1200dp+，让 heading 与代码块
    /// 阅读极其吃力。这里对整块内容（含 loading Center 与 Markdown 主体）套一次
    /// wrapListChild：compact 断点原样返回，medium / expanded 才做 720dp
    /// 居中限宽。loading Center 已经自带水平居中，wrapListChild 只是给它加了个
    /// 最大宽度上限，视觉自然。ADR-0005 §"消费方约束"里对本页作为直连消费点
    /// 做了显式豁免登记。
    return GSYAdaptiveNavigation.instance
        .wrapListChild(context: context, child: widget);
  }
}
