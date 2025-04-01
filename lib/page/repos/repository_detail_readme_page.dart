import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/page/repos/provider/repos_detail_provider.dart';
import 'package:gsy_github_app_flutter/widget/markdown/gsy_markdown_widget.dart';
import 'package:provider/provider.dart';

/// Readme
/// Created by guoshuyu
/// Date: 2018-07-18

class RepositoryDetailReadmePage extends StatefulWidget {
  const RepositoryDetailReadmePage({super.key});

  @override
  RepositoryDetailReadmePageState createState() =>
      RepositoryDetailReadmePageState();
}

class RepositoryDetailReadmePageState extends State<RepositoryDetailReadmePage>
    with AutomaticKeepAliveClientMixin {
  RepositoryDetailReadmePageState();

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
        : GSYMarkdownWidget(markdownData: markdownData);

    return widget;
  }
}
