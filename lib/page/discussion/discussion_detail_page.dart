import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/net/graphql/client.dart' as gql;
import 'package:gsy_github_app_flutter/common/style/gsy_style.dart';
import 'package:gsy_github_app_flutter/widget/gsy_title_bar.dart';

/// GitHub Discussions 阅读页（骨架）
///
/// 对齐 roadmap §3.1 第一项："Discussion 事件已经识别，动态流里能看到
/// '在 xxx 创建 讨论'，但点进去没页面"。
///
/// **当前阶段（骨架）**：
/// - 顶部标题 + 返回
/// - 拉一次 GraphQL [gql.getDiscussion]，成功后展示 title/author/bodyHTML 摘要
/// - 失败或未登录时展示 fallback 文案，不崩、不阻塞
///
/// **尚未做的下一阶段**（在 roadmap §3.1 anchor 里跟踪）：
/// - bodyHTML → 用 GSYMarkdownWidget 或 flutter_html 完整渲染
/// - comments/replies 展开、分页加载
/// - answer 徽标、reactions bar、投票交互
/// - 复用 [issue_timeline_item.dart](file:///d:/workspace/project/gsy_github_app_flutter/lib/page/issue/widget/issue_timeline_item.dart) 的事件行骨架
///   把 category_changed / answered 等 discussion 事件穿插进正文流
class DiscussionDetailPage extends StatefulWidget {
  final String owner;
  final String reposName;
  final int number;
  final bool needHomeIcon;

  const DiscussionDetailPage(
    this.owner,
    this.reposName,
    this.number, {
    super.key,
    this.needHomeIcon = false,
  });

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  bool _loading = true;
  String? _errorText;
  Map<String, dynamic>? _discussion;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final QueryResult? res =
          await gql.getDiscussion(widget.owner, widget.reposName, widget.number);
      if (!mounted) return;
      if (res == null || res.hasException) {
        setState(() {
          _loading = false;
          _errorText = res?.exception?.toString() ?? 'null result';
        });
        return;
      }
      final Map<String, dynamic>? repo =
          res.data?['repository'] as Map<String, dynamic>?;
      final Map<String, dynamic>? disc =
          repo?['discussion'] as Map<String, dynamic>?;
      setState(() {
        _loading = false;
        _discussion = disc;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            Text(context.l10n.loading_text),
          ],
        ),
      );
    }
    if (_errorText != null) {
      return _buildFallback(context.l10n.discussion_load_failed, _errorText);
    }
    if (_discussion == null) {
      return _buildFallback(context.l10n.discussion_not_found, null);
    }
    return _buildContent(_discussion!);
  }

  Widget _buildFallback(String main, String? detail) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              main,
              style: GSYConstant.middleTextBold,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: GSYConstant.smallText,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              child: Text(context.l10n.discussion_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> disc) {
    final String title = (disc['title'] as String?) ?? '';
    final Map<String, dynamic>? author =
        disc['author'] as Map<String, dynamic>?;
    final String? authorLogin = author?['login'] as String?;
    final Map<String, dynamic>? category =
        disc['category'] as Map<String, dynamic>?;
    final String? categoryName = category?['name'] as String?;
    final String? categoryEmoji = category?['emoji'] as String?;
    final int upvote = (disc['upvoteCount'] as int?) ?? 0;
    final bool answered = disc['answerChosenAt'] != null;
    final int commentCount =
        ((disc['comments'] as Map<String, dynamic>?)?['totalCount'] as int?) ??
            0;
    final String? bodyHTML = disc['bodyHTML'] as String?;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('#${widget.number}  $title', style: GSYConstant.largeTextBold),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (authorLogin != null)
                Chip(label: Text('@$authorLogin')),
              if (categoryName != null)
                Chip(label: Text('${categoryEmoji ?? ''} $categoryName')),
              if (answered)
                Chip(
                  label: Text(context.l10n.discussion_answered_badge),
                  backgroundColor: Colors.green.shade100,
                ),
              Chip(label: Text('▲ $upvote')),
              Chip(
                label: Text(
                  context.l10n.discussion_comments_count(commentCount),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (bodyHTML == null || bodyHTML.isEmpty)
            Text(
              context.l10n.discussion_empty_body,
              style: GSYConstant.smallText,
            )
          else
            Text(
              bodyHTML,
              style: GSYConstant.middleText,
            ),
          const SizedBox(height: 24),
          Text(
            context.l10n.discussion_skeleton_notice,
            style: GSYConstant.smallSubText,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GSYTitleBar(
          '${widget.reposName} · #${widget.number}',
          iconData: GSYICons.HOME,
          needRightLocalIcon: widget.needHomeIcon,
        ),
      ),
      body: _buildBody(),
    );
  }
}
