# ADR-0004 Markdown 内嵌 HTML 前置转换策略

- 状态：已采纳
- 日期：2026-07-04
- 相关：ADR-0003 Markdown 相对路径图片处理边界

## 背景

GitHub issue / PR / comment body 是一种「Markdown + 白名单 HTML」的混合格式。
GitHub GFM 规范（https://github.github.com/gfm/#raw-html）明确列出了允许的
HTML 标签白名单（`<a>` `<img>` `<details>` `<summary>` `<kbd>` `<sub>` `<sup>`
`<code>` `<b>` `<i>` 等约 40 个），官方 Web/App 会把这些标签正常渲染成对应的
富文本元素。

项目一直使用 [`flutter_markdown_plus`](https://pub.dev/packages/flutter_markdown_plus)
（当前 1.0.6）作为渲染器，它默认已经启用 GFM 扩展（删除线 / 任务列表 / 表格 /
自动链接可直接工作），**但明确不支持内联 HTML**。README 原文：

> "It supports the original format, but no inline HTML."

底层 `package:markdown` 解析器把 raw HTML 当作 **文本节点** 输出，
`MarkdownBuilder` 按纯文本原样吐到页面，结果就是用户看到：

```
<a href="/CarGuo/xxx/new/master?filename=..." class="Link--inTextBlock" 
   target="_blank" rel="noopener noreferrer">Add Copilot custom instructions</a>
```

一整段裸标签字面文本，完全丢失可读性与可点击链接。

真机截图 `/tmp/gsy_smoke_11_final.png` 是 Copilot 在 PR #938 提交的 review body
出现此问题的证据。

## 候选方案

调研 pub 生态与自身项目边界，得到三条候选路径：

**P1 前置文本预处理**
- 用 `package:html` 把 HTML 段解析成 DOM，深度优先遍历翻译成 Markdown 等价语法
- 输出的字符串继续走既有 `GSYMarkdownWidget` 管线
- 影响面：只改一个文件（新增 `markdown_html_transformer.dart`），依赖只加一个官方
  `html: 0.15.5`
- 保真度：可读性 100%，链接可点击 100%；细节（如 `<img width>` 尺寸、`<details>`
  的折叠交互）会退化为可读的展开版本，但不影响信息传达

**P2 换渲染包（如 `markdown_widget` + `html_support.dart` 扩展）**
- 需要重写 `MarkdownStyleSheet` → `MarkdownConfig` 体系
- `onTapLink` 签名从 `(text, href, title)` 改为 `(url)`
- 影响面覆盖 README/issue/comment/notification 所有 markdown 渲染入口
- 该包**也不默认支持内联 HTML**，仍要接入官方 `html_support.dart` 扩展写自定义
  `SpanNode`/`InlineSyntax`，工作量与 P1 相近但影响面大得多

**P3 服务端 rendered HTML + `flutter_html`**
- 改网络层加 `Accept: application/vnd.github.html+json` 头，body 字段全改用 body_html
- 前端用 `flutter_html` 渲染
- 保真度最高（emoji / @mention / reference 链接完全对齐 GitHub Web）
- 影响面：`common/net` + `common/repositories` + 所有 body 字段的模型 —— 属于 AGENTS.md
  标记的**高风险目录**，代价极大

## 决策

**采用 P1 前置文本预处理**。

具体实现在
[markdown_html_transformer.dart](../../lib/widget/markdown/markdown_html_transformer.dart)：

1. 引入官方依赖 `html: 0.15.5`（Dart 官方维护、纯 Dart 零 native、非常轻）
2. 提供 `transformInlineHtmlToMarkdown(String input)` 一入一出的纯函数
3. 覆盖 GitHub GFM 白名单约 40 种标签，每类给出 Markdown 等价语法：
    - `<a href>` → `[text](href)`
    - `<img src alt>` → `![alt](src)`
    - `<b>` `<strong>` → `**x**`；`<i>` `<em>` → `*x*`；`<s>` `<strike>` `<del>` → `~~x~~`
    - `<code>` `<kbd>` `<tt>` `<samp>` `<var>` → `` `x` ``；`<pre>` → 三反引号代码块
    - `<sub>` `<sup>` → **纯文本**（GFM 未定义 `~x~` 上下标语法，与删除线 `~~x~~` 会冲突；退回纯文本保可读性）
    - `<h1>-<h6>` → `# ~ ######`；`<hr>` → `---`；`<br>` → 两空格换行
    - `<blockquote>` → `> x`（支持多级嵌套，**单层加 `> ` 前缀，总复杂度 O(N) 而非 O(D·N)**）
    - `<ul>` `<ol>` `<li>` → Markdown 列表（支持嵌套，`<ol start="5">` 支持起始序号）
    - `<details><summary>...</summary>body</details>` → `**summary**` + 空行 + body（不做折叠交互）
    - `<table><thead><tbody><tr><th><td>` → GFM 表格
    - `<dl><dt><dd>` → `**term**\n: definition`
    - `<div>` `<span>` `<small>` `<q>` 视为透传容器，只吐子节点
    - 白名单外或未知标签：**退回 textContent**，绝不让 `<xxx>` 字面泄漏
4. 在 `GSYMarkdownWidget.build` 里，把 `markdownData` 先过一遍
   `transformInlineHtmlToMarkdown` 再喂给 `_processMarkdownImages`
5. 解析失败静默降级：捕获异常并返回原字符串，绝不阻断渲染

## 安全与边界（reviewer 独立复审后加固）

一次独立 reviewer subagent 复审发现 8 类核心问题，全部一次性修完并沉淀到单测。
这些"输出正确的 Markdown"细节，看似小、实则决定线上不出事：

1. **URL spoofing 防御**：`<a href="a)fake">y</a>` 直接翻译成 `[y](a)fake)` 会被
   markdown 解析成 URL=a、后面 `fake)` 变正文，作者可借此把 URL 后缀伪装成正文
   欺骗用户。修复：URL 含 `[\s<>()]` 时用 GFM 尖括号语法 `<url>` 包裹；
   内部再把 `<>` 本身 URL 编码成 `%3C` `%3E`
2. **链接文本/img alt 转义**：文本含 `]` `[` `\` 会破坏 `[label](url)` 语法。
   按 CommonMark 反斜杠转义规则一次处理
3. **行内代码定界动态化**：内容含 n 个连续反引号时，用 n+1 个反引号做定界
   （CommonMark §6.1）；首尾是反引号时再补空白 padding 防边界吞噬
4. **代码块 fence 动态化**：`<pre>` 内含 ```` ``` ```` 时，fence 至少加长到 4
   反引号，避免被内容里的三反引号提前闭合
5. **表格 cell 转义**：`<td>` 内含 `|` 必须转义为 `\|`；含 `\n` 必须替换为空格，
   因为 GFM 表格不允许多行 cell
6. **递归深度上限 200 层**：`<div><div>...</div></div>` 恶意深嵌套会栈爆，
   `_RenderCtx.recursion` 计数超上限直接退回 textContent
7. **blockquote O(N) 遍历**：早期实现每层都对内层重复加 `> ` 前缀，D 层嵌套时
   复杂度 O(D·N)。重写为**只加当前层前缀**、内层递归各自负责，总复杂度回到 O(N)
8. **short-circuit 优化**：正则 `<[a-zA-Z/!]` 快速判断是否含疑似 HTML 标签起始，
   纯 markdown（如 `1 < 2`）直接原样返回，不走 parser

## 后果

**优点：**

- 首页 / issue 详情 / PR timeline review body / notification / README 等**所有
  Markdown 入口自动受益**——一次改动，一次收益
- 单元测试 **46 条**（29 条白名单基础 + 17 条 reviewer 加固的安全与边界断言）
- 影响面极小：新增 1 个文件、修改 1 处引用、新增 1 条 pubspec 依赖
- 未来可继续扩展（例如给 `<details>` 加真正的折叠交互）而不破坏契约
- 真机 fixture PR #938 二次复测截图 `/tmp/gsy_smoke_13_final.png` 证据齐全：
  `# 大标题` / `## 中标题` / `<hr>` / `<ul>` / `<a>` 蓝色链接 / 行内代码 全部渲染正确

**代价：**

- `<details>` 失去折叠 UI，直接展开显示（但保留了粗体 summary + 内容层次）
- `<img width=100 height=50>` 之类的显式尺寸信息会丢失
- `<u>` `<ins>` 用 `*斜体*` 近似，因为 Markdown 无原生下划线语义
- `<sub>` `<sup>` 退化为纯文本（`H<sub>2</sub>O` → `H2O`），失去下标视觉；
  代价换来的是不与 GFM 删除线冲突
- 若 body 极长且频繁刷新（如实时聊天），HTML 解析器有一次性 O(n) 开销 —— GitHub
  评论场景 body 长度可控，实测无感

## 教训

1. **"markdown 引擎不吃 HTML" 不是 bug 而是设计边界**：应当在数据契约层（喂进
   引擎之前）做规范化，不应该寄望于给引擎「打补丁」（例如塞 InlineSyntax），
   打补丁越多耦合越深，行为越难预测
2. **不要相信「不需要支持 HTML」**：GitHub 官方 issue 模板、Copilot 生成的 body、
   人工手打的评论都大量使用 HTML 白名单标签，「Markdown-only」是脱离真实数据的
   一厢情愿
3. **依赖选型看官方 vs 三方**：`package:html` 是 Dart 官方（`dart-lang/html`），
   优先选它比自己写正则、找社区小包稳得多。**规则 2「参考开源项目」的正解**
4. **决策 vs 实施分开**：P1 的方案设计 3 小时不够，但落地后 46 条单测保证一次
   通过。ADR 明确边界后，后续维护者能一眼看懂"为什么不换包"
5. **"翻译"和"转义"是两回事**：能把 HTML 翻译成正确的 Markdown 标签只完成 60%，
   剩下 40% 是"翻译出来的 Markdown 本身不能被恶意载荷再吃一次"。URL spoofing、
   反引号提前闭合、表格 pipe 逃逸都是这一类。**任何输出 markdown 的地方都必须
   同时考虑 markdown 语法层面的转义**，这是本次 reviewer 复审教给我的核心
6. **独立 reviewer subagent 是硬性收益**：author 视角自证已经过滤掉的 8 个问题，
   在独立上下文的 reviewer 眼里 20 分钟就能被系统性打出来。AGENTS.md 里
   「reviewer 不复用 author 上下文」的强制约束不是形式主义，是防止盲区扩散的实招

## 相关文件

- 实现：[markdown_html_transformer.dart](../../lib/widget/markdown/markdown_html_transformer.dart)
- 接入点：[gsy_markdown_widget.dart#L249-L250](../../lib/widget/markdown/gsy_markdown_widget.dart#L249-L250)
- 单测：[markdown_html_transformer_test.dart](../../test/widget/markdown_html_transformer_test.dart)
- 依赖：[pubspec.yaml#L80](../../pubspec.yaml#L80)（`html: 0.15.5`）
