# ADR-0003 Markdown 相对路径图片的处理边界

## 状态

已采纳

## 日期

2026-07-04

## 背景

GSY 用 [gsy_markdown_widget.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart) 渲染 issue / PR / comment / review body 里的 markdown。这个 widget 有一个 `baseUrl` 参数，理论上用于把 body 里的相对路径图片（例如 `![](docs/foo.png)`）拼成绝对 URL 再交给 `Image.network`。

现状（在此 ADR 之前）：

- README 场景走 [getRawBaseUrl](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/utils/common_utils.dart#L489-L494)，拼成 `https://raw.githubusercontent.com/USER/REPO/BRANCH/`，行为正确
- issue / PR / comment / review body 走的所有调用点，`baseUrl` 全部硬编码为 `""`

一次 review 中提出"`baseUrl:""` 是理论洞，未来相对路径图片会走 `Image.file` 抛 `FileSystemException`"。作者据此引入 helper `getGithubWebRepoBaseUrl`，把三个 widget 的构造函数加 `repoUserName? / repoName?` 参数，一路从 [IssueDetailPage](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/issue_detail_page.dart) 和 [repository_detail_issue_list_page.dart](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/repos/repository_detail_issue_list_page.dart) 串下去，拼出 `https://github.com/USER/REPO/`。

独立 reviewer 复审时顺着 `_processMarkdownImages` → `kDefaultImageBuilder` 走了一遍真实数据流：

1. `baseUrl:""` 场景下，相对路径最终会命中 [kDefaultImageBuilder](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L281) 里的 `if (uri.scheme.isEmpty) return const SizedBox();`，**不会**走到 `Image.file`。行为是"静默显示为空白"，不是"抛异常崩溃"。
2. `https://github.com/USER/REPO/foo.png` 这种 URL，GitHub Web **不会**返回 302 到 CDN，也不会返回图片内容。它会返回一个 HTML 页面，`Image.network` 拿到 HTML 会解析失败白屏。这比 `baseUrl:""` 走 SizedBox 视觉上**更糟**。
3. `raw.githubusercontent.com/USER/REPO/BRANCH/foo.png` 才是符合 GitHub CDN 语义的 base，但 issue / PR body 的上下文里**没有 branch 信息**（不像 README 有 default_branch），无法可靠拼出。硬编码 `main` / `master` 都会对相当一部分老仓库或非默认分支的相对引用错位。
4. 采样 flutter / react-native / vscode / CarGuo 四个仓库 × 100 条评论和 PR body，**零命中**相对路径图片——GitHub Web 保存 body 时会自动把粘贴的图片替换成 `user-attachments/...` 或直接绝对 URL，所以真实数据里几乎不存在需要 `baseUrl` 参与解析的相对路径。

引入 helper 反而把一个"不会崩、几乎不触发"的路径改成一个"命中就白屏"的路径，是**用错的方案修一个不存在的问题**。回滚。

## 决策

从现在开始约束 markdown 相对路径图片的处理边界：

1. **issue / PR / comment / review body 场景，`GSYMarkdownWidget.baseUrl` 一律传 `""`**。
   - 相对路径图片在 GitHub Web 侧几乎不会出现，真出现时下游会走 `SizedBox` 静默失败，不会崩溃。
   - 不要为这个场景引入串仓库参数的 helper。既有 `baseUrl:""` 是**故意为之**的行为，不是待修复的 TODO。

2. **README / 源码文件预览场景，继续用 [getRawBaseUrl](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/common/utils/common_utils.dart#L489-L494)**。它拼出的 `raw.githubusercontent.com/USER/REPO/BRANCH/` 是 GitHub CDN 真正支持的路径。这一场景本来就有 branch 信息，helper 契约完整。

3. **不引入 "GitHub Web 仓库根 URL" 类型的 helper**（例如 `github.com/USER/REPO/`）。这种 URL 不是 CDN 入口，`Image.network` 无法从它加载图片。

4. 若未来出现真实用户反馈"某评论里的图片显示不出来"，先抓具体的 body 内容做 fixture、写单测、再做修复。不要基于"理论洞"引入防御代码。

## 后果

好处：

- 避免"看到 `baseUrl:""` 就想串参数"这类基于经验主义的错误修复循环
- 保持三个 widget（[IssueItem](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_item.dart)、[IssueHeaderItem](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_header_item.dart)、[IssueTimelineItem](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/page/issue/widget/issue_timeline_item.dart)）构造函数入参精简，不带用不到的"仓库标识"污染
- 明确 "静默 SizedBox" 是**当前的既定行为契约**，reviewer 和后续 agent 有据可依

代价：

- 极少数手打相对路径图片的评论（如 `![](docs/foo.png)`）会显示为空白。用户看不到内容也不知道原因。若这种反馈真的出现，按第 4 条走 fixture-first 流程。

## 与本决策相关的教训

- **理论洞 vs 真实数据**：修复前先采样真实数据。GitHub 客户端场景下 body 的图片形态由 GitHub Web 侧决定，不是我们能自由假设的。
- **helper 命名 vs 契约**：`getFooBaseUrl` 这种名字很容易让人以为"齐全时就能用"。实际契约取决于**下游消费方**（这里是 Image.network）而不是 helper 自己。命名必须能反映"这个 URL 真的能被目标消费方消费"。
- **`baseUrl:""` 的实质语义不是 TODO**：它是"放弃解析相对路径 → 下游走 SizedBox"，这是一条有意的行为路径，不是 bug。改动前必须先读 [_processMarkdownImages](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L142) 和 [kDefaultImageBuilder](file:///Users/guoshuyu/workspace/flutter-work/gsy_github_app_flutter/lib/widget/markdown/gsy_markdown_widget.dart#L281) 全数据流。
