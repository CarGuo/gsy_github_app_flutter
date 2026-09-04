import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 仓库详情各 tab 页面接入 [GSYAdaptiveNavigation.instance.wrapListChild]
/// 的**源码级契约锁**。
///
/// 意图（P0-2 / P0-3 / P1-4 分级说明，ADR-0005 §"消费方约束"）：
/// - File tab 与 Readme tab 都直连 [ListView.builder] / [GSYMarkdownWidget]，
///   不走 GSYPullLoadWidget / GSYNestedPullLoadWidget 那条共享收口，因此必须
///   在页面 build 里显式调用 wrapListChild，才能在 medium / expanded 断点获得
///   与列表卡片一致的 720dp 中央条视觉。
/// - Discussion tab 通过 [GSYPullLoadWidget] 走共享通路，wrapListChild 已在
///   `_getItem` 出口套上；本文件锁"Discussion 必须使用 GSYPullLoadWidget"，
///   与 [gsy_pull_load_widget_test.dart] 的 widget 级契约联合形成完整保护。
/// - Widget test 侧要真跑 File / Readme 需要 stub EasyRefresh + Provider + 网络栈，
///   投入产出不划算；而这里的关键不变量是"页面确实调了 wrapListChild"，
///   静态源码扫描已足够锁死"未来重构静默拆掉包装"这条主要漂移风险。
/// - Widget 级视觉断言（"item 外层出现 maxWidth==cardMaxWidth 约束"）已由
///   [gsy_adaptive_shell_test.dart] + [gsy_nested_pull_load_widget_test.dart]
///   + [gsy_pull_load_widget_test.dart] 三份契约共同覆盖，本文件补齐
///   "是否接入 / 走的是共享通路"这一层。
///
/// 若未来有人把 wrapListChild 从这三个 tab 里拆掉、或把 Discussion 从
/// GSYPullLoadWidget 切成裸 ListView.builder、或者换成别的写法，
/// 本 test 会 fail，逼迫改动方显式说明理由并同步 ADR-0005 消费口径白名单。
///
/// 路径解析：flutter test 的默认 [Directory.current] 是 package root，但
/// dart 侧启动方式偶尔会漂移（比如某些 IDE runner），为了稳妥这里从当前
/// 工作目录反推 package root，命中 `pubspec.yaml` 时视为根目录。
void main() {
  final packageRoot = _resolvePackageRoot();

  group('仓库详情 tab wrapListChild 源码级契约锁（P0-2 / P0-3 / P1-4）', () {
    test(
        'RepositoryFileListPage 必须调用 GSYAdaptiveNavigation.instance.wrapListChild',
        () {
      final file = File(
              '${packageRoot.path}/lib/page/repos/repository_file_list_page.dart')
          .readAsStringSync();
      // 精确锁"实际调用点"，不误伤注释：注释里可能出现 wrapListChild 字样，
      // 因此用 `.wrapListChild(` 这种带 `(` 的形式命中真正的方法调用。
      expect(
        file.contains('.wrapListChild('),
        isTrue,
        reason: 'P0-2 契约：File tab 直连 ListView.builder，必须在 itemBuilder 出口 '
            '接入 wrapListChild，否则 medium / expanded 断点上文件行会拉满宽度。',
      );
      expect(
        file.contains(
            "import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart'"),
        isTrue,
        reason: 'wrapListChild 依赖 gsy_adaptive_shell.dart，import 缺失即会编译失败，'
            '本断言让契约漂移信号更靠前。',
      );
    });

    test(
        'RepositoryDetailReadmePage 必须调用 GSYAdaptiveNavigation.instance.wrapListChild',
        () {
      final file = File(
              '${packageRoot.path}/lib/page/repos/repository_detail_readme_page.dart')
          .readAsStringSync();
      expect(
        file.contains('.wrapListChild('),
        isTrue,
        reason: 'P0-3 契约：Readme tab 主体是纯 Markdown，medium / expanded 上必须走 '
            'wrapListChild 收 720dp 中央条，否则代码块与 heading 阅读体验退化。',
      );
      expect(
        file.contains(
            "import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart'"),
        isTrue,
      );
    });

    test(
        'DiscussionListPage 必须走 GSYPullLoadWidget 共享通路（wrapListChild 自动继承）',
        () {
      final file = File(
              '${packageRoot.path}/lib/page/discussion/discussion_list_page.dart')
          .readAsStringSync();
      // P1-4 契约：Discussion tab 是 repository detail 里唯一走 GraphQL 的 tab，
      // 但列表渲染仍必须复用 GSYPullLoadWidget，一是与其它列表 tab 视觉一致，
      // 二是 wrapListChild 已经在 GSYPullLoadWidget._getItem 里套好（由
      // gsy_pull_load_widget_test.dart 契约锁保护），Discussion 自动继承。
      //
      // 反面 case：若有人把这里改成裸 ListView.builder 或自建 pull-refresh，
      // wrapListChild 就断链，medium / expanded 上 Discussion 卡片会拉满宽度。
      expect(
        file.contains('GSYPullLoadWidget('),
        isTrue,
        reason: 'P1-4 契约：Discussion tab 必须使用 GSYPullLoadWidget，自动继承 '
            'wrapListChild。不允许切成裸 ListView.builder / 自建刷新组件。',
      );
      expect(
        file.contains(
            "import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_load_widget.dart'"),
        isTrue,
        reason: 'GSYPullLoadWidget 依赖 gsy_pull_load_widget.dart，import 缺失即会编译失败。',
      );
    });
  });
}

/// 从测试运行时向上寻找 `pubspec.yaml` 所在目录，作为 package root。
/// flutter test 默认 [Directory.current] 就是 package root，但用向上遍历
/// 再兜一层更稳，避免 IDE runner cwd 漂移。
Directory _resolvePackageRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}
