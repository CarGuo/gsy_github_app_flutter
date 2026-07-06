# GSY GitHub App Flutter 协作说明

这是一个 Flutter GitHub 客户端，同时也是带有教学展示性质的示例工程。
不要假设整个仓库是单一架构风格。多种状态管理方案并存是当前设计现实，不是偶然脏代码。

## 进入仓库后先读

在进行非微小改动前，先读这些文件：

1. `README.md`
2. `docs/README.md`
3. `docs/00-overview/project-map.md`
4. `docs/00-overview/roadmap.md`
5. `docs/01-architecture/app-layering.md`
6. `docs/01-architecture/state-management-matrix.md`

## 工作规则

- 改动尽量限制在当前功能域，不要顺手做跨模块重构。
- 非任务明确要求时，不要迁移状态管理框架。
- 优先遵循目标模块现有模式，而不是引入新的全局规范。
- 未经明确允许，不得为了满足需求擅自替换模块既有框架或状态实现，即使替换后看起来更简单。
- `*.g.dart`、多语言生成文件、env 生成文件都视为生成产物；优先重新生成，不要手改。
- 不要提交密钥。`lib/common/config/ignoreConfig.dart` 属于本地或 CI 环境材料。

## 高风险目录

- `lib/app.dart`：应用根装配、导航、全局报错、Redux 和 Riverpod 混合接线
- `lib/common/net/`：共享网络栈、拦截器、GraphQL/REST 入口
- `lib/common/repositories/`：功能数据访问边界
- `lib/env/`：构建期环境配置和生成文件
- `lib/common/localization/`：ARB 与多语言生成输出

## 建议修改策略

- 纯 UI 任务：优先只改页面或局部 widget，不碰全局状态
- API 任务：同时检查 `common/net` 与对应 `common/repositories`
- 状态任务：沿用该模块当前已有状态方案，除非任务明确要求迁移
- 配置/构建任务：同步更新 `docs/03-runbooks/` 中的操作说明

## Review 规则

- 中等以上改动默认使用独立 reviewer 上下文
- 每次非微小代码改动后，默认拉起新的 reviewer subagent 或新的干净上下文审查刚刚的修改
- author 在通过一轮新的 reviewer subagent 审查前，不应直接宣告代码任务完成
- reviewer 不应复用 author 的完整上下文历史
- 先看 `docs/05-ai/review-harness.md`
- reviewer 提示模板见 `docs/05-ai/prompts/reviewer-system.md`
- `tool/ai/build_review_bundle.ps1` 只是可选辅助，不是主流程

## 本地最小验证

按改动范围选择最小验证集合：

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter gen-l10n`
- `flutter analyze`
- `flutter build apk --release --target-platform=android-arm64 --no-shrink`

说明：

- 改模型、env、注解生成代码时跑 `build_runner`
- 改 ARB 或本地化输入时跑 `flutter gen-l10n`
- 改 Android 构建、依赖或运行时关键路径时跑 APK 构建

## 运行时冒烟验证（强制）

**"能编译过 + 装机不崩" 不算测试通过。**
任何涉及运行时行为（UI 渲染、事件解析、状态流转、网络分支、多语言文案）的改动，
在宣告完成前，author 必须在真机或模拟器上跑通对应改动路径，
并把真实证据（截图 / 文案 dump / 错误日志）**以文件形式产出并写清路径**，
禁止只凭"app 启动了、日志没红"就报完成。

强制的是**证据本身**，不是具体工具。工具链按可用性挑：

### 工具选型（按可用性挑一条主路径 + 一条 fallback）

1. **主路径 — `mcp_dart`（debug 构建、DTD 在线时首选）**
   - `dtd` → `listDtdUris` / `connect` 建立 DTD 连接
   - `widget_inspector` → `get_widget_tree` / `get_selected_widget` 抓真实渲染出的 widget 树
   - `get_runtime_errors` 拉 Dart 层异常（改动前后各拉一次）
   - `flutter_driver_command` 只在工程已引入 `flutter_driver` / `integration_test`
     并且 `main.dart` 里显式调用 `enableFlutterDriverExtension()` 时才可用。
     本仓库目前**未引入这套依赖**，因此该子工具默认不可用，不得作为唯一验证手段。

2. **Fallback — `adb`（release 构建、DTD 掉线、driver 未启用时的一等公民）**
   - `adb devices` 确认设备可见
   - `adb shell input tap/swipe/text/keyevent` 驱动 UI
   - `adb exec-out screencap -p > /tmp/xxx.png` 抓真实渲染截图
   - `adb logcat -d -s flutter` 抓 Dart 侧输出
   - **截图文件路径必须写进完成汇报**，reviewer 需要能拿到该路径复核。
   - 反复用到的 tap 序列必须沉淀到 [`tool/ai/smoke/`](tool/ai/smoke/)，
     不允许把已经跑通的坐标序列扔在一次对话里就丢掉。

3. **Web / DevTools 类改动**：用 `integrated_browser` 走同样"操作 → 截图 → 抓日志"流程。

### 强制流程

1. `flutter run` 或已装机的 build 起到已连接设备。
2. 按上表挑工具组合抓证据；`mcp_dart` 不可用时直接切 `adb`，不视为破例。
3. 走一遍改动**直接覆盖**的路径（例：改了 PR timeline 事件行 → 真的进 PR 详情页把
   timeline 滚一遍，抓到目标文案的截图或 `get_text` 输出）。
4. 覆盖不到的分支（例：`base_ref_force_pushed` 真机上罕见）必须在完成汇报里
   **显式列为已知缺口**，不能糊成"通过"。稀有分支覆盖率无法靠真机保证时，
   优先考虑加模型层单测 + 真实 JSON fixture 补齐。

### 分级要求（避免形式主义）

| 改动类型 | 最低证据要求 |
|---|---|
| 纯模型 / 纯工具函数 | `flutter analyze` + 单测（若 test 目录已存在）；无需截图 |
| UI 渲染 / 文案 / 事件行 | 至少 1 张真机截图 + `get_runtime_errors` 或 `logcat` 空异常 |
| 关键路径（登录 / 网络栈 / 根装配 / 状态边界） | 主路径截图 + 至少 1 个失败/边界分支的证据 |

### 完成汇报三段式（必填）

**看代码**：改了哪些文件、哪些函数、为什么这么改。
**看编译**：`flutter analyze` / `build_runner` / `gen-l10n` 的产物结论。
**看运行**：设备 id、所用工具组合（mcp_dart 或 adb）、**截图文件绝对路径**、
`get_runtime_errors` 或 `logcat` 结果、无法覆盖的分支列表。

三段任一缺失 = 任务未完成。

### 禁止行为

- ❌ 只跑 `flutter analyze` 就报"测试通过"
- ❌ 把"app 启动到首页"当成本次功能验证
- ❌ 让用户手动操作 UI 代替 author 自测（除非物理上无法自动化，且已说明原因）
- ❌ 拿"日志里没 Exception"当作行为正确的证据
- ❌ 只把截图放在自己上下文里而不写路径，导致 reviewer 拿不到证据

## 当前已知约束

- 仓库既有 `test/`（纯 Dart 单测 + widget test）也有 `patrol_test/`（Patrol 集成测试脚手架，pubspec 中已引入 `patrol`）；两条测试路径并存，按改动性质挑合适档次
- CI 使用 GitHub Actions，当前偏重构建成功
- 项目同时使用 Redux、Riverpod、Provider、Signals
- OAuth 登录相关流程依赖本地 `ignoreConfig.dart`
- **GSY 是 GitHub 的只读 + 评论客户端**，不承担写 PR / 提交 review / 建仓库这类"作者行为"。冒烟或回归时**禁止通过 gh cli 或 GitHub API 新建仓库、造 PR 或提交 review**去伪造证据，一律用既有仓库里的真实数据

### 允许 / 禁止的写操作清单

> 状态：作者已于 2026-07-06 拍板转正，正式约束。修改需在 PR 描述里显式提出并同步 `docs/00-overview/roadmap.md §4.1`。

**允许（已在做且不打算收回）**：

- Issue / Comment 上加/取消 reaction
- Issue / PR / Discussion 下发评论
- Notify 标记已读 / 标记 done / unsubscribe
- 关注 / 取消关注仓库（star / watch 切换）
- **PR review thread mark as resolved / unresolved（2026-07-06 新加）**：仅操作层，不做"未 resolved thread 计数"这类仪表盘
- **编辑自己发的 issue body / comment 内容（2026-07-06 新加）**：服务端会按作者身份校验，不会误伤他人；范围**限编辑**，不含删除

**明确禁止（越界的作者行为）**：

- 新建仓库 / fork 仓库
- 新建 issue / PR / discussion
- 提交 / dismiss review
- 合并 PR / close issue / lock conversation
- 修改仓库设置 / 分支保护 / webhook / secret
- 通过 gh cli 或 GitHub API 制造冒烟数据
- **GitHub Actions workflow rerun / cancel（2026-07-06 拍板归入禁止）**：属于仓库运维行为，GSY 不介入；用户如需 rerun 请去 GitHub 官网或官方 app
- **Projects V2 卡片移动 / 状态字段编辑（2026-07-06 拍板归入禁止）**：等同协作作者视角编辑，与只读 + 评论定位冲突；连 Projects V2 阅读也一并搁置
- **删除自己发的 issue / comment**：即使 API 支持，也不做——避免"误删无法恢复"的用户投诉面

**判断口径**：

- 判断依据是"是否让 GSY 用户在 GitHub 上产生新数据 / 修改他人内容 / 触发仓库运维"，不是"API 是不是 write endpoint"
- 若未来需要新增一条允许项，需要在 PR 描述里显式提出，并同步更新本清单与 roadmap §4.1


## 真机验证专用 fixture（写死，不允许随手换）

以下 PR/仓库是真机冒烟脚本 `tool/ai/smoke/open_pr_timeline.sh` 默认命中的证据源。改动 timeline 相关代码时，优先复用它们；只有在明确覆盖不到时才另外找 PR。

- **fixture 账号**：`CarSmallGuo`（当前 adb 设备与 gh cli 登录的账号，token 有 `repo` 权限但**只做读**）
- **fixture 仓库**：`CarGuo/gsy_github_app_flutter`（GSY 主仓库自身）
- **fixture PR**：
  - `#938`：Copilot 提交的 `reviewed / state=commented`，body 788 字符，同时覆盖 `ready_for_review` / `review_requested` / `assigned` / `merged` / `closed` / 未知事件兜底等新事件类型
    - 打开方式：`bash tool/ai/smoke/open_pr_timeline.sh`（默认参数即可）
    - 期望截图证据：`/tmp/gsy_smoke_07_issue_detail_scrolled.png` 与随后一屏能同时看到"Copilot 提交了评审意见"这一行**和其下方灰底 body 卡片**
  - 后续若需要 approved/changes_requested body 场景，请在 `CarGuo` 名下的其它 PR 里挑选并把 PR 号写回本段落，不要造 PR


